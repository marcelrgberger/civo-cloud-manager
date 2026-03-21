import Foundation

struct CivoObjectStore: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let maxSize: Int?
    let objectstoreEndpoint: String?
    let status: String?
    let ownerInfo: CivoObjectStoreOwner?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case maxSize = "max_size"
        case objectstoreEndpoint = "objectstore_endpoint"
        case ownerInfo = "owner_info"
    }

    var maxSizeDisplay: String {
        if let maxSize { return "\(maxSize) GB" }
        return "—"
    }

    var credentialId: String? { ownerInfo?.credentialId }
    var accessKeyId: String? { ownerInfo?.accessKeyId }
}

struct CivoObjectStoreOwner: Codable, Sendable {
    let accessKeyId: String?
    let credentialId: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case name
        case accessKeyId = "access_key_id"
        case credentialId = "credential_id"
    }
}
