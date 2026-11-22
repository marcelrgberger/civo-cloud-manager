import Foundation

/// The rule requests of the rule editor, each pinned to the account and region the edit was started in.
protocol FirewallRuleAPI: Sendable {
    func getRulesForFirewall(_ firewallId: String, region: String?, apiKey: String?) async throws -> [CivoRule]
    func updateRule(_ ruleId: String, of firewallId: String, body: sending [String: Any], region: String, apiKey: String) async throws
}

final class CivoFirewallService: FirewallRuleAPI, Sendable {
    private let api = CivoAPIClient.shared

    /// `apiKey` pins the request to one account instead of reading the current key.
    func listFirewalls(region: String? = nil, apiKey: String? = nil) async throws -> [CivoFirewall] {
        var queryItems: [URLQueryItem]? = nil
        if let region {
            queryItems = [URLQueryItem(name: "region", value: region)]
        }
        return try await api.getArray(path: "/firewalls", queryItems: queryItems, apiKey: apiKey)
    }

    func createFirewall(_ body: [String: Any]) async throws -> CivoFirewall {
        try await api.post(path: "/firewalls", body: body)
    }

    func removeFirewall(_ id: String) async throws {
        try await api.delete(path: "/firewalls/\(id)")
    }

    /// `apiKey` pins the request to one account instead of reading the current key.
    func getRulesForFirewall(_ firewallId: String, region: String? = nil, apiKey: String? = nil) async throws -> [CivoRule] {
        var queryItems: [URLQueryItem]? = nil
        if let region {
            queryItems = [URLQueryItem(name: "region", value: region)]
        }
        return try await api.getArray(path: "/firewalls/\(firewallId)/rules", queryItems: queryItems, apiKey: apiKey)
    }

    /// `PUT /v2/firewalls/:firewall_id/rules/:rule_id`; https://www.civo.com/api/vpc documents the path
    /// under its `/v2/vpc/firewalls` alias and answers with `{"id": ..., "result": "success"}`.
    func updateRule(_ ruleId: String, of firewallId: String, body: sending [String: Any], region: String, apiKey: String) async throws {
        let _: CivoResult = try await api.put(
            path: "/firewalls/\(firewallId)/rules/\(ruleId)",
            body: body,
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey
        )
    }

    @discardableResult
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
    ) async throws -> CivoRule {
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

        var queryItems: [URLQueryItem]? = nil
        if let region {
            queryItems = [URLQueryItem(name: "region", value: region)]
        }
        return try await api.post(
            path: "/firewalls/\(firewallId)/rules",
            body: body,
            queryItems: queryItems
        )
    }

    func createRuleFromBody(firewallId: String, body: [String: Any]) async throws {
        let _: CivoRule = try await api.post(
            path: "/firewalls/\(firewallId)/rules",
            body: body
        )
    }

    func deleteRule(firewallId: String, ruleId: String, region: String? = nil) async throws {
        var queryItems: [URLQueryItem]? = nil
        if let region {
            queryItems = [URLQueryItem(name: "region", value: region)]
        }
        try await api.delete(path: "/firewalls/\(firewallId)/rules/\(ruleId)", queryItems: queryItems)
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

    @discardableResult
    func openAccess(firewallId: String, port: Int, ip: String, label: String, region: String? = nil) async throws -> CivoRule {
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

    func closeAllManagedRules(managedFirewalls: [ManagedFirewall]) async throws -> (removed: Int, failed: Int, listErrors: [String]) {
        var removedCount = 0
        var failedCount = 0
        var listErrors: [String] = []
        let hostname = CivoAccessLabel.hostname
        let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

        for managed in managedFirewalls where managed.enabled {
            let rules: [CivoRule]
            do {
                rules = try await getRulesForFirewall(managed.id, region: managed.region)
            } catch {
                listErrors.append("\(managed.name): \(error.localizedDescription)")
                Log.error("Unable to list managed rules for \(managed.id): \(error)")
                continue
            }
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

        return (removed: removedCount, failed: failedCount, listErrors: listErrors)
    }
}
