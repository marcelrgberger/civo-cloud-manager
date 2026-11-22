import Foundation

/// The account and region a load balancer list was loaded from.
struct LoadBalancerContext: Equatable, Sendable {
    let account: CivoAccount
    let region: String
}

/// The load balancer an edit was started for, with the account and region it was listed in.
struct LoadBalancerTarget: Equatable, Sendable {
    let id: String
    let name: String
    let context: LoadBalancerContext

    var region: String { context.region }
}

/// Why a load balancer edit was refused. Nothing was sent in any of these cases.
enum LoadBalancerEditError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case accountChanged
    case staleList
    case removed
    case changedElsewhere
    case noChanges
    case notEditable(LoadBalancerEditability)

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Changing load balancers requires Full Access.")
        case .noRegion:
            String(localized: "The region of this load balancer is unknown. Refresh the list and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the load balancer edit was cancelled. Nothing was sent.")
        case .accountChanged:
            String(localized: "The API key changed, so the load balancer edit was cancelled. Nothing was sent.")
        case .staleList:
            String(localized: "The list is from another account or region. Refresh it first.")
        case .removed:
            String(localized: "The load balancer no longer exists, so nothing was changed.")
        case .changedElsewhere:
            String(localized: "The load balancer was changed elsewhere in the meantime. Check the comparison against its current values and save again.")
        case .noChanges:
            String(localized: "Nothing was changed.")
        case .notEditable(let editability):
            // Only refusals are reported, and every refusal has a message.
            editability.message ?? ""
        }
    }
}

/// How a save ended. The editor stays open, and `saveError` explains why, when `save` returns nil.
enum LoadBalancerSaveOutcome: Equatable {
    /// Civo reports exactly the requested settings.
    case saved(CivoLoadBalancer)
    /// Civo reports something else than requested; nothing is corrected or sent again.
    case mismatch(LoadBalancerMismatch)
    /// The update may have been applied, but Civo's current values could not be read for this account and region.
    case unverified
    /// The edit was closed without sending; `notice` explains why.
    case cancelled
}

/// Edits one load balancer at a time. Before the update the load balancer is loaded again: one that was removed
/// is reported and never recreated, and one changed elsewhere must be confirmed again. After the update it is read
/// back, and only a matching answer counts as saved. An unclear result is reported, never reset or sent again.
@Observable
@MainActor
final class LoadBalancerEditor {
    struct Session: Equatable {
        /// Tells this edit apart from a later one of the same load balancer.
        let id = UUID()
        let target: LoadBalancerTarget
        /// The load balancer as last loaded; the comparison and the conflict check use it.
        var original: CivoLoadBalancer
    }

    private(set) var session: Session?
    private(set) var isSaving = false
    /// The session whose update is on its way to Civo. It can no longer be called back.
    private var sendingSessionId: UUID?
    private(set) var saveError: String?
    /// The result of the last edit, or why it was closed without saving, shown above the details.
    private(set) var notice: String?

