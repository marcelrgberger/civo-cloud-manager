import Foundation

struct StorageLoadContext: Equatable, Sendable {
    let account: CivoAccount
    let region: String
}

@Observable
@MainActor
final class StorageOperationGate {
    enum Kind { case credentialChange, pauseResume, save, s3Work }
    struct Token: Equatable { fileprivate let id = UUID() }
    private var operations: [UUID: Kind] = [:]
    var isExclusive: Bool { operations.values.contains(.credentialChange) }
    var isBusy: Bool { !operations.isEmpty }
    var s3WorkCount: Int { operations.values.filter { $0 == .s3Work }.count }

    var problem: ObjectStoreCredentialChangeError? {
        if operations.values.contains(.pauseResume) { return .pauseBusy }
        if operations.values.contains(.save) || isExclusive { return .saveBusy }
        if s3WorkCount > 0 { return .transferBusy }
        return nil
    }

    func begin(_ kind: Kind) -> Token? {
        guard !isExclusive else { return nil }
        if kind != .s3Work && isBusy { return nil }
        // S3 work cannot start while pause/resume or a save is using the store.
        if kind == .s3Work && operations.values.contains(where: { $0 != .s3Work }) { return nil }
        let token = Token()
        operations[token.id] = kind
        return token
    }

    func end(_ token: Token) { operations[token.id] = nil }
}

struct SecretRevealState {
    struct Ticket: Equatable { let identity: String; fileprivate let nonce = UUID() }
    private var ticket: Ticket?
    private var revealed = false

    mutating func begin(for identity: String) -> Ticket {
        let next = Ticket(identity: identity)
        ticket = next
        revealed = false
        return next
    }
    mutating func complete(_ ticket: Ticket, success: Bool) {
        guard self.ticket == ticket else { return }
        revealed = success
    }
    func isRevealed(for identity: String) -> Bool { revealed && ticket?.identity == identity }
    mutating func reset() { ticket = nil; revealed = false }
}

enum ObjectStoreCredentialEligibility {
    static func isEligible(_ credential: CivoObjectStoreCredential, currentAccessKeyId: String?) -> Bool {
        !credential.id.isEmpty && !(credential.accessKeyId ?? "").isEmpty
            && credential.accessKeyId != currentAccessKeyId && credential.suspended != true
            && ["", "ready"].contains((credential.status ?? "").lowercased())
    }
    static func candidates(from credentials: [CivoObjectStoreCredential], currentAccessKeyId: String?) -> [CivoObjectStoreCredential] {
        credentials.filter { isEligible($0, currentAccessKeyId: currentAccessKeyId) }
    }
}

enum ObjectStoreCredentialChangeError: Error, Equatable {
    case accessRevoked, contextChanged, reload, storeChanged, unavailable, incomplete
    case pauseBusy, saveBusy, transferBusy, inactive, vault, unconfirmed
    case authentication, permission, notFound, rejected, rateLimit, requestFailed, cancelled

    var message: String {
        switch self {
        case .accessRevoked: String(localized: "Changing credentials requires Full Access.")
        case .contextChanged: String(localized: "The account or region changed. Reopen the credential change. Nothing was sent.")
        case .reload: String(localized: "Reload the storage list first.")
        case .storeChanged: String(localized: "The object store changed. Reload its details before changing credentials.")
        case .unavailable: String(localized: "The selected credential is no longer available or usable in this region.")
        case .incomplete: String(localized: "The credential list is incomplete. Reload it before changing credentials.")
        case .pauseBusy: String(localized: "Pause or resume is still running.")
        case .saveBusy: String(localized: "Another storage change is still running.")
        case .transferBusy: String(localized: "A transfer or file listing is still running.")
        case .inactive: String(localized: "Only a ready object store can change credentials.")
        case .vault: String(localized: "The pause vault cannot change credentials.")
        case .unconfirmed: String(localized: "The request may have been applied, but the new assignment could not be confirmed. It was not sent again. Check again before using this object store.")
        case .authentication: String(localized: "Authentication failed. Check your API key in Settings.")
        case .permission: String(localized: "Access denied. Your API key may not have permission for this action.")
        case .notFound: String(localized: "Resource not found. It may have been deleted.")
        case .rejected: String(localized: "Civo rejected the credential change. Reload the store and credentials.")
        case .rateLimit: String(localized: "Rate limit exceeded. Please wait a moment and try again.")
        case .requestFailed: String(localized: "The storage request failed. Check your connection and try again.")
        case .cancelled: String(localized: "The credential change was cancelled before sending.")
        }
    }

