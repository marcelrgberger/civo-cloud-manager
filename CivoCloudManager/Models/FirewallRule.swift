import Foundation

// MARK: - Firewall

/// Represents a firewall from the Civo API.
struct CivoFirewall: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let rulesCount: String
    let networkId: String?
    /// Whether this is the default firewall of its network.
    let isDefault: Bool
    /// Region this firewall belongs to (set after decoding, not from API JSON).
    var region: String = ""

    var rulesCountInt: Int { Int(rulesCount) ?? 0 }
}

extension CivoFirewall {
    enum CodingKeys: String, CodingKey {
        case id, name
        case rulesCount = "rules_count"
        case networkId = "network_id"
        case isDefault = "default"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        networkId = try c.decodeIfPresent(String.self, forKey: .networkId)
        // https://www.civo.com/api/firewall sends default as the string "true" or "false"
        if let flag = try? c.decode(Bool.self, forKey: .isDefault) {
            isDefault = flag
        } else {
            isDefault = (try? c.decode(String.self, forKey: .isDefault))?.lowercased() == "true"
        }
        // rules_count can be String or Int depending on the API version
        if let s = try? c.decode(String.self, forKey: .rulesCount) {
            rulesCount = s
        } else if let i = try? c.decode(Int.self, forKey: .rulesCount) {
            rulesCount = String(i)
        } else {
            rulesCount = "0"
        }
    }
}

// MARK: - Firewall of an instance

/// The firewalls and networks of the region an instance was listed from.
/// Civo only accepts a firewall that exists in the instance's network.
struct InstanceFirewallOptions: Sendable {
    let region: String
    let firewalls: [CivoFirewall]
    let networks: [CivoNetwork]

    /// The instance's network, or the region's default network when Civo reports none.
    func networkId(of instance: CivoInstance) -> String? {
        if let id = instance.networkId, !id.isEmpty { return id }
        return networks.first { $0.isDefault == true }?.id
    }

    /// The firewalls the instance may be switched to, the network's default firewall first.
    func offered(for instance: CivoInstance) -> [CivoFirewall] {
        guard let networkId = networkId(of: instance) else { return [] }
        return InstanceCreationForm.firewalls(firewalls, in: networkId)
            .sorted { $0.isDefault && !$1.isDefault }
    }

    func firewall(withId id: String?) -> CivoFirewall? {
        firewalls.first { $0.id == id }
    }
}

// MARK: - Rule

/// Represents a single firewall rule.
struct CivoRule: Codable, Identifiable, Sendable {
    let id: String
    let label: String?
    let cidr: String?
    let ports: String?
    let startPort: String?
    let endPort: String?
    let direction: String?
    let action: String?
}

extension CivoRule {
    enum CodingKeys: String, CodingKey {
        case id, label, cidr, ports, direction, action
        case startPort = "start_port"
        case endPort = "end_port"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        ports = try c.decodeIfPresent(String.self, forKey: .ports)
        startPort = try c.decodeIfPresent(String.self, forKey: .startPort)
        endPort = try c.decodeIfPresent(String.self, forKey: .endPort)
        direction = try c.decodeIfPresent(String.self, forKey: .direction)
        action = try c.decodeIfPresent(String.self, forKey: .action)

        // cidr can be a String or an Array of Strings
        if let s = try? c.decode(String.self, forKey: .cidr) {
            cidr = s
        } else if let arr = try? c.decode([String].self, forKey: .cidr), let first = arr.first {
            cidr = first
        } else {
            cidr = nil
        }
    }
}

// MARK: - User's managed config (persisted in UserDefaults)

struct ManagedFirewall: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    var port: Int
    var enabled: Bool
    var region: String

    init(id: String, name: String, port: Int, enabled: Bool, region: String) {
        self.id = id
        self.name = name
        self.port = port
        self.enabled = enabled
        self.region = region
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        port = try c.decode(Int.self, forKey: .port)
        enabled = try c.decode(Bool.self, forKey: .enabled)
        // Backward compatibility: existing data may not have region — empty triggers migration
        region = try c.decodeIfPresent(String.self, forKey: .region) ?? ""
    }
}

// MARK: - Runtime status

struct FirewallStatus: Identifiable, Sendable {
    let managed: ManagedFirewall
    let isOpen: Bool
    let ruleId: String?
    let ruleCidr: String?

    var id: String { managed.id }
}
