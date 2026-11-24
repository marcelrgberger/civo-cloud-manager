import Foundation
import LocalAuthentication
import Security

extension Notification.Name {
    /// Posted after saved instance credentials were created, replaced or deleted. Carries no data.
    static let instanceCredentialsDidChange = Notification.Name("CivoCloudManager.instanceCredentialsDidChange")
}

/// Keychain account of an instance's saved credentials: instance ID and the region it was loaded
/// from. The name is not part of it, so a renamed instance keeps its entry.
struct InstanceCredentialKey: Hashable, Sendable {
    let account: String

    init(_ target: ConsoleTarget) {
        account = "\(target.region.lowercased())/\(target.instanceId.lowercased())"
    }
}

/// User name and password saved for an instance. In memory only: not Codable, redacted in
/// descriptions and mirrors.
struct InstanceCredential: Equatable, Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let username: String
    let password: String

    var description: String { "InstanceCredential(<redacted>)" }
    var debugDescription: String { description }
    var customMirror: Mirror { Mirror(self, children: [:]) }
}

enum InstanceCredentialError: Error, Equatable {
    case emptyPassword
    case deviceAuthenticationUnavailable
    case unreadableEntry
    case keychain(OSStatus)

    /// Fixed, non-sensitive text for `Log`: only the status code.
    var logDescription: String {
        switch self {
        case .keychain(let status): return "keychain-\(status)"
        default: return "\(self)"
        }
    }

    /// Localized text, or nil when nothing should be shown (the user cancelled authentication).
    var userMessage: String? {
        switch self {
        case .emptyPassword:
            return String(localized: "Enter a password.")
        case .deviceAuthenticationUnavailable:
            return String(localized: "Touch ID or a system password is required to save credentials.")
        case .unreadableEntry:
            return String(localized: "The saved credentials could not be read.")
        case .keychain(errSecUserCanceled):
            return nil
        case .keychain(errSecDuplicateItem):
            return String(localized: "Credentials for this instance are already saved.")
        case .keychain(errSecAuthFailed):
            return String(localized: "Authentication with Touch ID or the system password failed.")
        case .keychain(errSecInteractionNotAllowed):
            return String(localized: "The keychain is not available right now. Unlock your Mac and try again.")
        case .keychain(errSecMissingEntitlement):
            return String(localized: "This build of the app cannot use the protected keychain.")
        case .keychain(let status):
            return String(localized: "The keychain reported an error (\(Int(status))).")
        }
    }
}

/// The keychain calls the store makes; injectable so tests never touch the user's keychain.
struct KeychainClient {
    var add: ([String: Any]) -> OSStatus
    var update: ([String: Any], [String: Any]) -> OSStatus
    /// Returns the status and, if the query asked for it, the item's data.
    var copyMatching: ([String: Any]) -> (OSStatus, Data?)
    var delete: ([String: Any]) -> OSStatus

    static var system: KeychainClient {
        KeychainClient(
            add: { SecItemAdd($0 as CFDictionary, nil) },
            update: { SecItemUpdate($0 as CFDictionary, $1 as CFDictionary) },
            copyMatching: { query in
                var result: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                return (status, result as? Data)
            },
            delete: { SecItemDelete($0 as CFDictionary) }
        )
    }
}

/// Saved instance credentials in this Mac's data protection keychain: readable only after Touch ID
/// or the system password, never synchronized, never migrated to another device. Only
/// `errSecItemNotFound` means "no entry"; every other status is reported.
@MainActor
final class InstanceCredentialStore {
    #if DEBUG
    static let shared = InstanceCredentialStore(keychain: DemoMode.isActive ? .demo : .system)
    #else
    static let shared = InstanceCredentialStore(keychain: .system)
    #endif

    static let service = "de.berger-rosenstock.CivoCloudManager.instance-credentials"
    static let protection = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    static let accessControlFlags: SecAccessControlCreateFlags = .userPresence

