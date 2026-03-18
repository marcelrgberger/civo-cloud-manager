import Foundation

struct CivoNetwork: Codable, Identifiable, Sendable {
    let id: String
    let label: String?
    let region: String?
    let status: String?
    let isDefault: String?

    var name: String { label ?? id }

    enum CodingKeys: String, CodingKey {
        case id, label, region, status
        case isDefault = "default"
    }
}