    private let api: any LoadBalancerAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (_ action: String, LoadBalancerTarget) -> Void
    private let diagnostics: @MainActor (String) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any LoadBalancerAPI = CivoLoadBalancerService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (_ action: String, LoadBalancerTarget) -> Void = { action, target in
            ActivityLog.shared.log(action, resourceType: "Load Balancer", resourceName: target.name, resourceId: target.id)
        },
        diagnostics: @escaping @MainActor (String) -> Void = { Log.error($0) }
    ) {
        self.api = api
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.apiKey = apiKey
        self.notificationCenter = notificationCenter
        self.recordActivity = recordActivity
        self.diagnostics = diagnostics
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

    /// Opens the editor for `lb`, listed under `context`. A list from another account or region is not edited.
    func begin(editing lb: CivoLoadBalancer, context: LoadBalancerContext?) {
        notice = nil
        saveError = nil
        let editability = LoadBalancerEditability(lb)
        guard editability == .editable else {
            notice = LoadBalancerEditError.notEditable(editability).message
            return
        }
        guard let context else {
            notice = LoadBalancerEditError.staleList.message
            return
        }
        let target = LoadBalancerTarget(id: lb.id, name: lb.name, context: context)
        switch targetError(for: target) {
        case nil:
            session = Session(target: target, original: lb)
        case .regionChanged?, .accountChanged?:
            notice = LoadBalancerEditError.staleList.message
        case let problem?:
            notice = problem.message
        }
    }

    func cancel() {
        if let session, session.id == sendingSessionId {
            notice = Self.awaitingAnswerMessage(for: session.target)
        }
        session = nil
        saveError = nil
    }

    /// Why `target` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for target: LoadBalancerTarget) -> LoadBalancerEditError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard target.context.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard target.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    // MARK: - Save

    /// Sends `draft` once the load balancer, loaded again, still matches what the user compared against,
    /// then reads it back to confirm the result.
    func save(_ draft: LoadBalancerDraft) async -> LoadBalancerSaveOutcome? {
        guard let session, !isSaving else { return nil }
        let target = session.target
        saveError = nil
        if let problem = targetError(for: target) { return close(problem) }
        if let invalid = draft.problems(editing: session.original).first {
            saveError = invalid.message
            return nil
        }
        // One key for the reload, the update and the read back, so all reach the same account.
        let key = apiKey()
        guard !key.isEmpty else {
            saveError = LoadBalancerFailure.noAPIKey.message
            return nil
        }

        isSaving = true
        defer { isSaving = false }

        let loaded = await load(target, apiKey: key)
        // Cancelled, or closed by a region or key change, while the load balancer was loading.
        guard self.session?.id == session.id else { return nil }
        if let problem = targetError(for: target) { return close(problem) }
        let current: CivoLoadBalancer
        switch loaded {
        case .success(let lb):
            current = lb
        case .failure(.notFound):
            return close(.removed)
        case .failure(let failure):
            diagnostics("Load balancer reload failed: \(failure.diagnosticName) \(target.id)")
            saveError = failure.message
            return nil
        }

        let editability = LoadBalancerEditability(current)
        guard editability == .editable else { return close(.notEditable(editability)) }
        guard current.hasSameSettings(as: session.original) else {
            self.session?.original = current
            saveError = LoadBalancerEditError.changedElsewhere.message
            return nil
        }
        self.session?.original = current
        guard !draft.changes(from: current).isEmpty else {
            saveError = LoadBalancerEditError.noChanges.message
            return nil
        }

        // From here on the editor may be closed, and another one opened, before Civo answers. The answer then
        // leaves the later editor alone and is reported as a notice naming the load balancer.
        sendingSessionId = session.id
        defer { sendingSessionId = nil }
        do {
            _ = try await api.updateLoadBalancer(target.id, body: draft.updateBody(for: current, region: target.region), region: target.region, apiKey: key)
        } catch {
            let failure = LoadBalancerFailure(error)
            if failure.provesNothingChanged {
                diagnostics("Load balancer update refused: \(failure.diagnosticName) \(target.id)")
                let reason = Self.refusalMessage(for: failure)
                guard self.session?.id == session.id else {
                    notice = Self.notSavedMessage(for: target, reason: reason)
                    return .cancelled
                }
                saveError = reason
                return nil
            }
            // A lost connection, a cancelled request, a server error or an unreadable answer may follow a change
            // Civo already applied, so the result is read back like after an accepted update.
            diagnostics("Load balancer update result unknown: \(failure.diagnosticName) \(target.id)")
        }

        let outcome = await readBack(draft, of: current, target: target, apiKey: key)
        switch outcome {
        case .saved:
            recordActivity("Updated load balancer", target)
        default:
            recordActivity("Load balancer update not confirmed", target)
        }
        if self.session?.id == session.id {
            self.session = nil
            notice = Self.resultMessage(for: outcome, target: target, isEditorOpen: true)
        } else {
            notice = Self.resultMessage(for: outcome, target: target, isEditorOpen: false)
        }
        return outcome
    }

    /// Compares Civo's current values with the request. A changed account or region leaves the result unverified.
    private func readBack(_ draft: LoadBalancerDraft, of original: CivoLoadBalancer, target: LoadBalancerTarget, apiKey key: String) async -> LoadBalancerSaveOutcome {
        guard targetError(for: target) == nil else { return .unverified }
        let loaded = await load(target, apiKey: key)
        guard targetError(for: target) == nil else { return .unverified }
        switch loaded {
        case .success(let actual):
            guard let mismatch = draft.mismatch(in: actual, requestedFrom: original) else { return .saved(actual) }
            return .mismatch(mismatch)
        case .failure(let failure):
            diagnostics("Load balancer read back failed: \(failure.diagnosticName) \(target.id)")
            return .unverified
        }
    }

    /// The load balancer as Civo reports it now. Only when Civo's answer cannot be read is the list asked instead,
    /// with the same account and region; every other failure is returned as it is.
    private func load(_ target: LoadBalancerTarget, apiKey key: String) async -> Result<CivoLoadBalancer, LoadBalancerFailure> {
        do {
            return .success(try await api.getLoadBalancer(target.id, region: target.region, apiKey: key))
        } catch {
            let failure = LoadBalancerFailure(error)
            guard failure == .unreadableAnswer else { return .failure(failure) }
        }
        do {
            let list = try await api.listLoadBalancers(region: target.region, apiKey: key)
            guard let lb = list.first(where: { $0.id == target.id }) else { return .failure(.notFound) }
            return .success(lb)
        } catch {
            return .failure(LoadBalancerFailure(error))
        }
    }

    // MARK: - Messages

    static func awaitingAnswerMessage(for target: LoadBalancerTarget) -> String {
        String(localized: "The change of load balancer \"\(target.name)\" was already sent and can no longer be cancelled. Its result is shown here once Civo answers.")
    }

    static func notSavedMessage(for target: LoadBalancerTarget, reason: String) -> String {
        String(localized: "The change of load balancer \"\(target.name)\" was not saved: \(reason)")
    }

    private static func refusalMessage(for failure: LoadBalancerFailure) -> String {
        switch failure {
        case .rejected:
            String(localized: "Civo refused the change, so nothing was changed. Check the backends and your quota in the Civo dashboard.")
        case .notFound:
            LoadBalancerEditError.removed.message
        default:
            failure.message ?? ""
        }
    }

    private static func resultMessage(for outcome: LoadBalancerSaveOutcome, target: LoadBalancerTarget, isEditorOpen: Bool) -> String? {
        switch outcome {
        case .saved:
            isEditorOpen ? nil : String(localized: "The change of load balancer \"\(target.name)\" was saved.")
        case .mismatch(let mismatch):
            String(localized: "Civo reports load balancer \"\(target.name)\" differently from the requested change: \(Self.describe(mismatch)). Nothing was corrected or sent again. Check it in the list.")
        case .unverified:
            String(localized: "The change of load balancer \"\(target.name)\" was sent, but its result could not be confirmed. Check it in the list.")
        case .cancelled:
            nil
        }
    }

    static func describe(_ mismatch: LoadBalancerMismatch) -> String {
        var parts = mismatch.fields.map { field -> String in
            switch field {
            case .name: String(localized: "Name")
            case .algorithm: String(localized: "Algorithm")
            case .trafficPolicy: String(localized: "Traffic Policy")
            case .addedBackend: String(localized: "Backends")
            }
        }
        parts += mismatch.missingBackends.map { String(localized: "missing backend \($0.display)") }
        // Only backends with a valid address, protocol and ports are quoted; Civo's text is not shown otherwise.
        let unexpected = mismatch.unexpectedBackends.filter { LoadBalancerBackendKey($0) != nil }
        parts += unexpected.map { String(localized: "unexpected backend \($0.display)") }
        if unexpected.count < mismatch.unexpectedBackends.count {
            parts.append(String(localized: "a backend Civo reports in a form the app cannot read"))
        }
        return parts.joined(separator: ", ")
    }

    private func close(_ problem: LoadBalancerEditError) -> LoadBalancerSaveOutcome {
        session = nil
        saveError = nil
        notice = problem.message
        return .cancelled
    }

    private func dropInvalidSession() {
        guard let session, let problem = targetError(for: session.target) else { return }
        if session.id == sendingSessionId {
            cancel()
        } else {
            _ = close(problem)
        }
    }
}
