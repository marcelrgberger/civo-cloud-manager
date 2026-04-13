import Foundation

struct PausedObjectStore: Codable, Identifiable, Sendable {
    let id: String
    let originalName: String
    let originalMaxSize: Int
    let credentialId: String?
    let accessKeyId: String?
    let region: String
    let endpoint: String
    let pausedAt: Date
    let fileCount: Int
    let totalSizeBytes: Int64
    let vaultPrefix: String

    var pausedAtDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: pausedAt, relativeTo: Date())
    }

    var totalSizeDisplay: String {
        if totalSizeBytes < 1024 { return "\(totalSizeBytes) B" }
        if totalSizeBytes < 1024 * 1024 { return "\(totalSizeBytes / 1024) KB" }
        if totalSizeBytes < 1024 * 1024 * 1024 { return "\(totalSizeBytes / (1024 * 1024)) MB" }
        return String(format: "%.1f GB", Double(totalSizeBytes) / (1024 * 1024 * 1024))
    }
}

struct PausedStoreManifest: Codable, Sendable {
    var stores: [PausedObjectStore]
}
