import Foundation
import Security

private enum ConfigKey {
    static let region = "CivoCloudManager.region"
    static let keychainService = "de.berger-rosenstock.CivoCloudManager"
    static let keychainAccount = "apikey"
}

final class CivoConfig: @unchecked Sendable {
    static let shared = CivoConfig()

    var apiKey: String {
        get { readKeychain() ?? "" }
        set { writeKeychain(newValue) }
    }

    var region: String {
        get { UserDefaults.standard.string(forKey: ConfigKey.region) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: ConfigKey.region) }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }
    var hasRegion: Bool { !region.isEmpty }

    // MARK: - Keychain

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ConfigKey.keychainService,
            kSecAttrAccount as String: ConfigKey.keychainAccount,
        ]
    }

    private func readKeychain() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychain(_ value: String) {
        guard !value.isEmpty else {
            // Delete only when explicitly clearing
            SecItemDelete(baseQuery as CFDictionary)
            return
        }

        guard let valueData = value.data(using: .utf8) else { return }

        // Try update first — preserves existing item if present
        let updateAttrs: [String: Any] = [kSecValueData as String: valueData]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttrs as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // No existing item — add new
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = valueData
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                Log.error("Keychain add failed: \(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            Log.error("Keychain update failed: \(updateStatus)")
        }
    }
}
