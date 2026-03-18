import Foundation

struct CivoDomain: Codable, Identifiable, Sendable {
    let id: String
    let name: String
}

struct CivoDomainRecord: Codable, Identifiable, Sendable {
    let id: String
    let name: String?
    let type: String?
    let value: String?
    let ttl: Int?
    let priority: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, type, value, ttl, priority
    }
}
