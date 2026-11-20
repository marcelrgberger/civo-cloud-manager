import Foundation
import LocalAuthentication

/// Shows, copies, edits and deletes the saved credentials of one instance. Contents are read only
/// after Touch ID or the system password, one authentication per action, and dropped again whenever
/// `access` is invalidated (timeout, closing, deactivation, screen lock, sleep, API key change).
@Observable
@MainActor
final class InstanceCredentialVault {
    enum Field: Hashable {
        case username, password
    }

    enum Entry: Equatable {
        case unknown, absent, present
    }

    /// An edit form holding the stored values closes after this time, like a revealed value after
    /// `PasswordAccess.visibleDuration`, but with room to type a new password.
    static let editingDuration: Duration = .seconds(120)

    let target: ConsoleTarget
    let access: PasswordAccess
    private(set) var entry: Entry = .unknown
    private(set) var error: InstanceCredentialError?
    private(set) var revealedFields: Set<Field> = []
    /// True while the form holds the stored values for editing.
    private(set) var isEditing = false

    @ObservationIgnored private var revealed: InstanceCredential?
    @ObservationIgnored private var editContext: LAContext?
    private let key: InstanceCredentialKey
    private let store: InstanceCredentialStore

    init(target: ConsoleTarget, store: InstanceCredentialStore? = nil, access: PasswordAccess = PasswordAccess()) {
        self.target = target
        self.key = InstanceCredentialKey(target)
        self.store = store ?? .shared
        self.access = access
        access.onInvalidate = { [weak self] in self?.discardSecrets() }
    }

    /// Checks whether an entry exists, without authentication. Values shown or being edited are
    /// dropped once the entry is gone, so a stale edit cannot recreate a deleted entry.
    func refresh() {
        do {
            entry = try store.contains(key) ? .present : .absent
            error = nil
        } catch {
            entry = .unknown
            record(error)
        }
        if entry != .present { access.invalidate() }
    }

    /// The value of a revealed field, nil while it is hidden.
    func value(of field: Field) -> String? {
        guard revealedFields.contains(field), let revealed else { return nil }
        return switch field {
        case .username: revealed.username
        case .password: revealed.password
        }
    }

    func reveal(_ field: Field) async {
        await access.reveal(reason: String(localized: "Show saved credentials")) { context in
            guard let credential = load(with: context) else { return false }
            revealed = credential
            revealedFields.insert(field)
            return true
        }
    }

    func hide(_ field: Field) {
        revealedFields.remove(field)
        guard revealedFields.isEmpty else { return }
        revealed = nil
        access.hide()
    }

    /// Copies a field through `SecretPasteboard`; a hidden field only after authentication.
    func copy(_ field: Field) async -> Bool {
        await access.copy(reason: String(localized: "Copy saved credentials"), isVisible: revealedFields.contains(field)) { context in
            guard let context else { return value(of: field) }
            return load(with: context).map { field == .username ? $0.username : $0.password }
        }
    }

    /// Returns the stored values for the edit form after authentication. The same authentication
    /// later allows saving them, so editing costs one prompt.
    func beginEditing() async -> InstanceCredential? {
        hideAll()
        guard let context = await access.authorize(reason: String(localized: "Edit saved credentials")) else { return nil }
        guard let credential = load(with: context) else {
            context.invalidate()
            return nil
        }
        editContext = context
        isEditing = true
        return credential
    }

    func cancelEditing() {
        editContext?.invalidate()
        editContext = nil
        isEditing = false
    }

    /// Saves a new entry, or overwrites the stored one while editing. Fails closed when the Mac
    /// cannot authenticate its owner, because nobody could ever read the entry again.
    func save(username: String, password: String) -> Bool {
        let credential = InstanceCredential(username: username, password: password)
        do {
            if let editContext {
                try store.replace(credential, for: key, context: editContext)
            } else {
                guard DeviceOwner.canAuthenticate() else { throw InstanceCredentialError.deviceAuthenticationUnavailable }
                try store.create(credential, for: key)
            }
            cancelEditing()
            entry = .present
            error = nil
            return true
        } catch {
            record(error)
            return false
        }
    }

    /// Deleting reveals nothing, so it needs a confirmation but no authentication.
    func delete() {
        do {
            try store.delete(key)
            access.invalidate()
            entry = .absent
            error = nil
        } catch {
            record(error)
        }
    }

    /// Hides everything and discards pending authentications and an open edit.
    func invalidate() {
        access.invalidate()
    }

    private func hideAll() {
        revealedFields = []
        revealed = nil
        access.hide()
    }

    private func discardSecrets() {
        revealedFields = []
        revealed = nil
        cancelEditing()
    }

    private func load(with context: LAContext) -> InstanceCredential? {
        do {
            guard let credential = try store.read(key, context: context) else {
                entry = .absent
                return nil
            }
            entry = .present
            error = nil
            return credential
        } catch {
            record(error)
            return nil
        }
    }

    private func record(_ error: Error) {
        let credentialError = error as? InstanceCredentialError ?? .unreadableEntry
        Log.error("Instance credentials: \(credentialError.logDescription)")
        self.error = credentialError
    }
}
