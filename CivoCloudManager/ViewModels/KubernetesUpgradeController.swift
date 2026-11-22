import Foundation

/// The cluster an upgrade was started for, with the account and region its detail was loaded from.
struct KubernetesUpgradeTarget: Equatable, Sendable {
    let clusterId: String
    let clusterName: String
    let region: String
    /// The account the cluster was loaded with, so an upgrade never reaches another account.
    let account: CivoAccount
    /// The version the cluster reported when the upgrade was started.
    let fromVersion: String

    fileprivate var key: ClusterKey { ClusterKey(clusterId: clusterId, region: region, account: account) }
}

/// A cluster as loaded from one region with one account.
private struct ClusterKey: Equatable {
    let clusterId: String
    let region: String
    let account: CivoAccount?
}

/// How a confirmed upgrade ended. The sheet stays open, and `sheetError` explains why, when `upgrade` returns nil.
enum KubernetesUpgradeOutcome: Equatable {
    /// Civo accepted the request. The upgrade itself runs afterwards and is not finished yet.
    case requested
    /// The request was sent but no refusal came back, or Civo's answer could not be read.
    case uncertain
    /// The upgrade was closed without sending it; `notice` explains why.
    case cancelled
}

/// Upgrades one cluster at a time, only after the user picked a newer version and confirmed it. Before the
/// request the cluster and the version list are loaded again: a cluster that changed meanwhile, an upgrade
/// that is already running or a version Civo no longer offers sends nothing.
@Observable
@MainActor
final class KubernetesUpgradeController {
    struct Session: Equatable {
        /// Tells this upgrade apart from a later one of the same cluster.
        let id = UUID()
        let target: KubernetesUpgradeTarget
        /// The versions offered, newest first; nil until the version list is loaded.
        var targets: [CivoKubernetesVersion]?
        /// Civo's own upgrade hint for the cluster, if any.
        let recommendedVersion: String?
    }

    /// An upgrade Civo answered as accepted, kept until the cluster reports the version.
    private struct RequestedUpgrade: Equatable {
        let cluster: ClusterKey
        let version: String
    }

    /// Shown only on the detail page of the cluster it was raised for.
    private struct Notice {
        let cluster: ClusterKey
        let message: String
        /// The version of an accepted upgrade the notice reports as not finished; the notice goes once it is reached.
        var pendingVersion: String?
    }

    private(set) var session: Session?
    private(set) var isLoadingVersions = false
    private(set) var isSending = false
    /// The session whose upgrade is on its way to Civo. It can no longer be called back.
    private var sendingSessionId: UUID?
    /// Shown in the sheet: the version list could not be loaded, or Civo refused the upgrade.
    private(set) var sheetError: String?
    /// Why the last upgrade was closed, or what became of it.
    private var notice: Notice?
    private var requestedUpgrades: [RequestedUpgrade] = []

