import Foundation

struct CivoSSHKey: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let fingerprint: String?
    let publicKey: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, fingerprint
        case publicKey = "public_key"
        case createdAt = "created_at"
    }
}
