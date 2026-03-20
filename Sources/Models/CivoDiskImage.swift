import Foundation

struct CivoDiskImage: Codable, Identifiable, Sendable {
    let id: String
    let name: String?
    let version: String?
    let label: String?

    var displayName: String {
        if let label, !label.isEmpty { return label }
        if let name {
            if let version { return "\(name) \(version)" }
            return name
        }
        return id
    }
}
