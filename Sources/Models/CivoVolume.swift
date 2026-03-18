import Foundation

struct CivoVolume: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String?
    let sizeGigabytes: String?
    let mountPoint: String?
    let instanceId: String?
    let clusterId: String?
    let networkId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case sizeGigabytes = "size_gigabytes"
        case mountPoint = "mount_point"
        case instanceId = "instance_id"
        case clusterId = "cluster_id"
        case networkId = "network_id"
    }
}
