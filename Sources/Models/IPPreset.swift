import Foundation

struct IPPreset: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String  // e.g. "Home", "Office"
    var ip: String    // e.g. "203.0.113.42"

    init(name: String, ip: String) {
        self.id = UUID()
        self.name = name
        self.ip = ip
    }
}
