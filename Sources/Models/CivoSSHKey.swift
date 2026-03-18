import Foundation

struct CivoSSHKey: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let fingerprint: String?

    enum CodingKeys: String, CodingKey {
        case id, name, fingerprint
    }
}
