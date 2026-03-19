import Foundation

struct CivoNetwork: Codable, Identifiable, Sendable {
    let id: String
    let label: String?
    let name: String?
    let region: String?
    let status: String?
    let isDefault: Bool?

    var displayName: String { label ?? name ?? id }

    enum CodingKeys: String, CodingKey {
        case id, label, name, region, status
        case isDefault = "default"
    }
}
