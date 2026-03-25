import Foundation
import Security

/// Stores and retrieves SSH private keys in the macOS Keychain.
/// With iCloud Keychain enabled, keys sync across all Apple devices (E2E encrypted).
enum SSHKeychain {
    private static let service = "de.berger-rosenstock.CivoCloudManager.ssh"

    /// Save a private key to the Keychain.
    static func save(name: String, privateKey: Data) -> Bool {
        // Delete existing if any
        delete(name: name)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecAttrLabel as String: "SSH Key: \(name)",
            kSecAttrComment as String: "Private SSH key managed by Civo Cloud Manager",
            kSecValueData as String: privateKey,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,  // Sync via iCloud Keychain
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a private key from the Keychain.
    static func load(name: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Delete a private key from the Keychain.
    @discardableResult
    static func delete(name: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// List all stored SSH key names.
    static func listKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else { return [] }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
    }

    /// Check if a key exists in the Keychain.
    static func exists(name: String) -> Bool {
        load(name: name) != nil
    }
}
