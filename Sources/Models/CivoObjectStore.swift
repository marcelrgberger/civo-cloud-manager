import Foundation

struct CivoObjectStore: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let maxSize: Int?
    let objectstoreEndpoint: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case maxSize = "max_size"
        case objectstoreEndpoint = "objectstore_endpoint"
    }

    var maxSizeDisplay: String {
        if let maxSize { return "\(maxSize) GB" }
        return "—"
    }
}
