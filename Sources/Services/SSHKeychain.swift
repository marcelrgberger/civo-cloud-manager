import Foundation
import CryptoKit

/// Stores SSH private keys as encrypted files in the app's Application Support directory.
/// Files are encrypted with a key derived from the machine's hardware UUID.
enum SSHKeychain {
    private static var storageDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CivoCloudManager/ssh-keys")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var encryptionKey: SymmetricKey {
        // Derive key from bundle ID + hardware UUID for basic protection
        let seed = (Bundle.main.bundleIdentifier ?? "civo") + (hardwareUUID ?? "fallback")
        let hash = SHA256.hash(data: Data(seed.utf8))
        return SymmetricKey(data: hash)
    }

    private static var hardwareUUID: String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        guard let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else { return nil }
        return uuid
    }

    static func save(name: String, privateKey: Data) -> Bool {
        do {
            let sealed = try AES.GCM.seal(privateKey, using: encryptionKey)
            let combined = sealed.combined!
            try combined.write(to: storageDir.appendingPathComponent(name))
            return true
        } catch {
            Log.error("SSHKeychain.save failed for '\(name)': \(error.localizedDescription)")
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
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: storageDir.path) else { return [] }
        return files.filter { !$0.hasPrefix(".") }.sorted()
    }

    static func exists(name: String) -> Bool {
        FileManager.default.fileExists(atPath: storageDir.appendingPathComponent(name).path)
    }
}
