import Foundation
import CryptoKit
import Security

/// Stores SSH private keys as encrypted files in the app's Application Support directory.
/// Files are encrypted with a random key stored securely in the Keychain.
enum SSHKeychain {
    private static let keychainService = "de.berger-rosenstock.CivoCloudManager.ssh-encryption"
    private static let keychainAccount = "ssh-key-encryption"

    private static var storageDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CivoCloudManager/ssh-keys")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var encryptionKey: SymmetricKey {
        // Try to load existing key from Keychain
        if let existing = loadKeychainKey() {
            return SymmetricKey(data: existing)
        }
        // Generate and store a new random key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        saveKeychainKey(keyData)
        return newKey
    }

    private static func loadKeychainKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }

    private static func saveKeychainKey(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Log.error("Failed to store SSH encryption key in Keychain: \(status)")
        }
    }

    static func save(name: String, privateKey: Data) -> Bool {
        do {
            let sealed = try AES.GCM.seal(privateKey, using: encryptionKey)
            guard let combined = sealed.combined else {
                Log.error("SSH key encryption failed: no combined representation")
                return false
            }
            let path = storageDir.appendingPathComponent(name)
            try combined.write(to: path)
            Log.info("SSH key saved for '\(name)'")
            return true
        } catch {
            Log.error("SSH key save failed for '\(name)': \(error.localizedDescription)")
            return false
        }
    }

    static func load(name: String) -> Data? {
        let path = storageDir.appendingPathComponent(name)
        guard let combined = try? Data(contentsOf: path),
              let sealed = try? AES.GCM.SealedBox(combined: combined),
              let decrypted = try? AES.GCM.open(sealed, using: encryptionKey) else { return nil }
        return decrypted
    }

    @discardableResult
    static func delete(name: String) -> Bool {
        let path = storageDir.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: path)
        return true
    }

    static func listKeys() -> [String] {
        let dir = storageDir
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else {
            Log.error("SSH keychain: cannot read directory")
            return []
        }
        return files.filter { !$0.hasPrefix(".") }.sorted()
    }

    static func exists(name: String) -> Bool {
        FileManager.default.fileExists(atPath: storageDir.appendingPathComponent(name).path)
    }
}
