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

    let createdAt: String?
    let region: String?
    let bootable: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, status, mountpoint, region, bootable
        case sizeGb = "size_gb"
        case instanceId = "instance_id"
        case clusterId = "cluster_id"
        case networkId = "network_id"
        case createdAt = "created_at"
    }

    var sizeDisplay: String {
        if let sizeGb { return "\(sizeGb) GB" }
        return "—"
    }
}
