import Foundation

struct CivoDatabase: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String
    let software: String?
    let softwareVersion: String?
    let size: String?
    let nodes: String?
    let port: String?
    let host: String?
    let privateIpv4: String?
    let firewallId: String?
    let networkId: String?
    let dnsEntry: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, software, size, nodes, port, host
        case softwareVersion = "software_version"
        case privateIpv4 = "private_ipv4"
        case firewallId = "firewall_id"
        case networkId = "network_id"
        case dnsEntry = "dns_entry"
    }

    var nodesInt: Int { Int(nodes ?? "1") ?? 1 }
    var portInt: Int { Int(port ?? "5432") ?? 5432 }
}
