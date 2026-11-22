import Foundation

/// The cluster a node pool change was started for, with the account and region its detail was loaded from.
struct KubernetesNodePoolTarget: Equatable, Sendable {
    let clusterId: String
    let clusterName: String
    let region: String
    /// The account the cluster was loaded with, so a change never reaches another account.
    let account: CivoAccount

    fileprivate var key: ClusterKey { ClusterKey(clusterId: clusterId, region: region, account: account) }
}

/// A cluster as loaded from one region with one account.
private struct ClusterKey: Equatable {
    let clusterId: String
    let region: String
    let account: CivoAccount?
}

/// How a confirmed change ended. The sheet stays open, and `sheetError` explains why, when `save` returns nil.
enum KubernetesNodePoolOutcome: Equatable {
    /// Civo accepted the request. Nodes are added and removed afterwards; that is not finished yet.
    case requested
    /// The request was sent but no refusal came back, or Civo's answer could not be read.
    case uncertain
    /// The change was closed without sending it; the notice explains why.
    case cancelled
}

/// Scales, adds and removes the node pools of one cluster at a time with one `PUT` of the complete desired
/// state. Before the request the cluster is loaded again, and only the changes the user made are applied to it:
/// a changed pool, a busy cluster or a size Civo no longer offers sends nothing. Nothing is sent again on its own.
@Observable
@MainActor
final class KubernetesNodePoolController {
    struct Session {
        /// Tells this change apart from a later one of the same cluster.
        let id = UUID()
        let target: KubernetesNodePoolTarget
        var draft: KubernetesNodePoolDraft
        /// The sizes Civo offers in the target region; nil until loaded.
        var sizes: [CivoSize]?
        var sizesError: String?
        /// nil until loaded, or when it could not be loaded.
        var quota: CivoQuota?
        var quotaError: String?
    }

    /// Shown only on the detail page of the cluster it was raised for.
    private struct Notice {
        let cluster: ClusterKey
        let message: String
    }

    /// Accepted changes, kept until the cluster reports them.
    private struct PendingChange {
        let cluster: ClusterKey
        let changes: [KubernetesNodePoolChange]
    }

    private(set) var session: Session?
    private(set) var isSending = false
    /// The request on its way to Civo. It can no longer be called back.
    private var sendingSessionId: UUID?
    /// Shown in the sheet: the cluster could not be loaded again, or Civo refused the change.
    private(set) var sheetError: String?
    private var notice: Notice?
    private var pendingChanges: [PendingChange] = []

