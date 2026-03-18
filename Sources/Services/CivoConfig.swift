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
        get { readKeychain() ?? UserDefaults.standard.string(forKey: "CivoCloudManager.apiKey.fallback") ?? "" }
        set { writeKeychain(newValue) }
    }

    var region: String {
        get { UserDefaults.standard.string(forKey: ConfigKey.region) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: ConfigKey.region) }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }
    var hasRegion: Bool { !region.isEmpty }
    var isConfigured: Bool { hasAPIKey && hasRegion }

    // MARK: - Keychain

    private func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ConfigKey.keychainService,
            kSecAttrAccount as String: ConfigKey.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychain(_ value: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ConfigKey.keychainService,
            kSecAttrAccount as String: ConfigKey.keychainAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard !value.isEmpty else { return }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ConfigKey.keychainService,
            kSecAttrAccount as String: ConfigKey.keychainAccount,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            Log.error("Keychain write failed: \(status)")
            // Fallback: store in UserDefaults if Keychain is unavailable
            UserDefaults.standard.set(value, forKey: "CivoCloudManager.apiKey.fallback")
        }
    }

    /// Read from Keychain first, fall back to UserDefaults if Keychain was unavailable.
    private func readWithFallback() -> String? {
        if let key = readKeychain() { return key }
        return UserDefaults.standard.string(forKey: "CivoCloudManager.apiKey.fallback")
    }
}
