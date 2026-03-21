import Foundation

struct CivoInstance: Codable, Identifiable, Sendable {
    let id: String
    let hostname: String?
    let size: String?
    let status: String?
    let publicIp: String?
    let cpuCores: Int?
    let ramMb: Int?
    let diskGb: Int?
    let firewallId: String?
    let networkId: String?
    let region: String?
    let createdAt: String?
    let tags: [String]?

    let initialPassword: String?
    let privateIp: String?

    var name: String { hostname ?? id }

    enum CodingKeys: String, CodingKey {
        case id, hostname, size, status, tags, region
        case publicIp = "public_ip"
        case privateIp = "private_ip"
        case cpuCores = "cpu_cores"
        case ramMb = "ram_mb"
        case diskGb = "disk_gb"
        case firewallId = "firewall_id"
        case networkId = "network_id"
        case createdAt = "created_at"
        case initialPassword = "initial_password"
    }
}
