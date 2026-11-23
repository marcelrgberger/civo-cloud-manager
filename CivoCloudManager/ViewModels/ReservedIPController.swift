import Foundation

/// How a confirmed reserved IP action ended. The sheet stays open, and `sheetError` explains why, for `failed`
/// and when `confirm` returns nil; every other outcome closes it.
enum ReservedIPOutcome: Equatable {
    /// Civo accepted the change and the list was reloaded.
    case done
    /// Civo accepted the change, but the list could not be reloaded afterwards.
    case doneRefreshFailed
    /// The request was sent but Civo's answer was missing, unreadable or unexpected. Nothing is sent again.
    case uncertain
    /// Civo refused the request. Nothing changed; the user may correct it and send it again on purpose.
    case failed
    /// The action was closed without sending anything; the notice explains why.
    case cancelled
}

/// What the user confirmed, with the input that goes with it.
enum ReservedIPAction: Equatable {
    case reserve(name: String)
    case rename(name: String)
    case assign(instanceId: String)
    case unassign(typedName: String)
    case release(typedName: String)

    var operation: ReservedIPOperation {
        switch self {
        case .reserve: .reserve
        case .rename: .rename
        case .assign: .assign
        case .unassign: .unassign
        case .release: .release
        }
    }
}

/// What the activity log records about an accepted change. Never keys, headers or raw answers.
struct ReservedIPActivity: Equatable {
    /// English, translated where shown; `%@` is filled with `detail`.
    let action: String
    let detail: String?
    let name: String
    let id: String
}

/// Reserves, renames, assigns, unassigns and releases one reserved IP at a time, only after the user confirmed
/// account, region and IP. Before assigning, unassigning or releasing, the IP is loaded again: one that is gone,
/// renamed or assigned differently sends nothing. Nothing is sent again on its own.
@Observable
@MainActor
final class ReservedIPController {
    struct Request: Equatable, Identifiable {
        /// Tells this action apart from a later one on the same IP.
        let id = UUID()
        let operation: ReservedIPOperation
        let account: CivoAccount
        let region: String
        /// The IP as the user saw it when the action was opened; nil when reserving.
        let ip: CivoReservedIP?
    }

    struct Notice: Equatable {
        let message: String
        /// Set while the shown list may not match what Civo has, until a reload succeeds.
        let offersReload: Bool
    }

    enum InstanceChoices: Equatable {
        case loading
        case loaded([ReservedIPInstanceChoice])
        case failed(String)
    }

    private enum Verification {
        case proceed(instanceName: String?)
        case stop(ReservedIPOutcome?)
    }

    private(set) var request: Request?
    private(set) var isSending = false
    /// The request on its way to Civo. It can no longer be called back.
    private var sendingRequestId: UUID?
    private(set) var sheetError: String?
    private(set) var notice: Notice?
    private(set) var instanceChoices = InstanceChoices.loading
    /// Reloads the shown list and reports whether the complete list was loaded. Set by the view model that owns the list.
    var reloadList: @MainActor () async -> Bool = { true }