    static func from(_ error: Error) -> Self {
        if let error = error as? Self { return error }
        if CivoAPIError.isCancelled(error) { return .cancelled }
        if case CivoAPIError.incompleteList = error { return .incomplete }
        if case CivoAPIError.httpError(let code, _) = error {
            switch code {
            case 401: return .authentication
            case 403: return .permission
            case 404: return .notFound
            case 422: return .rejected
            case 429: return .rateLimit
            default: break
            }
        }
        return .requestFailed
    }
}

struct ObjectStoreCredentialTarget: Equatable {
    let storeId: String
    let storeName: String
    let context: StorageLoadContext
    let currentCredentialId: String?
    let currentAccessKeyId: String?
}

enum ObjectStoreCredentialChangeOutcome: Equatable { case changed, failed, uncertain }

@Observable
@MainActor
final class ObjectStoreCredentialSwitcher {
    struct Session: Identifiable {
        let id = UUID()
        let target: ObjectStoreCredentialTarget
        let currentName: String
    }
    private(set) var session: Session?
    private(set) var candidates: [CivoObjectStoreCredential] = []
    private(set) var isLoading = false
    private(set) var isSubmitting = false
    private(set) var message: String?
    private(set) var hasOtherCredentials = false
    private(set) var isComplete = false
    private weak var vm: VolumeViewModel?
    private let api: any ObjectStoreCredentialAPI
    private let recordActivity: (ObjectStoreCredentialTarget) -> Void

    init(vm: VolumeViewModel, api: any ObjectStoreCredentialAPI, recordActivity: @escaping (ObjectStoreCredentialTarget) -> Void) {
        self.vm = vm
        self.api = api
        self.recordActivity = recordActivity
    }

    func begin(for store: CivoObjectStore) async {
        guard let vm, !isSubmitting else { return }
        message = nil
        if let problem = vm.credentialChangeProblem(for: store) { message = problem.message; return }
        guard let context = vm.selectedObjectStoreContext else { return }
        let target = ObjectStoreCredentialTarget(storeId: store.id, storeName: store.name, context: context, currentCredentialId: store.credentialId, currentAccessKeyId: store.accessKeyId)
        let opened = Session(target: target, currentName: vm.credentialForStore(store)?.displayName ?? store.ownerInfo?.name ?? String(localized: "Unknown credential"))
        session = opened
        candidates = []
        isComplete = false
        hasOtherCredentials = false
        isLoading = true
        defer { if session?.id == opened.id { isLoading = false } }
        let key = vm.currentAPIKey
        do {
            let list = try await api.listCredentials(region: context.region, apiKey: key)
            try validate(opened)
            isComplete = list.isComplete
            guard list.isComplete else { throw ObjectStoreCredentialChangeError.incomplete }
            hasOtherCredentials = list.items.contains { $0.accessKeyId != target.currentAccessKeyId }
            candidates = ObjectStoreCredentialEligibility.candidates(from: list.items, currentAccessKeyId: target.currentAccessKeyId)
        } catch {
            if session?.id == opened.id { message = ObjectStoreCredentialChangeError.from(error).message }
        }
    }

    func cancel() {
        session = nil
        candidates = []
        isLoading = false
        isComplete = false
        hasOtherCredentials = false
        message = nil
    }

    private func validate(_ opened: Session) throws {
        guard session?.id == opened.id, !Task.isCancelled else { throw ObjectStoreCredentialChangeError.cancelled }
        guard let vm, vm.isCredentialAccessAllowed else { throw ObjectStoreCredentialChangeError.accessRevoked }
        guard vm.currentStorageContext == opened.target.context else { throw ObjectStoreCredentialChangeError.contextChanged }
        guard !vm.isAssignmentUnconfirmed(opened.target.storeId) else { throw ObjectStoreCredentialChangeError.unconfirmed }
        guard opened.target.storeName != ObjectStorePauseService.vaultName else { throw ObjectStoreCredentialChangeError.vault }
    }

