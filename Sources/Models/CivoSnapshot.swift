import Foundation

struct CivoSnapshot: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let instanceId: String?
    let region: String
    let sizeGb: Int
    let state: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, region, state
        case instanceId = "instance_id"
        case sizeGb = "size_gb"
        case createdAt = "created_at"
    }

    var stateColor: String {
        switch state.lowercased() {
        case "available", "complete": return "green"
        case "creating", "pending": return "orange"
        case "error", "failed": return "red"
        default: return "gray"
        }
    }
}