    private let api: any KubernetesUpgradeAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (KubernetesUpgradeTarget, String) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any KubernetesUpgradeAPI = CivoKubernetesService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (KubernetesUpgradeTarget, String) -> Void = { target, version in
            ActivityLog.shared.log(
                "Requested Kubernetes upgrade to %@", detail: version,
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
                MainActor.assumeIsolated { self?.dropInvalidSession() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    // MARK: - Session

    /// Opens the upgrade for `cluster`, loaded from `region` with `account`, with the target captured now,
    /// then loads the versions Civo offers.
    func begin(upgrading cluster: CivoKubernetesCluster, region: String, account: CivoAccount?) async {
        guard sendingSessionId == nil else { return }
        notice = nil
        sheetError = nil
        guard let account else {
            notice = Notice(cluster: ClusterKey(clusterId: cluster.id, region: region, account: nil), message: KubernetesUpgradeError.accountChanged.message)
            return
        }
        let current = cluster.kubernetesVersion ?? cluster.version ?? ""
        let target = KubernetesUpgradeTarget(clusterId: cluster.id, clusterName: cluster.name, region: region, account: account, fromVersion: current)
        if let problem = targetError(for: target)
            ?? requestedVersion(forCluster: cluster.id, region: region, account: account).map(KubernetesUpgradeError.upgradeAlreadyRequested)
            ?? KubernetesVersionCatalog.upgradeBlocker(for: cluster)
            ?? (KubernetesVersionNumber(current) == nil ? .unknownVersionFormat(current) : nil) {
            close(problem, for: target)
            return
        }
        session = Session(target: target, recommendedVersion: cluster.upgradeAvailableTo)
        await loadVersions()
    }

    /// Loads the version list for the open session, again after a failure.
    func loadVersions() async {
        guard let session, !isLoadingVersions else { return }
        let key = apiKey()
        sheetError = nil
        isLoadingVersions = true
        defer { isLoadingVersions = false }
        do {
            let catalog = try await api.listVersions(apiKey: key)
            guard self.session?.id == session.id else { return }
            if let problem = targetError(for: session.target) {
                close(problem, for: session.target)
                return
            }
            switch KubernetesVersionCatalog.upgradeTargets(from: session.target.fromVersion, in: catalog) {
            case .success(let targets): self.session?.targets = targets
            case .failure(let problem): close(problem, for: session.target)
            }
        } catch {
            guard self.session?.id == session.id else { return }
            sheetError = Self.versionListFailedMessage(reason: CivoAPIError.userMessage(error))
        }
    }

    func cancel() {
        if let session, session.id == sendingSessionId {
            notice = Notice(cluster: session.target.key, message: Self.awaitingAnswerMessage(for: session.target))
        }
        session = nil
        sheetError = nil
    }

    /// Why `target` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for target: KubernetesUpgradeTarget) -> KubernetesUpgradeError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard target.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard target.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    /// Why the last upgrade of the cluster, loaded from `region` with `account`, was closed, or what became of it.
    func notice(forCluster clusterId: String, region: String, account: CivoAccount?) -> String? {
        guard let notice, notice.cluster == ClusterKey(clusterId: clusterId, region: region, account: account) else { return nil }
        return notice.message
    }

    // MARK: - Requested upgrades

    /// The version an accepted upgrade of the cluster is heading for, until the cluster reports it.
    func requestedVersion(forCluster clusterId: String, region: String, account: CivoAccount?) -> String? {
        let cluster = ClusterKey(clusterId: clusterId, region: region, account: account)
        return requestedUpgrades.first { $0.cluster == cluster }?.version
    }

    /// Forgets an accepted upgrade, and the notice that it is not finished, once `cluster`, loaded from
    /// `region` with `account`, reports its version.
    func clusterDidLoad(_ cluster: CivoKubernetesCluster, region: String, account: CivoAccount) {
        guard let reported = (cluster.kubernetesVersion ?? cluster.version).flatMap(KubernetesVersionNumber.init) else { return }
        let key = ClusterKey(clusterId: cluster.id, region: region, account: account)
        func isReached(_ version: String) -> Bool {
            KubernetesVersionNumber(version).flatMap(reported.compare).map { $0 != .orderedAscending } ?? false
        }
        requestedUpgrades.removeAll { $0.cluster == key && isReached($0.version) }
        if let notice, notice.cluster == key, let pending = notice.pendingVersion, isReached(pending) {
            self.notice = nil
        }
    }

    // MARK: - Upgrade

    /// Sends the upgrade to `version` once the cluster, loaded again, still runs the version the user saw,
    /// is not busy, and Civo still offers `version` for it.
    func upgrade(to version: CivoKubernetesVersion) async -> KubernetesUpgradeOutcome? {
        guard let session, !isSending, !isLoadingVersions else { return nil }
        let target = session.target
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

        let catalog: [CivoKubernetesVersion]
        do {
            let cluster = try await api.showCluster(target.clusterId, region: target.region, apiKey: key)
            catalog = try await api.listVersions(apiKey: key)
            // Cancelled, or closed by a region or key change, while loading.
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem, for: target) }
            if let problem = Self.staleTargetError(target, cluster: cluster) { return close(problem, for: target) }
        } catch let CivoAPIError.httpError(status, _) where status == 404 {
            guard self.session?.id == session.id else { return nil }
            return close(.clusterRemoved, for: target)
        } catch {
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem, for: target) }
            sheetError = CivoAPIError.userMessage(error)
            return nil
        }
        guard case .success(let offered) = KubernetesVersionCatalog.upgradeTargets(from: target.fromVersion, in: catalog),
              offered.contains(where: { $0.number == version.number }) else {
            return close(.targetUnavailable(version.version), for: target)
        }
        if let requested = requestedVersion(forCluster: target.clusterId, region: target.region, account: target.account) {
            return close(.upgradeAlreadyRequested(requested), for: target)
        }

