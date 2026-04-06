import Foundation

final class CivoFirewallService: Sendable {
    private let api = CivoAPIClient.shared

    func listFirewalls() async throws -> [CivoFirewall] {
        try await api.getArray(path: "/firewalls")
    }

    func createFirewall(_ body: [String: Any]) async throws -> CivoFirewall {
        try await api.post(path: "/firewalls", body: body)
    }

    func removeFirewall(_ id: String) async throws {
        try await api.delete(path: "/firewalls/\(id)")
    }

    func getRulesForFirewall(_ firewallId: String, region: String? = nil) async throws -> [CivoRule] {
        if let region {
            let saved = CivoConfig.shared.region
            CivoConfig.shared.region = region
            defer { CivoConfig.shared.region = saved }
            return try await api.getArray(path: "/firewalls/\(firewallId)/rules")
        }
        return try await api.getArray(path: "/firewalls/\(firewallId)/rules")
    }

    func createRule(
        firewallId: String,
        protocol proto: String = "tcp",
        startPort: String,
        endPort: String? = nil,
        cidr: String,
        direction: String = "ingress",
        label: String? = nil,
        action: String = "allow",
        region: String? = nil
    ) async throws {
        let effectiveRegion = region ?? CivoConfig.shared.region
        var body: [String: Any] = [
            "protocol": proto,
            "start_port": startPort,
            "cidr": [cidr],
            "direction": direction,
            "action": action,
            "region": effectiveRegion,
        ]
        if let endPort { body["end_port"] = endPort }
        if let label { body["label"] = label }

        if let region {
            let saved = CivoConfig.shared.region
            CivoConfig.shared.region = region
            defer { CivoConfig.shared.region = saved }
            let _: CivoRule = try await api.post(
                path: "/firewalls/\(firewallId)/rules",
                body: body
            )
        } else {
            let _: CivoRule = try await api.post(
                path: "/firewalls/\(firewallId)/rules",
                body: body
            )
        }
    }

    func createRuleFromBody(firewallId: String, body: [String: Any]) async throws {
        let _: CivoRule = try await api.post(
            path: "/firewalls/\(firewallId)/rules",
            body: body
        )
    }

    func deleteRule(firewallId: String, ruleId: String, region: String? = nil) async throws {
        if let region {
            let saved = CivoConfig.shared.region
            CivoConfig.shared.region = region
            defer { CivoConfig.shared.region = saved }
            try await api.delete(path: "/firewalls/\(firewallId)/rules/\(ruleId)")
        } else {
            try await api.delete(path: "/firewalls/\(firewallId)/rules/\(ruleId)")
        }
    }

    // MARK: - Firewall status

    func getStatus(managedFirewalls: [ManagedFirewall], currentIP: String) async -> [FirewallStatus] {
        var statuses: [FirewallStatus] = []

        for managed in managedFirewalls where managed.enabled {
            do {
                let rules = try await getRulesForFirewall(managed.id, region: managed.region)
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
            } catch {
                Log.error("Status check failed for firewall \(managed.name) (\(managed.region)): \(error.localizedDescription)")
                // Still show the firewall but as closed/unknown
                statuses.append(FirewallStatus(
                    managed: managed,
                    isOpen: false,
                    ruleId: nil,
                    ruleCidr: nil
                ))
            }
        }

        return statuses
    }

    func openAccess(firewallId: String, port: Int, ip: String, label: String, region: String? = nil) async throws {
        try await createRule(
            firewallId: firewallId,
            startPort: String(port),
            cidr: "\(ip)/32",
            label: label,
            region: region
        )
    }

    func closeAccess(firewallId: String, ruleId: String, region: String? = nil) async throws {
        try await deleteRule(firewallId: firewallId, ruleId: ruleId, region: region)
    }

    func closeAllManagedRules(managedFirewalls: [ManagedFirewall]) async throws -> (removed: Int, failed: Int) {
        var removedCount = 0
        var failedCount = 0
        let hostname = CivoAccessLabel.hostname
        let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

        for managed in managedFirewalls where managed.enabled {
            let rules = try await getRulesForFirewall(managed.id, region: managed.region)
            let ourRules = rules.filter { $0.label?.hasPrefix(fullLabelPrefix) ?? false }

            for rule in ourRules {
                do {
                    try await closeAccess(firewallId: managed.id, ruleId: rule.id, region: managed.region)
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
