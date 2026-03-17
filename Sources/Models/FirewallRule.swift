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
struct CivoRule: Codable, Sendable {
    let id: String
    let label: String?
    let cidr: [String]?
    let ports: String?
    let startPort: String?
    let endPort: String?
    let direction: String?
    let action: String?

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