    private let keychain: KeychainClient
    private let notificationCenter: NotificationCenter

    init(keychain: KeychainClient, notificationCenter: NotificationCenter = .default) {
        self.keychain = keychain
        self.notificationCenter = notificationCenter
    }

    /// Checks for an entry without reading it and without any authentication prompt. The keychain
    /// answers an existing protected entry with `errSecInteractionNotAllowed`, because finding it
    /// would need the prompt this check forbids; a missing entry is still `errSecItemNotFound`.
    func contains(_ key: InstanceCredentialKey) throws -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        var query = Self.query(for: key)
        query[kSecUseAuthenticationContext as String] = context
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let (status, _) = keychain.copyMatching(query)
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed: return true
        case errSecItemNotFound: return false
        default: throw InstanceCredentialError.keychain(status)
        }
    }

    /// Reads the entry with a context the owner already authenticated. Nil only if there is no entry.
    func read(_ key: InstanceCredentialKey, context: LAContext) throws -> InstanceCredential? {
        var query = Self.query(for: key)
        query[kSecUseAuthenticationContext as String] = context
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        let (status, data) = keychain.copyMatching(query)
        switch status {
        case errSecSuccess:
            guard let data, let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
                throw InstanceCredentialError.unreadableEntry
            }
            return InstanceCredential(username: payload.username, password: payload.password)
        case errSecItemNotFound:
            return nil
        default:
            throw InstanceCredentialError.keychain(status)
        }
    }

    /// Adds a new entry. An existing entry is never overwritten here (`errSecDuplicateItem`).
    func create(_ credential: InstanceCredential, for key: InstanceCredentialKey) throws {
        let data = try Self.encode(credential)
        let status = keychain.add(try Self.addQuery(for: key, data: data))
        guard status == errSecSuccess else { throw InstanceCredentialError.keychain(status) }
        notificationCenter.post(name: .instanceCredentialsDidChange, object: nil)
    }

    /// Overwrites the entry with the context authenticated for editing; adds it if it vanished meanwhile.
    func replace(_ credential: InstanceCredential, for key: InstanceCredentialKey, context: LAContext) throws {
        let data = try Self.encode(credential)
        var query = Self.query(for: key)
        query[kSecUseAuthenticationContext as String] = context
        let status = keychain.update(query, [kSecValueData as String: data])
        switch status {
        case errSecSuccess:
            notificationCenter.post(name: .instanceCredentialsDidChange, object: nil)
        case errSecItemNotFound:
            try create(credential, for: key)
        default:
            throw InstanceCredentialError.keychain(status)
        }
    }

    /// Removes the entry; a missing entry counts as removed.
    func delete(_ key: InstanceCredentialKey) throws {
        let status = keychain.delete(Self.query(for: key))
        switch status {
        case errSecSuccess:
            notificationCenter.post(name: .instanceCredentialsDidChange, object: nil)
        case errSecItemNotFound:
            break
        default:
            throw InstanceCredentialError.keychain(status)
        }
    }

    // MARK: - Queries

    static func query(for key: InstanceCredentialKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.account,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: false,
        ]
    }

    static func addQuery(for key: InstanceCredentialKey, data: Data) throws -> [String: Any] {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(nil, protection, accessControlFlags, &error) else {
            error?.release()
            throw InstanceCredentialError.keychain(errSecParam)
        }
        var query = query(for: key)
        query[kSecAttrAccessControl as String] = accessControl
        query[kSecValueData as String] = data
        return query
    }

    /// User name and password both live in the protected data, so neither is readable without authentication.
    private struct Payload: Codable {
        let username: String
        let password: String
    }

    private static func encode(_ credential: InstanceCredential) throws -> Data {
        guard !credential.password.isEmpty else { throw InstanceCredentialError.emptyPassword }
        return try JSONEncoder().encode(Payload(username: credential.username, password: credential.password))
    }
}
