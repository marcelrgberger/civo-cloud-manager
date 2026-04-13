import Foundation

struct CivoRegion: Codable, Identifiable, Sendable {
    let code: String
    let name: String
    let country: String?
    let countryName: String?
    let isDefault: Bool?

    var id: String { code }
    var isCurrent: Bool { code == CivoConfig.shared.region }
    var countryDisplay: String { countryName ?? country ?? "" }

    enum CodingKeys: String, CodingKey {
        case code, name, country
        case countryName = "country_name"
        case isDefault = "default"
    }
}
