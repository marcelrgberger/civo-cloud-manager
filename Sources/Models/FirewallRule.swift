import Foundation

/// Configuration for a known firewall.
struct FirewallConfig: Sendable {
    let name: String        // e.g. "fw-cluster"
    let displayName: String // e.g. "Cluster (K8s API)"
    let port: Int           // e.g. 6443
    let label: String       // e.g. "manual-access-marcelrgberger-cluster"
}

/// Runtime status of a firewall including whether the current IP has access.
struct FirewallStatus: Sendable, Identifiable {
    let id: String          // firewall name, e.g. "fw-cluster"
    let config: FirewallConfig
    let isOpen: Bool        // true if current IP has a manual-access rule
    let ruleId: String?     // rule ID for deletion
    let ruleCidr: String?   // the IP/32 of the active rule
}

/// Represents a single firewall rule from the civo CLI JSON output.
struct CivoFirewallRule: Decodable, Sendable {
    let id: String
    let label: String?
    let cidr: [String]?
    let ports: String?
    let direction: String?
    let action: String?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case cidr
        case ports
        case direction
        case action
    }
}

/// Known firewall configurations.
enum Firewalls {
    static let all: [FirewallConfig] = [
        FirewallConfig(
            name: "fw-cluster",
            displayName: "Cluster (K8s API)",
            port: 6443,
            label: "manual-access-marcelrgberger-cluster"
        ),
        FirewallConfig(
            name: "fw-db-dev",
            displayName: "Database Dev",
            port: 5432,
            label: "manual-access-marcelrgberger-db-dev"
        ),
        FirewallConfig(
            name: "fw-db-prod",
            displayName: "Database Prod",
            port: 5432,
            label: "manual-access-marcelrgberger-db-prod"
        ),
    ]
}
