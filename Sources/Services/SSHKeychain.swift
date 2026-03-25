import Foundation
import Security

/// Stores and retrieves SSH private keys in the macOS Keychain.
/// With iCloud Keychain enabled, keys sync across all Apple devices (E2E encrypted).
enum SSHKeychain {
    private static let service = "de.berger-rosenstock.CivoCloudManager.ssh"

    /// Save a private key to the Keychain.
    static func save(name: String, privateKey: Data) -> Bool {
        delete(name: name)

        // Try with iCloud sync first, fall back to local-only
        var query = baseQuery(name: name)
        query[kSecValueData as String] = privateKey
        query[kSecAttrLabel as String] = "SSH Key: \(name)"
        query[kSecAttrSynchronizable as String] = kCFBooleanTrue!
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        var status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            // Fallback: save without iCloud sync
            query.removeValue(forKey: kSecAttrSynchronizable as String)
            status = SecItemAdd(query as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    static func load(name: String) -> Data? {
        // Try sync first, then local
        for sync in [kCFBooleanTrue!, kCFBooleanFalse!] {
            var query = baseQuery(name: name)
            query[kSecAttrSynchronizable as String] = sync
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var result: AnyObject?
            if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
               let data = result as? Data {
                return data
            }
        }

        // Try without sync attribute at all
        var query = baseQuery(name: name)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    @discardableResult
    static func delete(name: String) -> Bool {
        // Delete from all (sync + non-sync)
        for sync in [kCFBooleanTrue!, kCFBooleanFalse!] {
            var query = baseQuery(name: name)
            query[kSecAttrSynchronizable as String] = sync
            SecItemDelete(query as CFDictionary)
        }
        // Also delete without sync attr
        SecItemDelete(baseQuery(name: name) as CFDictionary)
        return true
    }

    static func listKeys() -> [String] {
        var allNames: Set<String> = []

        // Search both sync and non-sync
        for sync: Any in [kCFBooleanTrue!, kCFBooleanFalse!, kSecAttrSynchronizableAny] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrSynchronizable as String: sync,
                kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
            ]

            var result: AnyObject?
            if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
               let items = result as? [[String: Any]] {
                for item in items {
                    if let name = item[kSecAttrAccount as String] as? String {
                        allNames.insert(name)
                    }
                }
            }
        }

        return allNames.sorted()
    }

    private static func baseQuery(name: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
    }

    /// Check if a key exists in the Keychain.
    static func exists(name: String) -> Bool {
        load(name: name) != nil
    }
}
