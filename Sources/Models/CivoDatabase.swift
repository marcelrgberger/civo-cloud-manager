import Foundation

struct CivoDatabase: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String
    let software: String?
    let softwareVersion: String?
    let size: String?
    let nodes: Int?
    let port: Int?
    let publicIpv4: String?
    let privateIpv4: String?
    let firewallId: String?
    let networkId: String?
    let dnsEntry: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, software, size, nodes, port
        case softwareVersion = "software_version"
        case publicIpv4 = "public_ipv4"
        case privateIpv4 = "private_ipv4"
        case firewallId = "firewall_id"
        case networkId = "network_id"
        case dnsEntry = "dns_entry"
    }
}
