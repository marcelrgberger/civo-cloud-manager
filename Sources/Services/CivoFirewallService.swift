import Foundation

final class CivoFirewallService: Sendable {
    private let api = CivoAPIClient.shared

    func listFirewalls() async throws -> [CivoFirewall] {
        try await api.getArray(path: "/firewalls")
    }

    func createFirewall(_ body: [String: Any]) async throws -> CivoFirewall {
        try await api.post(path: "/firewalls", body: body)
    }

    func getRulesForFirewall(_ firewallId: String) async throws -> [CivoRule] {
        try await api.getArray(path: "/firewalls/\(firewallId)/rules")
    }

    func createRule(
        firewallId: String,
        protocol proto: String = "tcp",
        startPort: String,
        endPort: String? = nil,
        cidr: String,
        direction: String = "ingress",
        label: String? = nil,
        action: String = "allow"
    ) async throws {
        var body: [String: Any] = [
            "protocol": proto,
            "start_port": startPort,
            "cidr": [cidr],
            "direction": direction,
            "action": action,
            "region": CivoConfig.shared.region,
        ]
        if let endPort { body["end_port"] = endPort }
        if let label { body["label"] = label }

        let _: CivoRule = try await api.post(
            path: "/firewalls/\(firewallId)/rules",
            body: body
        )
    }

    func deleteRule(firewallId: String, ruleId: String) async throws {
        try await api.delete(path: "/firewalls/\(firewallId)/rules/\(ruleId)")
    }

    // MARK: - Firewall status

    func getStatus(managedFirewalls: [ManagedFirewall], currentIP: String) async throws -> [FirewallStatus] {
        var statuses: [FirewallStatus] = []

        for managed in managedFirewalls where managed.enabled {
            let rules = try await getRulesForFirewall(managed.id)
            let cidr = "\(currentIP)/32"
            let hostname = CivoAccessLabel.hostname
            let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

            let portStr = String(managed.port)
            let matchingRule = rules.first { rule in
                guard let label = rule.label else { return false }
                let matchesLabel = label.hasPrefix(fullLabelPrefix)
                let matchesCidr = rule.cidr == cidr
                let matchesPort = rule.startPort == portStr || rule.ports == portStr
                return matchesLabel && matchesCidr && matchesPort
            }

            statuses.append(FirewallStatus(
                managed: managed,
                isOpen: matchingRule != nil,
                ruleId: matchingRule?.id,
                ruleCidr: matchingRule?.cidr
            ))
        }

        return statuses
    }

    func openAccess(firewallId: String, port: Int, ip: String, label: String) async throws {
        try await createRule(
            firewallId: firewallId,
            startPort: String(port),
            cidr: "\(ip)/32",
            label: label
        )
    }

    func closeAccess(firewallId: String, ruleId: String) async throws {
        try await deleteRule(firewallId: firewallId, ruleId: ruleId)
    }

    func closeAllManagedRules(managedFirewalls: [ManagedFirewall]) async throws -> (removed: Int, failed: Int) {
        var removedCount = 0
        var failedCount = 0
        let hostname = CivoAccessLabel.hostname
        let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

        for managed in managedFirewalls where managed.enabled {
            let rules = try await getRulesForFirewall(managed.id)
            let ourRules = rules.filter { $0.label?.hasPrefix(fullLabelPrefix) ?? false }

            for rule in ourRules {
                do {
                    try await closeAccess(firewallId: managed.id, ruleId: rule.id)
                    removedCount += 1
                } catch {
                    failedCount += 1
                    Log.error("Failed to remove rule \(rule.id): \(error.localizedDescription)")
                }
            }
        }

        return (removed: removedCount, failed: failedCount)
    }
}
