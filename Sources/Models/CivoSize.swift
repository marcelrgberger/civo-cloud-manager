import Foundation

struct CivoSize: Codable, Identifiable, Sendable {
    let name: String
    let description: String?
    let cpu: Int?
    let ram: Int?
    let disk: Int?
    let type: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, description, cpu, ram, disk, type
    }

    var displayName: String {
        if let description, !description.isEmpty { return description }
        return name
    }
}
