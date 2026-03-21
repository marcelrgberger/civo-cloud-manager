import Foundation

struct CivoObjectStore: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let maxSize: Int?
    let objectstoreEndpoint: String?
    let status: String?
    let ownerInfo: CivoObjectStoreOwner?
    let bucketURL: String?
    let region: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, region
        case maxSize = "max_size"
        case objectstoreEndpoint = "objectstore_endpoint"
        case ownerInfo = "owner_info"
        case bucketURL = "bucket_url"
        case createdAt = "created_at"
    }

    var maxSizeDisplay: String {
        if let maxSize { return "\(maxSize) GB" }
        return "—"
    }

    var accessKeyId: String? { ownerInfo?.accessKeyId }
    var secretAccessKey: String? { ownerInfo?.secretAccessKey }
}

struct CivoObjectStoreOwner: Codable, Sendable {
    let accessKeyId: String?
    let secretAccessKey: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case name
        case accessKeyId = "access_key_id"
        case secretAccessKey = "secret_access_key"
    }
}
