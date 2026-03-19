import Foundation

struct CivoVolume: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String?
    let sizeGb: Int?
    let mountpoint: String?
    let instanceId: String?
    let clusterId: String?
    let networkId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, mountpoint
        case sizeGb = "size_gb"
        case instanceId = "instance_id"
        case clusterId = "cluster_id"
        case networkId = "network_id"
    }

    var sizeDisplay: String {
        if let sizeGb { return "\(sizeGb) GB" }
        return "—"
    }
}
