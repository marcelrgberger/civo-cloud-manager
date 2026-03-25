import Foundation
import Security

/// Stores and retrieves SSH private keys in the macOS Keychain.
/// With iCloud Keychain enabled, keys sync across all Apple devices (E2E encrypted).
enum SSHKeychain {
    private static let service = "de.berger-rosenstock.CivoCloudManager.ssh"

    /// Save a private key to the Keychain.
    static func save(name: String, privateKey: Data) -> Bool {
        delete(name: name)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecAttrLabel as String: "SSH Key: \(name)",
            kSecValueData as String: privateKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Log.error("SSHKeychain.save failed for '\(name)': OSStatus \(status)")
        } else {
            Log.info("SSHKeychain.save OK for '\(name)' (\(privateKey.count) bytes)")
        }
        return status == errSecSuccess
    }

    static func load(name: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func delete(name: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func listKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess && status != errSecItemNotFound {
            Log.error("SSHKeychain.listKeys failed: OSStatus \(status)")
        }
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            Log.info("SSHKeychain.listKeys: \(status == errSecItemNotFound ? "empty" : "error \(status)")")
            return []
        }

        let names = items.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
        Log.info("SSHKeychain.listKeys: found \(names.count) keys: \(names)")
        return names
    }

    /// Check if a key exists in the Keychain.
    static func exists(name: String) -> Bool {
        load(name: name) != nil
    }
}