    private let api: any KubernetesNodePoolAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let hourlyRates: @MainActor () -> [String: Double]
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (KubernetesNodePoolTarget, [KubernetesNodePoolChange]) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any KubernetesNodePoolAPI = CivoKubernetesService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        hourlyRates: @escaping @MainActor () -> [String: Double] = { CivoCharge.hourlyRates },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (KubernetesNodePoolTarget, [KubernetesNodePoolChange]) -> Void = { target, changes in
            ActivityLog.shared.log(
                "Requested node pool changes: %@", detail: changes.map(\.summary).joined(separator: "; "),
                resourceType: "Kubernetes", resourceName: target.clusterName, resourceId: target.clusterId
            )
        }
    ) {
        self.api = api
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.apiKey = apiKey
        self.hourlyRates = hourlyRates
        self.notificationCenter = notificationCenter
        self.recordActivity = recordActivity
        observers = [Notification.Name.civoAPIKeyDidChange, .civoRegionDidChange].map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.dropInvalidSession() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    // MARK: - Status

    /// Why the last change of the cluster, loaded from `region` with `account`, was closed, or what became of it.
    func notice(forCluster clusterId: String, region: String, account: CivoAccount?) -> String? {
        guard let notice, notice.cluster == ClusterKey(clusterId: clusterId, region: region, account: account) else { return nil }
        return notice.message
    }

    /// Whether Civo accepted a change of the cluster, loaded from `region` with `account`, that it does not report yet.
    func isChangePending(forCluster clusterId: String, region: String, account: CivoAccount?) -> Bool {
        let key = ClusterKey(clusterId: clusterId, region: region, account: account)
        return pendingChanges.contains { $0.cluster == key }
    }

    /// Forgets an accepted change, and its notice, once `cluster`, loaded from `region` with `account`, reports it.
    func clusterDidLoad(_ cluster: CivoKubernetesCluster, region: String, account: CivoAccount) {
        let key = ClusterKey(clusterId: cluster.id, region: region, account: account)
        guard let pending = pendingChanges.first(where: { $0.cluster == key }),
              KubernetesNodePoolPlan.reports(pending.changes, in: cluster) else { return }
        pendingChanges.removeAll { $0.cluster == key }
        if notice?.cluster == key { notice = nil }
    }

    // MARK: - Editing

    /// Opens the editor for `cluster`, loaded from `region` with `account`, with the pools as shown now, then
    /// loads the sizes and the quota with the same account.
    func begin(editing cluster: CivoKubernetesCluster, region: String, account: CivoAccount?) async {
        guard sendingSessionId == nil else { return }
        notice = nil
        sheetError = nil
        let key = ClusterKey(clusterId: cluster.id, region: region, account: account)
        guard let account else {
            notice = Notice(cluster: key, message: KubernetesNodePoolError.accountChanged.message)
            return
        }
        let target = KubernetesNodePoolTarget(clusterId: cluster.id, clusterName: cluster.name, region: region, account: account)
        let shownPools: [CivoNodePoolSpec]
        switch KubernetesNodePoolPlan.currentPools(of: cluster) {
        case .success(let pools): shownPools = pools
        case .failure(let problem):
            close(problem, for: target)
            return
        }
        if let problem = targetError(for: target)
            ?? (isChangePending(forCluster: cluster.id, region: region, account: account) ? .changeAlreadyPending : nil)
            ?? KubernetesNodePoolPlan.busyStatus(of: cluster) {
            close(problem, for: target)
            return
        }
        let opened = Session(target: target, draft: KubernetesNodePoolDraft(shownPools: shownPools))
        session = opened
        await loadOptions(for: opened)
    }

    /// Applies an edit to the open draft. Ignored while saving, since the changes being sent are already fixed.
    func edit(_ change: (inout KubernetesNodePoolDraft) -> Void) {
        guard var draft = session?.draft, !isSending else { return }
        change(&draft)
        session?.draft = draft
    }

    var changes: [KubernetesNodePoolChange] { session?.draft.changes ?? [] }

    /// Whether saving deletes nodes, which the user confirms separately.
    var removesNodes: Bool { changes.contains(where: \.removesNodes) }

    var costEstimate: KubernetesNodePoolCostEstimate {
        KubernetesNodePoolCostEstimate(changes: changes, rates: hourlyRates())
    }

    /// What the added nodes need beyond the quota; empty without a loaded quota.
    var quotaShortfalls: [KubernetesNodePoolQuotaShortfall] {
        guard let session, let quota = session.quota else { return [] }
        return KubernetesNodePoolQuotaShortfall.shortfalls(for: changes, sizes: session.sizes ?? [], quota: quota)
    }

    func cancel() {
        if let session, session.id == sendingSessionId {
            notice = Notice(cluster: session.target.key, message: Self.awaitingAnswerMessage)
        }
        session = nil
        sheetError = nil
    }

    /// Why `target` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for target: KubernetesNodePoolTarget) -> KubernetesNodePoolError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard target.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard target.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    // MARK: - Saving

    /// Sends the changes once the cluster, loaded again, is active and still has every changed pool as shown.
    /// Changes that delete nodes are sent only with `confirmingRemoval`.
    func save(confirmingRemoval: Bool) async -> KubernetesNodePoolOutcome? {
        guard let session, !isSending else { return nil }
        let target = session.target
        let changes = session.draft.changes
        guard !changes.isEmpty, confirmingRemoval || !changes.contains(where: \.removesNodes) else { return nil }
        sheetError = nil
        if let problem = targetError(for: target) { return close(problem, for: target) }
        // One key for every request, so all reach the same account.
        let key = apiKey()
        guard !key.isEmpty else {
            sheetError = CivoAPIError.userMessage(CivoAPIError.noAPIKey)
            return nil
        }

        isSending = true
        defer { isSending = false }

        let pools: [CivoNodePoolSpec]
        do {
            let addedSizes = Set(changes.compactMap { change in
                if case .add(_, let size, _) = change { size } else { nil }
            })
            let offeredSizes = addedSizes.isEmpty ? [] : Set(try await api.listSizes(region: target.region, apiKey: key).map(\.name))
            // Loaded last, so the desired state is built from the newest pools.
            let cluster = try await api.showCluster(target.clusterId, region: target.region, apiKey: key)
            // Cancelled, or closed by a region or key change, while loading.
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) ?? KubernetesNodePoolPlan.busyStatus(of: cluster) {
                return close(problem, for: target)
            }
            if let missing = addedSizes.sorted().first(where: { !offeredSizes.contains($0) }) {
                return close(.sizeUnavailable(missing), for: target)
            }
            switch KubernetesNodePoolPlan.desiredPools(applying: changes, shownPools: session.draft.shownPools, to: cluster) {
            case .success(let desired): pools = desired
            case .failure(let problem): return close(problem, for: target)
            }
        } catch let CivoAPIError.httpError(status, _) where status == 404 {
            guard self.session?.id == session.id else { return nil }
            return close(.clusterRemoved, for: target)
        } catch {
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem, for: target) }
            sheetError = CivoAPIError.userMessage(error)
            return nil
        }

        // From here on the sheet may be closed before Civo answers; the answer is then reported as a notice.
        sendingSessionId = session.id
        defer { sendingSessionId = nil }
        do {
            try await api.updatePools(pools, inCluster: target.clusterId, region: target.region, apiKey: key)
        } catch CivoAPIError.decodingError {
            remember(changes, for: target)
            return finish(session, notice: Self.unreadableAnswerMessage, outcome: .uncertain)
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            // Civo refused the request, for example a 403, an exceeded quota or a size it does not offer.
            let reason = refusal.localizedDescription
            guard self.session?.id == session.id else {
                notice = Notice(cluster: target.key, message: Self.notSentMessage(reason: reason))
                return .cancelled
            }
            sheetError = reason
            return nil
        } catch {
            // A timeout or a server error may follow a change Civo already started, or none at all.
            // Nothing is remembered and nothing is sent again; the reloaded cluster shows what happened.
            return finish(session, notice: Self.unknownResultMessage, outcome: .uncertain)
        }
        remember(changes, for: target)
        recordActivity(target, changes)
        return finish(session, notice: Self.acceptedMessage, outcome: .requested)
    }

    /// Saves the labels of pool `poolId` of the cluster in `target` as the complete desired state of its pools,
    /// built from the cluster loaded again just now. Returns nil once Civo accepted the labels, otherwise why
    /// nothing, or nothing certain, was saved.
    func saveLabels(_ labels: [String: String], shownLabels: [String: String], ofPool poolId: String, in target: KubernetesNodePoolTarget) async -> String? {
        guard !isSending else { return KubernetesNodePoolError.changeAlreadyPending.message }
        if let problem = targetError(for: target)
            ?? (isChangePending(forCluster: target.clusterId, region: target.region, account: target.account) ? .changeAlreadyPending : nil) {
            return problem.message
        }
        // One key for both requests, so the labels reach the account the cluster was loaded with.
        let key = apiKey()
        guard !key.isEmpty else { return CivoAPIError.userMessage(CivoAPIError.noAPIKey) }

        isSending = true
        defer { isSending = false }

        let pools: [CivoNodePoolSpec]
        do {
            let cluster = try await api.showCluster(target.clusterId, region: target.region, apiKey: key)
            if let problem = targetError(for: target) ?? KubernetesNodePoolPlan.busyStatus(of: cluster) { return problem.message }
            switch KubernetesNodePoolPlan.relabeling(pool: poolId, from: shownLabels, to: labels, in: cluster) {
            case .success(let desired): pools = desired
            case .failure(let problem): return problem.message
            }
        } catch let CivoAPIError.httpError(status, _) where status == 404 {
            return KubernetesNodePoolError.clusterRemoved.message
        } catch {
            return targetError(for: target)?.message ?? CivoAPIError.userMessage(error)
        }
        do {
            try await api.updatePools(pools, inCluster: target.clusterId, region: target.region, apiKey: key)
            return nil
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            return Self.notSentMessage(reason: refusal.localizedDescription)
        } catch {
            // Not sent again; the reloaded cluster shows whether the labels were saved.
            return Self.unknownResultMessage
        }
    }

    static let acceptedMessage = String(localized: "Civo accepted the node pool changes. Nodes are added and removed on Civo's side, which is not finished yet; the pools shown here update when you refresh.")

    static let unreadableAnswerMessage = String(localized: "Civo accepted the node pool changes, but its answer could not be read. Refresh to see the node pools of the cluster.")

    static let unknownResultMessage = String(localized: "The result of the node pool changes is unknown. Refresh to see the node pools of the cluster before trying again.")

    static let awaitingAnswerMessage = String(localized: "The node pool changes were already sent and can no longer be cancelled. Their result is shown here once Civo answers.")

    static func notSentMessage(reason: String) -> String {
        String(localized: "Civo did not change the node pools: \(reason)")
    }

    /// Only a refusal of the request proves that Civo left the pools as they were. A 408 is a timeout, not a refusal.
    private static func provesNothingChanged(_ error: CivoAPIError) -> Bool {
        guard case .httpError(let status, _) = error, status != requestTimeoutStatus else { return false }
        return (400..<500).contains(status)
    }

    private static let requestTimeoutStatus = 408

    private func loadOptions(for opened: Session) async {
        let key = apiKey()
        let target = opened.target
        var sizes: [CivoSize]?
        var sizesError: String?
        var quota: CivoQuota?
        var quotaError: String?
        do {
            sizes = try await api.listSizes(region: target.region, apiKey: key)
        } catch {
            sizesError = CivoAPIError.userMessage(error)
        }
        do {
            quota = try await api.quota(apiKey: key)
        } catch {
            quotaError = CivoAPIError.userMessage(error)
        }
        guard session?.id == opened.id else { return }
        session?.sizes = sizes
        session?.sizesError = sizesError
        session?.quota = quota
        session?.quotaError = quotaError
    }

    private func remember(_ changes: [KubernetesNodePoolChange], for target: KubernetesNodePoolTarget) {
        pendingChanges.removeAll { $0.cluster == target.key }
        pendingChanges.append(PendingChange(cluster: target.key, changes: changes))
    }

    private func finish(_ sent: Session, notice: String, outcome: KubernetesNodePoolOutcome) -> KubernetesNodePoolOutcome {
        if session?.id == sent.id { session = nil }
        self.notice = Notice(cluster: sent.target.key, message: notice)
        return outcome
    }

    @discardableResult
    private func close(_ problem: KubernetesNodePoolError, for target: KubernetesNodePoolTarget) -> KubernetesNodePoolOutcome {
        session = nil
        sheetError = nil
        notice = Notice(cluster: target.key, message: problem.message)
        return .cancelled
    }

    private func dropInvalidSession() {
        guard let session, let problem = targetError(for: session.target) else { return }
        if session.id == sendingSessionId {
            cancel()
        } else {
            close(problem, for: session.target)
        }
    }
}
