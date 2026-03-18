import Foundation

struct CivoRegion: Codable, Identifiable, Sendable {
    let code: String
    let name: String
    let country: String?
    let current: String?

    var id: String { code }
    var isCurrent: Bool { current?.lowercased() == "yes" }
}