    func confirm(credentialId: String) async -> ObjectStoreCredentialChangeOutcome? {
        guard let opened = session, let vm, !isSubmitting, !isLoading, isComplete else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        message = nil
        let target = opened.target
        let key = vm.currentAPIKey
        do { try validate(opened) } catch {
            message = ObjectStoreCredentialChangeError.from(error).message
            return .failed
        }
        guard let token = vm.operationGate.begin(.credentialChange) else {
            message = (vm.operationGate.problem ?? .saveBusy).message
            return .failed
        }
        defer { vm.operationGate.end(token) }
        let selected: CivoObjectStoreCredential
        do {
            let current = try await api.showObjectStore(target.storeId, region: target.context.region, apiKey: key)
            try validate(opened)
            guard current.id == target.storeId, current.name == target.storeName,
                  current.credentialId == target.currentCredentialId, current.accessKeyId == target.currentAccessKeyId else {
                throw ObjectStoreCredentialChangeError.storeChanged
            }
            guard current.status?.lowercased() == "ready" else { throw ObjectStoreCredentialChangeError.inactive }
            let list = try await api.listCredentials(region: target.context.region, apiKey: key)
            try validate(opened)
            guard list.isComplete else { throw ObjectStoreCredentialChangeError.incomplete }
            guard let match = list.items.first(where: { $0.id == credentialId }),
                  ObjectStoreCredentialEligibility.isEligible(match, currentAccessKeyId: current.accessKeyId) else {
                throw ObjectStoreCredentialChangeError.unavailable
            }
            selected = match
            // Refresh the credentials used by the next S3 client, from this same complete, pinned list.
            vm.installCredentials(list, context: target.context)
            try validate(opened)
        } catch {
            if session?.id == opened.id { message = ObjectStoreCredentialChangeError.from(error).message }
            return .failed
        }
        guard let accessKey = selected.accessKeyId else { return .failed }
        vm.invalidateStorageReads()
        // An unstructured task owns the dispatched request and reconciliation, even if the sheet task is cancelled.
        let result = await Task {
            do { try self.validate(opened) } catch {
                if self.session?.id == opened.id { self.message = ObjectStoreCredentialChangeError.from(error).message }
                return ObjectStoreCredentialChangeOutcome.failed
            }
            return await self.dispatch(target, sessionId: opened.id, accessKey: accessKey, apiKey: key)
        }.value
        switch result {
        case .changed:
            if session?.id == opened.id { cancel() }
        case .uncertain:
            if session?.id == opened.id {
                isComplete = false
                message = ObjectStoreCredentialChangeError.unconfirmed.message
            }
        case .failed: break
        }
        return result
    }

    private func dispatch(_ target: ObjectStoreCredentialTarget, sessionId: UUID, accessKey: String, apiKey: String) async -> ObjectStoreCredentialChangeOutcome {
        do {
            _ = try await api.changeCredential(of: target.storeId, to: accessKey, region: target.context.region, apiKey: apiKey)
        } catch CivoAPIError.httpError(let code, _) where [401, 403, 404, 422, 429].contains(code) {
            if session?.id == sessionId { message = ObjectStoreCredentialChangeError.from(CivoAPIError.httpError(code, "")).message }
            return .failed
        } catch {
            // Anything but a definite refusal can follow a mutation that already reached Civo.
        }
        do {
            let verified = try await api.showObjectStore(target.storeId, region: target.context.region, apiKey: apiKey)
            if verified.id == target.storeId && verified.accessKeyId == accessKey && verified.status?.lowercased() == "ready" {
                recordActivity(target)
                vm?.resolveCredentialAssignment(target, store: verified)
                return .changed
            }
        } catch { /* An unreadable or failed GET cannot establish the assignment. */ }
        vm?.markCredentialAssignmentUnconfirmed(target, requestedAccessKey: accessKey)
        return .uncertain
    }

    func checkAgain(storeId: String) async {
        guard let vm, !isSubmitting, vm.isCredentialAccessAllowed,
              let pending = vm.pendingCredentialAssignment(storeId),
              let token = vm.operationGate.begin(.credentialChange) else { return }
        let context = vm.currentStorageContext
        let key = vm.currentAPIKey
        isSubmitting = true
        defer { isSubmitting = false; vm.operationGate.end(token) }
        do {
            let verified = try await api.showObjectStore(storeId, region: context.region, apiKey: key)
            guard vm.currentStorageContext == context, vm.isCredentialAccessAllowed else { return }
            // An old-key GET is not a completion barrier for a timed-out PATCH.
            guard verified.id == storeId, verified.accessKeyId == pending.requestedAccessKey,
                  verified.status?.lowercased() == "ready" else { return }
            recordActivity(pending.target)
            vm.resolveCredentialAssignment(pending.target, store: verified)
        } catch { /* Keep the uncertainty marker and the fixed recovery message. */ }
    }
}