        // From here on the sheet may be closed before Civo answers; the answer is then reported as a notice.
        sendingSessionId = session.id
        defer { sendingSessionId = nil }
        do {
            try await api.upgradeCluster(target.clusterId, to: version.version, region: target.region, apiKey: key)
        } catch CivoAPIError.decodingError {
            remember(version, for: target)
            return finish(session, notice: Self.unreadableAnswerMessage(for: target, version: version.version), pendingVersion: version.version, outcome: .uncertain)
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            // Civo refused the request, for example an upgrade path it does not allow.
            let reason = refusal.localizedDescription
            guard self.session?.id == session.id else {
                notice = Notice(cluster: target.key, message: Self.notSentMessage(for: target, reason: reason))
                return .cancelled
            }
            sheetError = reason
            return nil
        } catch {
            // A lost connection or a server error may follow an upgrade Civo already started, or none at all.
            // Nothing is remembered, so the checks against Civo's status decide on the next attempt.
            return finish(session, notice: Self.unknownResultMessage(for: target), outcome: .uncertain)
        }
        remember(version, for: target)
        recordActivity(target, version.version)
        return finish(session, notice: Self.acceptedMessage(for: target, version: version.version), pendingVersion: version.version, outcome: .requested)
    }

    static func acceptedMessage(for target: KubernetesUpgradeTarget, version: String) -> String {
        String(localized: "Civo accepted the upgrade of \"\(target.clusterName)\" from \(target.fromVersion) to \(version). The upgrade runs on Civo's side and is not finished yet; the status shown here updates when you refresh.")
    }

    static func unreadableAnswerMessage(for target: KubernetesUpgradeTarget, version: String) -> String {
        String(localized: "Civo accepted the upgrade of \"\(target.clusterName)\" to \(version), but its answer could not be read. Refresh to see the status of the cluster.")
    }

    static func unknownResultMessage(for target: KubernetesUpgradeTarget) -> String {
        String(localized: "The result of the upgrade request for \"\(target.clusterName)\" is unknown. Refresh to see the status of the cluster before trying again.")
    }

    static func awaitingAnswerMessage(for target: KubernetesUpgradeTarget) -> String {
        String(localized: "The upgrade request for \"\(target.clusterName)\" was already sent and can no longer be cancelled. Its result is shown here once Civo answers.")
    }

    static func notSentMessage(for target: KubernetesUpgradeTarget, reason: String) -> String {
        String(localized: "Civo did not upgrade \"\(target.clusterName)\": \(reason)")
    }

    static func versionListFailedMessage(reason: String?) -> String {
        String(localized: "The list of Kubernetes versions could not be loaded: \(reason ?? "")")
    }

    /// Why the reloaded `cluster` no longer matches what the user confirmed, nil while it does.
    private static func staleTargetError(_ target: KubernetesUpgradeTarget, cluster: CivoKubernetesCluster) -> KubernetesUpgradeError? {
        let reported = cluster.kubernetesVersion ?? cluster.version ?? ""
        guard let current = KubernetesVersionNumber(reported), current == KubernetesVersionNumber(target.fromVersion) else {
            return .clusterChanged
        }
        return KubernetesVersionCatalog.upgradeBlocker(for: cluster)
    }

    /// Only a refusal of the request proves that Civo left the cluster as it was.
    private static func provesNothingChanged(_ error: CivoAPIError) -> Bool {
        guard case .httpError(let status, _) = error else { return false }
        return (400..<500).contains(status)
    }

    private func remember(_ version: CivoKubernetesVersion, for target: KubernetesUpgradeTarget) {
        requestedUpgrades.removeAll { $0.cluster == target.key }
        requestedUpgrades.append(RequestedUpgrade(cluster: target.key, version: version.version))
    }

    private func finish(_ sent: Session, notice: String, pendingVersion: String? = nil, outcome: KubernetesUpgradeOutcome) -> KubernetesUpgradeOutcome {
        if session?.id == sent.id { session = nil }
        self.notice = Notice(cluster: sent.target.key, message: notice, pendingVersion: pendingVersion)
        return outcome
    }

    @discardableResult
    private func close(_ problem: KubernetesUpgradeError, for target: KubernetesUpgradeTarget) -> KubernetesUpgradeOutcome {
        session = nil
        sheetError = nil
        let pendingVersion: String? = if case .upgradeAlreadyRequested(let version) = problem { version } else { nil }
        notice = Notice(cluster: target.key, message: problem.message, pendingVersion: pendingVersion)
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
