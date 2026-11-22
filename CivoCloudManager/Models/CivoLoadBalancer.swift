import Foundation

/// A load balancer as `GET /v2/loadbalancers` reports it (https://www.civo.com/api/vpc). Civo answers with
/// `backends` as objects; older answers listed only the backend IPs as a comma separated `Backends` string.
struct CivoLoadBalancer: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let algorithm: String?
    let publicIp: String?
    let privateIp: String?
    let state: String?
    let clusterId: String?
    let firewallId: String?
    let networkId: String?
    let serviceName: String?
    let externalTrafficPolicy: String?
    let createdAt: String?
    /// The backends as objects, nil when Civo sent none in that form.
    let backendEntries: [LoadBalancerBackend]?
    /// The comma separated `Backends` string of older answers.
    let legacyBackends: String?
    /// Whether the answer carried `cluster_id` at all, even empty. Ownership is only decided on a reported value.
    let reportsClusterId: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, algorithm, state, backends
        case legacyBackends = "Backends"
        case publicIp = "public_ip"
        case privateIp = "private_ip"
        case clusterId = "cluster_id"
        case firewallId = "firewall_id"
        case networkId = "network_id"
        case serviceName = "service_name"
        case externalTrafficPolicy = "external_traffic_policy"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        algorithm = try container.decodeIfPresent(String.self, forKey: .algorithm)
        publicIp = try container.decodeIfPresent(String.self, forKey: .publicIp)
        privateIp = try container.decodeIfPresent(String.self, forKey: .privateIp)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        clusterId = try container.decodeIfPresent(String.self, forKey: .clusterId)
        firewallId = try container.decodeIfPresent(String.self, forKey: .firewallId)
        networkId = try container.decodeIfPresent(String.self, forKey: .networkId)
        serviceName = try container.decodeIfPresent(String.self, forKey: .serviceName)
        externalTrafficPolicy = try container.decodeIfPresent(String.self, forKey: .externalTrafficPolicy)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        reportsClusterId = container.contains(.clusterId)
        // `backends` is documented as objects; a string under that key is read like the old `Backends`.
        if let entries = try? container.decodeIfPresent([LoadBalancerBackend].self, forKey: .backends) {
            backendEntries = entries
            legacyBackends = try container.decodeIfPresent(String.self, forKey: .legacyBackends)
        } else {
            backendEntries = nil
            legacyBackends = try container.decodeIfPresent(String.self, forKey: .legacyBackends)
                ?? (try? container.decodeIfPresent(String.self, forKey: .backends))
        }
    }

    /// Keeps every decoded value, so the JSON export carries the same data.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(algorithm, forKey: .algorithm)
        try container.encodeIfPresent(publicIp, forKey: .publicIp)
        try container.encodeIfPresent(privateIp, forKey: .privateIp)
        try container.encodeIfPresent(state, forKey: .state)
        if reportsClusterId { try container.encode(clusterId ?? "", forKey: .clusterId) }
        try container.encodeIfPresent(firewallId, forKey: .firewallId)
        try container.encodeIfPresent(networkId, forKey: .networkId)
        try container.encodeIfPresent(serviceName, forKey: .serviceName)
        try container.encodeIfPresent(externalTrafficPolicy, forKey: .externalTrafficPolicy)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(backendEntries, forKey: .backends)
        try container.encodeIfPresent(legacyBackends, forKey: .legacyBackends)
    }

    /// The backend IPs, from whichever form Civo sent.
    var backendList: [String] {
        if let backendEntries { return backendEntries.map(\.ip) }
        return legacyBackends?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
}

/// One backend as Civo documents it: `{ip, protocol, source_port, target_port}`. Civo's Go client also
/// knows `health_check_port`; it is kept so an update never drops it from an existing backend.
struct LoadBalancerBackend: Codable, Hashable, Sendable {
    let ip: String
    let `protocol`: String?
    let sourcePort: Int?
    let targetPort: Int?
    let healthCheckPort: Int?

    enum CodingKeys: String, CodingKey {
        case ip, `protocol`
        case sourcePort = "source_port"
        case targetPort = "target_port"
        case healthCheckPort = "health_check_port"
    }

    init(ip: String, protocol: String?, sourcePort: Int?, targetPort: Int?, healthCheckPort: Int? = nil) {
        self.ip = ip
        self.protocol = `protocol`
        self.sourcePort = sourcePort
        self.targetPort = targetPort
        self.healthCheckPort = healthCheckPort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ip = try container.decode(String.self, forKey: .ip)
        `protocol` = try container.decodeIfPresent(String.self, forKey: .protocol)
        sourcePort = Self.port(in: container, forKey: .sourcePort)
        targetPort = Self.port(in: container, forKey: .targetPort)
        healthCheckPort = Self.port(in: container, forKey: .healthCheckPort)
    }

    /// Ports are documented as numbers; a numeric string is read too, anything else stays unknown.
    private static func port(in container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let number = try? container.decodeIfPresent(Int.self, forKey: key) { return number }
        return (try? container.decodeIfPresent(String.self, forKey: key)).flatMap { $0.flatMap(Int.init) }
    }

    /// The entry as an update sends it again, with every field Civo reported.
    var requestValue: [String: Any] {
        var value: [String: Any] = ["ip": ip]
        if let `protocol` { value["protocol"] = `protocol` }
        if let sourcePort { value["source_port"] = sourcePort }
        if let targetPort { value["target_port"] = targetPort }
        if let healthCheckPort { value["health_check_port"] = healthCheckPort }
        return value
    }
}
