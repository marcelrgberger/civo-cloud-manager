import Foundation

struct CivoObjectStoreCredential: Codable, Identifiable, Sendable {
    let id: String
    let name: String?
    let accessKeyId: String?
    let secretAccessKeyId: String?
    let status: String?
    let suspended: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, status, suspended
        case accessKeyId = "access_key_id"
        case secretAccessKeyId = "secret_access_key_id"
    }

    var displayName: String { name ?? id }
}