    private let api: any ReservedIPAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (ReservedIPActivity) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any ReservedIPAPI = CivoReservedIPService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (ReservedIPActivity) -> Void = { activity in
            ActivityLog.shared.log(
                activity.action, detail: activity.detail,
                resourceType: "Reserved IP", resourceName: activity.name, resourceId: activity.id
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
                MainActor.assumeIsolated { self?.accountOrRegionDidChange() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    // MARK: - Request

    /// Opens the action for `ip` (nil when reserving), loaded from `region` with `account`, with the target captured now.
    func begin(
        _ operation: ReservedIPOperation,
        ip: CivoReservedIP?,
        region: String,
        account: CivoAccount,
        listIsComplete: Bool
    ) {
        guard sendingRequestId == nil else { return }
        notice = nil
        sheetError = nil
        instanceChoices = .loading
        let candidate = Request(operation: operation, account: account, region: region, ip: ip)
        let problem = targetError(for: candidate)
            ?? (listIsComplete ? nil : .incompleteList)
            ?? ip.flatMap { ReservedIPRules.eligibilityError(for: operation, assignment: $0.assignment) }
        if let problem {
            notice = Notice(message: problem.message, offersReload: false)
            return
        }
        request = candidate
    }

    func cancel() {
        guard !isSending else { return }
        request = nil
        sheetError = nil
    }

    func dismissNotice() {
        notice = nil
    }

    /// A successful reload of the list shows what Civo has, so a notice that asked for one is done.
    func listDidLoad() {
        if notice?.offersReload == true { notice = nil }
    }

    /// Why `request` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for request: Request) -> ReservedIPError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !request.region.isEmpty else { return .noRegion }
        guard request.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard request.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    /// Loads the instances the user can pick from, for the region and account the assignment was opened with.
    func loadInstances() async {
        guard let request, request.operation == .assign, targetError(for: request) == nil else { return }
        instanceChoices = .loading
        let result: PaginatedList<ReservedIPInstanceChoice>
        do {
            result = try await api.listInstances(region: request.region, apiKey: apiKey())
        } catch {
            guard isCurrent(request) else { return }
            instanceChoices = .failed(CivoAPIError.userMessage(error) ?? ReservedIPError.incompleteInstanceList.message)
            return
        }
        guard isCurrent(request), targetError(for: request) == nil else { return }
        instanceChoices = result.isComplete ? .loaded(result.items) : .failed(ReservedIPError.incompleteInstanceList.message)
    }

    // MARK: - Confirm

    func confirm(_ action: ReservedIPAction) async -> ReservedIPOutcome? {
        guard let request, !isSending, action.operation == request.operation,
              let action = Self.validated(action, for: request.ip) else { return nil }
        sheetError = nil
        if let problem = targetError(for: request) { return close(problem) }
        // One key for every request, so all of them reach the same account.
        let key = apiKey()
        guard !key.isEmpty else {
            sheetError = CivoAPIError.userMessage(CivoAPIError.noAPIKey)
            return nil
        }

        isSending = true
        defer { isSending = false }

        var instanceName: String?
        if let ip = request.ip, action.operation != .rename {
            switch await verify(request, ip: ip, action: action, key: key) {
            case .stop(let outcome): return outcome
            case .proceed(let name): instanceName = name
            }
        }
        // Nothing is awaited between this check and the request.
        if let problem = targetError(for: request) { return close(problem) }

        sendingRequestId = request.id
        defer { sendingRequestId = nil }
        let acceptedId: String?
        do {
            acceptedId = try await send(action, request: request, key: key)
        } catch let refusal as CivoAPIError where Self.provesNothingChanged(refusal) {
            if case .httpError(404, _) = refusal, request.ip != nil { return await resolveNotFound(request, key: key) }
            sheetError = refusal.localizedDescription
            return .failed
        } catch {
            // A timeout or a server error may follow a change Civo already made, or none at all.
            return await finishUncertain(request)
        }
        guard let acceptedId else { return await finishUncertain(request) }
        recordActivity(Self.activity(for: action, ip: request.ip, id: acceptedId, instanceName: instanceName))
        return await finishDone(request)
    }

    /// The action with the name trimmed, nil while the input does not allow sending it.
    private static func validated(_ action: ReservedIPAction, for ip: CivoReservedIP?) -> ReservedIPAction? {
        switch action {
        case .reserve(let name):
            return ReservedIPRules.normalizedName(name).map(ReservedIPAction.reserve)
        case .rename(let name):
            guard let name = ReservedIPRules.normalizedName(name), name != ip?.name else { return nil }
            return .rename(name: name)
        case .assign:
            return action
        case .unassign(let typed), .release(let typed):
            guard let ip, ReservedIPRules.typedNameMatches(typed, name: ip.name) else { return nil }
            return action
        }
    }

    /// Loads the IP again, and for an assignment the instances, and compares them with what the user confirmed.
    private func verify(_ request: Request, ip: CivoReservedIP, action: ReservedIPAction, key: String) async -> Verification {
        var instanceName: String?
        do {
            let current = try await api.showReservedIP(ip.id, region: request.region, apiKey: key)
            guard isCurrent(request) else { return .stop(nil) }
            if let problem = targetError(for: request) ?? ReservedIPRules.staleError(captured: ip, reloaded: current) {
                return .stop(close(problem))
            }
            if case .assign(let instanceId) = action {
                let instances = try await api.listInstances(region: request.region, apiKey: key)
                guard isCurrent(request) else { return .stop(nil) }
                if let problem = targetError(for: request) { return .stop(close(problem)) }
                guard instances.isComplete else {
                    sheetError = ReservedIPError.incompleteInstanceList.message
                    return .stop(nil)
                }
                guard let chosen = instances.items.first(where: { $0.id == instanceId }) else {
                    return .stop(close(.instanceGone))
                }
                instanceName = chosen.name
            }
        } catch {
            guard isCurrent(request) else { return .stop(nil) }
            if let problem = targetError(for: request) { return .stop(close(problem)) }
            if case CivoAPIError.httpError(404, _) = error { return .stop(await resolveNotFound(request, key: key)) }
            sheetError = CivoAPIError.userMessage(error)
            return .stop(nil)
        }
        return .proceed(instanceName: instanceName)
    }

    /// The id of the IP Civo accepted the change for, nil when its answer is not the expected acknowledgment.
    private func send(_ action: ReservedIPAction, request: Request, key: String) async throws -> String? {
        let region = request.region
        let id = request.ip?.id ?? ""
        switch action {
        case .reserve(let name):
            let ack = try await api.reserve(name: name, region: region, apiKey: key)
            return ack.id.isEmpty ? nil : ack.id
        case .rename(let name):
            let ack = try await api.rename(id, to: name, region: region, apiKey: key)
            return ack.id == id ? id : nil
        case .assign(let instanceId):
            return try await api.assign(id, toInstance: instanceId, region: region, apiKey: key).isSuccess ? id : nil
        case .unassign:
            return try await api.unassign(id, region: region, apiKey: key).isSuccess ? id : nil
        case .release:
            return try await api.release(id, region: region, apiKey: key).isSuccess ? id : nil
        }
    }

    /// A 404 means the IP is gone only when the complete list no longer shows it.
    private func resolveNotFound(_ request: Request, key: String) async -> ReservedIPOutcome? {
        var isGone = false
        if let list = try? await api.listReservedIPs(region: request.region, apiKey: key), list.isComplete {
            isGone = !list.items.contains { $0.id == request.ip?.id }
        }
        guard isCurrent(request) else { return nil }
        if let problem = targetError(for: request) { return close(problem) }
        _ = await reloadList()
        return close(isGone ? .ipGone : .ipStateUnclear, outcome: isGone ? .cancelled : .uncertain)
    }

    private func finishDone(_ sent: Request) async -> ReservedIPOutcome {
        if request?.id == sent.id { request = nil }
        // A list of another account or region cannot show what became of this change.
        guard targetError(for: sent) == nil else {
            notice = Notice(message: ReservedIPError.contextChangedWhilePending.message, offersReload: false)
            return .doneRefreshFailed
        }
        let isRefreshed = await reloadList()
        notice = isRefreshed ? nil : Notice(message: Self.refreshFailedMessage, offersReload: true)
        return isRefreshed ? .done : .doneRefreshFailed
    }

    private func finishUncertain(_ sent: Request) async -> ReservedIPOutcome {
        if request?.id == sent.id { request = nil }
        guard targetError(for: sent) == nil else {
            notice = Notice(message: ReservedIPError.contextChangedWhilePending.message, offersReload: false)
            return .uncertain
        }
        let isRefreshed = await reloadList()
        notice = Notice(message: Self.unclearResultMessage, offersReload: !isRefreshed)
        return .uncertain
    }

    static var refreshFailedMessage: String {
        String(localized: "Done, but the list of reserved IPs could not be refreshed. Reload to see the current state.")
    }

    static var unclearResultMessage: String {
        String(localized: "Civo's answer to this change is unclear. The list was reloaded; check it before trying again. Nothing is sent again automatically.")
    }

    private static func activity(for action: ReservedIPAction, ip: CivoReservedIP?, id: String, instanceName: String?) -> ReservedIPActivity {
        switch action {
        case .reserve(let name): ReservedIPActivity(action: "Created reserved IP", detail: nil, name: name, id: id)
        case .rename(let name): ReservedIPActivity(action: "Renamed reserved IP", detail: nil, name: name, id: id)
        case .assign: ReservedIPActivity(action: "Assigned reserved IP to %@", detail: instanceName, name: ip?.name ?? "", id: id)
        case .unassign: ReservedIPActivity(action: "Unassigned reserved IP", detail: nil, name: ip?.name ?? "", id: id)
        case .release: ReservedIPActivity(action: "Released reserved IP", detail: nil, name: ip?.name ?? "", id: id)
        }
    }

    /// Only a refusal of the request proves that Civo left the IP as it was. A 408 is a timeout, not a refusal.
    private static func provesNothingChanged(_ error: CivoAPIError) -> Bool {
        guard case .httpError(let status, _) = error, status != requestTimeoutStatus else { return false }
        return (400..<500).contains(status)
    }

    private static let requestTimeoutStatus = 408

    private func isCurrent(_ other: Request) -> Bool {
        request?.id == other.id
    }

    @discardableResult
    private func close(_ problem: ReservedIPError, outcome: ReservedIPOutcome = .cancelled) -> ReservedIPOutcome {
        request = nil
        sheetError = nil
        notice = Notice(message: problem.message, offersReload: false)
        return outcome
    }

    private func accountOrRegionDidChange() {
        notice = nil
        guard let request, request.id != sendingRequestId, let problem = targetError(for: request) else { return }
        close(problem)
    }
}
