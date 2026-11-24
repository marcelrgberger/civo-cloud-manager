import CryptoKit
import Foundation
import Security

private enum ConfigKey {
    static let region = "CivoCloudManager.region"
    static let keychainService = "de.berger-rosenstock.CivoCloudManager"
    static let keychainAccount = "apikey"
}

extension Notification.Name {
    /// Posted after the stored API key changes, so open console windows can stop using the old account.
    static let civoAPIKeyDidChange = Notification.Name("CivoCloudManager.apiKeyDidChange")
    /// Posted after the Settings region changes, so captured instance targets of the old region are dropped.
    static let civoRegionDidChange = Notification.Name("CivoCloudManager.regionDidChange")
}

/// The account of an API key, held as a SHA-256 fingerprint so the key itself is not kept.
struct CivoAccount: Equatable, Sendable {
    private let fingerprint: SHA256.Digest

    init(apiKey: String) {
        fingerprint = SHA256.hash(data: Data(apiKey.utf8))
    }
}

final class CivoConfig: @unchecked Sendable {
    static let shared = CivoConfig()

    /// Central support portal for all Apple-native apps. Identical URL for every app;
    /// the server-side router forwards to the current support/feature-request form.
    static let supportPortalURL = URL(string: "https://support.apps.digitalfreedom.co.za")!

    var apiKey: String {
        get { DemoMode.isActive ? DemoMode.apiKey : readKeychain() ?? "" }
        set {
            guard !DemoMode.isActive else { return }
            writeKeychain(newValue)
            NotificationCenter.default.post(name: .civoAPIKeyDidChange, object: nil)
        }
    }

    var region: String {
        get { DemoMode.isActive ? DemoMode.region : AppEnvironment.defaults.string(forKey: ConfigKey.region) ?? "" }
        set {
            guard !DemoMode.isActive, newValue != region else { return }
            AppEnvironment.defaults.set(newValue, forKey: ConfigKey.region)
            NotificationCenter.default.post(name: .civoRegionDidChange, object: nil)
        }
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

        // Always set accessibility explicitly on update to keep the class consistent across upgrades.
        let updateAttrs: [String: Any] = [
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
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
