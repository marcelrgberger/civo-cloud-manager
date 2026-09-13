import Foundation
import CryptoKit
import Security

/// Stores SSH private keys as encrypted files in the app's Application Support directory.
/// Files are encrypted with a random key stored securely in the Keychain.
enum SSHKeychain {
    private static let keychainService = "de.berger-rosenstock.CivoCloudManager.ssh-encryption"
    private static let keychainAccount = "ssh-key-encryption"
    private static let keyLock = NSLock()

    enum KeyError: Error, Equatable {
        case keychain(OSStatus)
        case missingKey
        case invalidKey
    }

    static func hasBackups(in directory: URL) throws -> Bool {
        // Ignore only recognized Finder metadata: even a key named .DS_Store must block replacement.
        for name in try FileManager.default.contentsOfDirectory(atPath: directory.path) {
            guard name == ".DS_Store" else { return true }
            let file = try FileHandle(forReadingFrom: directory.appendingPathComponent(name))
            defer { try? file.close() }
            let header = try file.read(upToCount: 8)
            guard header == Data([0, 0, 0, 1, 0x42, 0x75, 0x64, 0x31]) else { return true }
        }
        return false
    }

    private static var storageDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CivoCloudManager/ssh-keys")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Only an explicit not-found result permits creation. A failed write never yields a usable key.
    static func resolveKey(allowCreation: Bool, read: () throws -> Data?, add: (Data) -> OSStatus) throws -> SymmetricKey {
        func validated(_ data: Data) throws -> SymmetricKey {
            guard data.count == 32 else { throw KeyError.invalidKey }
            return SymmetricKey(data: data)
        }
        if let existing = try read() { return try validated(existing) }
        guard allowCreation else { throw KeyError.missingKey }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        let status = add(keyData)
        if status == errSecSuccess { return newKey }
        if status == errSecDuplicateItem, let existing = try read() {
            return try validated(existing)
        }
        throw KeyError.keychain(status)
    }

    private static func loadKeychainKey() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
        guard let data = result as? Data else { throw KeyError.invalidKey }
        return data
    }

    private static func saveKeychainKey(_ data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        return SecItemAdd(query as CFDictionary, nil)
    }

    static func save(name: String, privateKey: Data) -> Bool {
        keyLock.lock()
        defer { keyLock.unlock() }
        do {
            let dir = storageDir
            // If encrypted backups exist, a missing master key requires recovery, never replacement.
            let key = try resolveKey(allowCreation: !hasBackups(in: dir), read: loadKeychainKey, add: saveKeychainKey)
            let sealed = try AES.GCM.seal(privateKey, using: key)
            guard let combined = sealed.combined else {
                Log.error("SSH key encryption failed: no combined representation")
                return false
            }
            let path = dir.appendingPathComponent(name)
            try combined.write(to: path, options: .atomic)
            Log.info("SSH key saved for '\(name)'")
            return true
        } catch {
            Log.error("SSH key save failed for '\(name)': \(error.localizedDescription)")
            return false
        }
    }

    static func load(name: String) -> Data? {
        keyLock.lock()
        defer { keyLock.unlock() }
        let path = storageDir.appendingPathComponent(name)
        guard let combined = try? Data(contentsOf: path),
              let sealed = try? AES.GCM.SealedBox(combined: combined),
              let key = try? resolveKey(allowCreation: false, read: loadKeychainKey, add: saveKeychainKey),
              let decrypted = try? AES.GCM.open(sealed, using: key) else { return nil }
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
