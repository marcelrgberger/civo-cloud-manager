import Foundation

struct CivoLoadBalancer: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let algorithm: String?
    let publicIp: String?
    let privateIp: String?
    let state: String?
    let clusterId: String?
    let firewallId: String?
    let backends: String?
    let externalTrafficPolicy: String?

    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, algorithm, state
        case backends = "Backends"
        case publicIp = "public_ip"
        case privateIp = "private_ip"
        case clusterId = "cluster_id"
        case firewallId = "firewall_id"
        case externalTrafficPolicy = "external_traffic_policy"
        case createdAt = "created_at"
    }

    // Backends is a comma-separated string
    var backendList: [String] {
        backends?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
}
