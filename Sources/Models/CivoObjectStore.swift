import Foundation

struct CivoObjectStore: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let maxSize: String?
    let objectstoreEndpoint: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case maxSize = "max_size"
        case objectstoreEndpoint = "objectstore_endpoint"
    }

    var maxSizeInt: Int { Int(maxSize ?? "0") ?? 0 }
}
