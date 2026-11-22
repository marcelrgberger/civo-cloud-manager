import Foundation

/// How a confirmed replacement ended. The sheet stays open, and `sheetError` explains why, when `confirm` returns nil.
enum KubernetesNodeRecycleOutcome: Equatable {
    /// Civo accepted the request. The node is replaced afterwards; the replacement is not finished yet.
    case requested
    /// The request was sent but no refusal came back, or Civo's answer could not be read.
    case uncertain
    /// The replacement was closed without sending it; the notice explains why.
    case cancelled
}

/// Replaces one worker node at a time, only after the user confirmed cluster, region and hostname. Before the
/// request the cluster is loaded again: a node that is gone, listed twice or moved, or a busy cluster sends nothing.
/// Nothing is drained first, and nothing is sent again on its own.
@Observable
@MainActor
final class KubernetesNodeRecycleController {
    struct Request: Equatable {
        /// Tells this replacement apart from a later one of the same node.
        let id = UUID()
        let target: KubernetesNodeRecycleTarget
    }

    /// A node as listed in one cluster, loaded from one region with one account.
    private struct NodeKey: Equatable {
        let clusterId: String
        let region: String
        let account: CivoAccount?
        let hostname: String
    }

    /// Shown only on the detail page of the cluster it was raised for.
    private struct Notice {
        let node: NodeKey
        let message: String
        /// Set while the notice reports an accepted replacement as not finished; it goes once the node is no longer listed.
        var isPending = false
    }

    private(set) var request: Request?
    private(set) var isSending = false
    /// The request on its way to Civo. It can no longer be called back.
    private var sendingRequestId: UUID?
    /// Shown in the sheet: the cluster could not be loaded again, or Civo refused the replacement.
    private(set) var sheetError: String?
    private var notice: Notice?
    /// Nodes Civo accepted a replacement for, kept until the cluster no longer lists them.
    private var requestedReplacements: [NodeKey] = []

    private let api: any KubernetesNodeRecycleAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (KubernetesNodeRecycleTarget) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any KubernetesNodeRecycleAPI = CivoKubernetesService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (KubernetesNodeRecycleTarget) -> Void = { target in
            ActivityLog.shared.log(
                "Requested replacement of node %@", detail: target.hostname,
                resourceType: "Kubernetes", resourceName: target.clusterName, resourceId: target.clusterId
            )
        }
    ) {
        self.api = api
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.apiKey = apiKey
        self.notificationCenter = notificationCenter
        self.recordActivity = recordActivity
        observers = [Notification.Name.civoAPIKeyDidChange, .civoRegionDidChange].map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.dropInvalidRequest() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    // MARK: - Offer

    /// Whether `hostname` names exactly one node of `cluster`, so "Replace node..." may be offered for it.
    static func canOffer(_ hostname: String, in cluster: CivoKubernetesCluster) -> Bool {
        if case .success = KubernetesNodeIdentity.pool(listing: hostname, in: cluster) { return true }
        return false
    }

    /// Whether Civo accepted a replacement of `hostname` in the cluster, loaded from `region` with `account`,
    /// that the cluster has not finished yet.
    func isReplacementRequested(_ hostname: String, inCluster clusterId: String, region: String, account: CivoAccount?) -> Bool {
        requestedReplacements.contains(NodeKey(clusterId: clusterId, region: region, account: account, hostname: hostname))
    }

    /// Why the last replacement in the cluster, loaded from `region` with `account`, was closed, or what became of it.
    func notice(forCluster clusterId: String, region: String, account: CivoAccount?) -> String? {
        guard let notice, notice.node.clusterId == clusterId, notice.node.region == region, notice.node.account == account else { return nil }
        return notice.message
    }

    /// Forgets accepted replacements, and the notice that one is not finished, once `cluster`, loaded from
    /// `region` with `account`, no longer lists the node.
    func clusterDidLoad(_ cluster: CivoKubernetesCluster, region: String, account: CivoAccount) {
        func isReplaced(_ node: NodeKey) -> Bool {
            guard node.clusterId == cluster.id, node.region == region, node.account == account else { return false }
            if case .failure(.nodeRemoved) = KubernetesNodeIdentity.pool(listing: node.hostname, in: cluster) { return true }
            return false
        }
        requestedReplacements.removeAll(where: isReplaced)
        if let notice, notice.isPending, isReplaced(notice.node) {
            self.notice = nil
        }
    }

    // MARK: - Request

    /// Opens the confirmation for `hostname` in `cluster`, loaded from `region` with `account`, with the target captured now.
    func begin(replacing hostname: String, in cluster: CivoKubernetesCluster, region: String, account: CivoAccount?) {
        guard sendingRequestId == nil else { return }
        notice = nil
        sheetError = nil
        let node = NodeKey(clusterId: cluster.id, region: region, account: account, hostname: hostname)
        guard let account else {
            notice = Notice(node: node, message: KubernetesNodeRecycleError.accountChanged.message)
            return
        }
        let pool: CivoNodePool
        switch KubernetesNodeIdentity.pool(listing: hostname, in: cluster) {
        case .success(let listing): pool = listing
        case .failure(let problem):
            notice = Notice(node: node, message: problem.message)
            return
        }
        let target = KubernetesNodeRecycleTarget(
            clusterId: cluster.id, clusterName: cluster.name, region: region, account: account, hostname: hostname, poolId: pool.id
        )
        if let problem = targetError(for: target)
            ?? (requestedReplacements.contains(node) ? .replacementAlreadyRequested(hostname) : nil)
            ?? KubernetesNodeIdentity.busyStatus(of: cluster) {
            close(problem, for: target)
            return
        }
        request = Request(target: target)
    }

    func cancel() {
        if let request, request.id == sendingRequestId {
            notice = Notice(node: Self.key(of: request.target), message: Self.awaitingAnswerMessage(for: request.target))
        }
        request = nil
        sheetError = nil
    }

    /// Why `target` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for target: KubernetesNodeRecycleTarget) -> KubernetesNodeRecycleError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard target.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard target.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    /// Sends the replacement once the cluster, loaded again, is active and still lists the node exactly once,
    /// in the pool the user saw.
    func confirm() async -> KubernetesNodeRecycleOutcome? {
        guard let request, !isSending else { return nil }
        let target = request.target
        sheetError = nil
        if let problem = targetError(for: target) { return close(problem, for: target) }
        // One key for every request, so both reach the same account.
        let key = apiKey()
        guard !key.isEmpty else {
            sheetError = CivoAPIError.userMessage(CivoAPIError.noAPIKey)
            return nil
        }

        isSending = true
        defer { isSending = false }

        do {
            let cluster = try await api.showCluster(target.clusterId, region: target.region, apiKey: key)
            // Cancelled, or closed by a region or key change, while loading.
            guard self.request?.id == request.id else { return nil }
            if let problem = targetError(for: target) ?? Self.staleTargetError(target, cluster: cluster) {
                return close(problem, for: target)
            }
        } catch let CivoAPIError.httpError(status, _) where status == 404 {
            guard self.request?.id == request.id else { return nil }
            return close(.clusterRemoved, for: target)
        } catch {
            guard self.request?.id == request.id else { return nil }
            if let problem = targetError(for: target) { return close(problem, for: target) }
            sheetError = CivoAPIError.userMessage(error)
            return nil
        }

        // From here on the sheet may be closed before Civo answers; the answer is then reported as a notice.
        sendingRequestId = request.id
        defer { sendingRequestId = nil }
        do {
            try await api.recycleNode(target.hostname, inCluster: target.clusterId, region: target.region, apiKey: key)
        } catch CivoAPIError.decodingError {
            remember(target)
            return finish(request, notice: Self.unreadableAnswerMessage(for: target), isPending: true, outcome: .uncertain)
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            // Civo refused the request, for example a 403 or a node it no longer knows.
            let reason = refusal.localizedDescription
            guard self.request?.id == request.id else {
                notice = Notice(node: Self.key(of: target), message: Self.notSentMessage(for: target, reason: reason))
                return .cancelled
            }
            sheetError = reason
            return nil
        } catch {
            // A timeout or a server error may follow a replacement Civo already started, or none at all.
            // Nothing is remembered and nothing is sent again; the reloaded cluster shows what happened.
            return finish(request, notice: Self.unknownResultMessage(for: target), outcome: .uncertain)
        }
        remember(target)
        recordActivity(target)
        return finish(request, notice: Self.acceptedMessage(for: target), isPending: true, outcome: .requested)
    }

    static func acceptedMessage(for target: KubernetesNodeRecycleTarget) -> String {
        String(localized: "Civo accepted the request to replace node \"\(target.hostname)\" in \"\(target.clusterName)\". The replacement runs on Civo's side and is not finished yet; the status shown here updates when you refresh.")
    }

    static func unreadableAnswerMessage(for target: KubernetesNodeRecycleTarget) -> String {
        String(localized: "Civo accepted the replacement of node \"\(target.hostname)\", but its answer could not be read. Refresh to see the status of the cluster.")
    }

    static func unknownResultMessage(for target: KubernetesNodeRecycleTarget) -> String {
        String(localized: "The result of the replacement request for node \"\(target.hostname)\" is unknown. Refresh to see the status of the cluster before trying again.")
    }

    static func awaitingAnswerMessage(for target: KubernetesNodeRecycleTarget) -> String {
        String(localized: "The replacement request for node \"\(target.hostname)\" was already sent and can no longer be cancelled. Its result is shown here once Civo answers.")
    }

    static func notSentMessage(for target: KubernetesNodeRecycleTarget, reason: String) -> String {
        String(localized: "Civo did not replace node \"\(target.hostname)\": \(reason)")
    }

    /// Why the reloaded `cluster` no longer matches what the user confirmed, nil while it does.
    private static func staleTargetError(_ target: KubernetesNodeRecycleTarget, cluster: CivoKubernetesCluster) -> KubernetesNodeRecycleError? {
        switch KubernetesNodeIdentity.pool(listing: target.hostname, in: cluster) {
        case .failure(let problem): problem
        case .success(let pool) where pool.id != target.poolId: .nodeMoved(target.hostname)
        case .success: KubernetesNodeIdentity.busyStatus(of: cluster)
        }
    }

    /// Only a refusal of the request proves that Civo left the node as it was. A 408 is a timeout, not a refusal.
    private static func provesNothingChanged(_ error: CivoAPIError) -> Bool {
        guard case .httpError(let status, _) = error, status != requestTimeoutStatus else { return false }
        return (400..<500).contains(status)
    }

    private static let requestTimeoutStatus = 408

    private static func key(of target: KubernetesNodeRecycleTarget) -> NodeKey {
        NodeKey(clusterId: target.clusterId, region: target.region, account: target.account, hostname: target.hostname)
    }

    private func remember(_ target: KubernetesNodeRecycleTarget) {
        let node = Self.key(of: target)
        if !requestedReplacements.contains(node) { requestedReplacements.append(node) }
    }

    private func finish(_ sent: Request, notice: String, isPending: Bool = false, outcome: KubernetesNodeRecycleOutcome) -> KubernetesNodeRecycleOutcome {
        if request?.id == sent.id { request = nil }
        self.notice = Notice(node: Self.key(of: sent.target), message: notice, isPending: isPending)
        return outcome
    }

    @discardableResult
    private func close(_ problem: KubernetesNodeRecycleError, for target: KubernetesNodeRecycleTarget) -> KubernetesNodeRecycleOutcome {
        request = nil
        sheetError = nil
        notice = Notice(node: Self.key(of: target), message: problem.message, isPending: problem == .replacementAlreadyRequested(target.hostname))
        return .cancelled
    }

    private func dropInvalidRequest() {
        guard let request, let problem = targetError(for: request.target) else { return }
        if request.id == sendingRequestId {
            cancel()
        } else {
            close(problem, for: request.target)
        }
    }
}
