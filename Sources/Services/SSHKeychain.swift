import Foundation
import Security

/// Stores and retrieves SSH private keys in the macOS Keychain.
/// With iCloud Keychain enabled, keys sync across all Apple devices (E2E encrypted).
enum SSHKeychain {
    private static let service = "de.berger-rosenstock.CivoCloudManager.ssh"

    /// Save a private key to the Keychain.
    /// Use data protection keychain for consistent save/load in sandbox
    private static let useDataProtection: [String: Any] = [
        kSecUseDataProtectionKeychain as String: true
    ]

    static func save(name: String, privateKey: Data) -> Bool {
        delete(name: name)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecAttrLabel as String: "SSH Key: \(name)",
            kSecValueData as String: privateKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        query.merge(useDataProtection) { _, new in new }

        let status = SecItemAdd(query as CFDictionary, nil)
        Log.info("SSHKeychain.save '\(name)': \(status == errSecSuccess ? "OK" : "FAILED (\(status))")")
        return status == errSecSuccess
    }

    static func load(name: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        query.merge(useDataProtection) { _, new in new }

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func delete(name: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
        query.merge(useDataProtection) { _, new in new }
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func listKeys() -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        query.merge(useDataProtection) { _, new in new }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        Log.info("SSHKeychain.listKeys: status=\(status)")

        guard status == errSecSuccess, let items = result as? [[String: Any]] else { return [] }

        let names = items.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
        Log.info("SSHKeychain.listKeys: found \(names)")
        return names
    }

    /// Check if a key exists in the Keychain.
    static func exists(name: String) -> Bool {
        load(name: name) != nil
    }
}
