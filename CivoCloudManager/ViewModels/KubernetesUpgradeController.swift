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
        let clusterId: String
        let region: String
        let account: CivoAccount
        let version: String
    }

    private(set) var session: Session?
    private(set) var isLoadingVersions = false
    private(set) var isSending = false
    /// The session whose upgrade is on its way to Civo. It can no longer be called back.
    private var sendingSessionId: UUID?
    /// Shown in the sheet: the version list could not be loaded, or Civo refused the upgrade.
    private(set) var sheetError: String?
    /// Why the last upgrade was closed, or what became of it, shown on the cluster detail page.
    private(set) var notice: String?
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
                "Requested Kubernetes upgrade", detail: "\(target.fromVersion) to \(version)",
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
            notice = KubernetesUpgradeError.accountChanged.message
            return
        }
        let current = cluster.kubernetesVersion ?? cluster.version ?? ""
        let target = KubernetesUpgradeTarget(clusterId: cluster.id, clusterName: cluster.name, region: region, account: account, fromVersion: current)
        if let problem = targetError(for: target)
            ?? requestedVersion(forCluster: cluster.id, region: region, account: account).map(KubernetesUpgradeError.upgradeAlreadyRequested)
            ?? KubernetesVersionCatalog.upgradeBlocker(for: cluster)
            ?? (KubernetesVersionNumber(current) == nil ? .unknownVersionFormat(current) : nil) {
            notice = problem.message
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
                close(problem)
                return
            }
            switch KubernetesVersionCatalog.upgradeTargets(from: session.target.fromVersion, in: catalog) {
            case .success(let targets): self.session?.targets = targets
            case .failure(let problem): close(problem)
            }
        } catch {
            guard self.session?.id == session.id else { return }
            sheetError = Self.versionListFailedMessage(reason: CivoAPIError.userMessage(error))
        }
    }

    func cancel() {
        if let session, session.id == sendingSessionId {
            notice = Self.awaitingAnswerMessage(for: session.target)
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

    // MARK: - Requested upgrades

    /// The version an accepted upgrade of the cluster is heading for, until the cluster reports it.
    func requestedVersion(forCluster clusterId: String, region: String, account: CivoAccount?) -> String? {
        requestedUpgrades.first { $0.clusterId == clusterId && $0.region == region && $0.account == account }?.version
    }

    /// Forgets an accepted upgrade once `cluster`, loaded from `region` with `account`, reports its version.
    func clusterDidLoad(_ cluster: CivoKubernetesCluster, region: String, account: CivoAccount) {
        guard let reported = (cluster.kubernetesVersion ?? cluster.version).flatMap(KubernetesVersionNumber.init) else { return }
        requestedUpgrades.removeAll { request in
            guard request.clusterId == cluster.id, request.region == region, request.account == account,
                  let requested = KubernetesVersionNumber(request.version) else { return false }
            return reported.compare(to: requested).map { $0 != .orderedAscending } ?? false
        }
    }

    // MARK: - Upgrade

    /// Sends the upgrade to `version` once the cluster, loaded again, still runs the version the user saw,
    /// is not busy, and Civo still offers `version` for it.
    func upgrade(to version: CivoKubernetesVersion) async -> KubernetesUpgradeOutcome? {
        guard let session, !isSending, !isLoadingVersions else { return nil }
        let target = session.target
        sheetError = nil
        if let problem = targetError(for: target) { return close(problem) }
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
            if let problem = targetError(for: target) { return close(problem) }
            if let problem = Self.staleTargetError(target, cluster: cluster) { return close(problem) }
        } catch let CivoAPIError.httpError(status, _) where status == 404 {
            guard self.session?.id == session.id else { return nil }
            return close(.clusterRemoved)
        } catch {
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem) }
            sheetError = CivoAPIError.userMessage(error)
            return nil
        }
        guard case .success(let offered) = KubernetesVersionCatalog.upgradeTargets(from: target.fromVersion, in: catalog),
              offered.contains(where: { $0.number == version.number }) else {
            return close(.targetUnavailable(version.version))
        }
        if let requested = requestedVersion(forCluster: target.clusterId, region: target.region, account: target.account) {
            return close(.upgradeAlreadyRequested(requested))
        }

        // From here on the sheet may be closed before Civo answers; the answer is then reported as a notice.
        sendingSessionId = session.id
        defer { sendingSessionId = nil }
        do {
            try await api.upgradeCluster(target.clusterId, to: version.version, region: target.region, apiKey: key)
        } catch CivoAPIError.decodingError {
            remember(version, for: target)
            return finish(session, notice: Self.unreadableAnswerMessage(for: target, version: version.version), outcome: .uncertain)
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            // Civo refused the request, for example an upgrade path it does not allow.
            let reason = refusal.localizedDescription
            guard self.session?.id == session.id else {
                notice = Self.notSentMessage(for: target, reason: reason)
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
        return finish(session, notice: Self.acceptedMessage(for: target, version: version.version), outcome: .requested)
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
        requestedUpgrades.removeAll { $0.clusterId == target.clusterId && $0.region == target.region && $0.account == target.account }
        requestedUpgrades.append(RequestedUpgrade(clusterId: target.clusterId, region: target.region, account: target.account, version: version.version))
    }

    private func finish(_ sent: Session, notice: String, outcome: KubernetesUpgradeOutcome) -> KubernetesUpgradeOutcome {
        if session?.id == sent.id { session = nil }
        self.notice = notice
        return outcome
    }

    @discardableResult
    private func close(_ problem: KubernetesUpgradeError) -> KubernetesUpgradeOutcome {
        session = nil
        sheetError = nil
        notice = problem.message
        return .cancelled
    }

    private func dropInvalidSession() {
        guard let session, let problem = targetError(for: session.target) else { return }
        if session.id == sendingSessionId {
            cancel()
        } else {
            close(problem)
        }
    }
}
