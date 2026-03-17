import Foundation

// MARK: - Discovered from civo CLI

/// Represents a firewall as returned by `civo firewall ls --output json`.
struct CivoFirewall: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let rulesCount: String  // civo returns this as a string, e.g. "6"

    var rulesCountInt: Int { Int(rulesCount) ?? 0 }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rulesCount = "rules_count"
    }
}

/// Represents a single firewall rule from `civo firewall rule ls --output json`.
/// Note: civo CLI returns `cidr` as either a String or an Array depending on context.
struct CivoRule: Sendable {
    let id: String
    let label: String?
    let cidr: String?       // normalized to single string
    let ports: String?
    let startPort: String?
    let endPort: String?
    let direction: String?
    let action: String?
}

extension CivoRule: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case label
        case cidr
        case ports
        case startPort = "start_port"
        case endPort = "end_port"
        case direction
        case action
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

/// A firewall the user has chosen to manage, with configurable port.
struct ManagedFirewall: Codable, Identifiable, Sendable, Hashable {
    let id: String          // civo firewall ID
    let name: String        // display name (= civo firewall name)
    var port: Int           // port to open (user configurable)
    var enabled: Bool       // whether to manage this firewall
}

// MARK: - Runtime status

/// Combines the user's managed config with live rule state.
struct FirewallStatus: Identifiable, Sendable {
    let managed: ManagedFirewall
    let isOpen: Bool
    let ruleId: String?
    let ruleCidr: String?

    var id: String { managed.id }
}
