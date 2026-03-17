import Foundation

enum CivoAdapterError: LocalizedError {
    case cliNotFound
    case notAuthenticated
    case parseError(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "civo CLI not found. Install with: brew install civo"
        case .notAuthenticated:
            return "civo CLI is not authenticated. Run: civo apikey save"
        case .parseError(let detail):
            return "Failed to parse civo output: \(detail)"
        case .operationFailed(let detail):
            return "Operation failed: \(detail)"
        }
    }
}

final class CivoAdapter: Sendable {
    private let runner = ProcessRunner()

    /// Check if civo CLI is available and authenticated.
    func isAuthenticated() async -> Bool {
        do {
            let result = try await runner.run(
                runner.findExecutable("civo"),
                arguments: ["region", "ls", "--output", "json"],
                timeout: 15
            )
            return result.exitCode == 0
        } catch {
            Log.error("civo auth check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Get status of all configured firewalls.
    func getStatus(currentIP: String) async throws -> [FirewallStatus] {
        var statuses: [FirewallStatus] = []

        for config in Firewalls.all {
            let status = try await getFirewallStatus(config: config, currentIP: currentIP)
            statuses.append(status)
        }

        return statuses
    }

    /// Get status of a single firewall.
    private func getFirewallStatus(config: FirewallConfig, currentIP: String) async throws -> FirewallStatus {
        let rules = try await listRules(firewallName: config.name)
        let cidr = "\(currentIP)/32"

        // Find a manual-access rule matching the label prefix and current IP
        let matchingRule = rules.first { rule in
            guard let label = rule.label else { return false }
            let isManualAccess = label.hasPrefix("manual-access-")
            let matchesCidr = rule.cidr?.contains(cidr) ?? false
            return isManualAccess && matchesCidr
        }

        // Also check for rules with matching label regardless of IP
        let labelRule = rules.first { rule in
            rule.label == config.label
        }

        let activeRule = matchingRule ?? labelRule

        return FirewallStatus(
            id: config.name,
            config: config,
            isOpen: activeRule != nil,
            ruleId: activeRule?.id,
            ruleCidr: activeRule?.cidr?.first
        )
    }

    /// List all rules for a firewall.
    private func listRules(firewallName: String) async throws -> [CivoFirewallRule] {
        let output = try await runner.runCivo([
            "firewall", "rule", "ls", firewallName, "--output", "json"
        ])

        guard let data = output.data(using: .utf8) else {
            throw CivoAdapterError.parseError("Invalid UTF-8 output")
        }

        do {
            let rules = try JSONDecoder().decode([CivoFirewallRule].self, from: data)
            return rules
        } catch {
            Log.error("JSON parse error for \(firewallName): \(error.localizedDescription)")
            Log.debug("Raw output: \(output)")
            throw CivoAdapterError.parseError(error.localizedDescription)
        }
    }

    /// Open firewall access for the given IP.
    func openAccess(firewall: FirewallConfig, ip: String) async throws {
        let cidr = "\(ip)/32"
        Log.info("Opening \(firewall.name) for \(cidr) with label \(firewall.label)")

        try await runner.runCivo([
            "firewall", "rule", "create", firewall.name,
            "-s", String(firewall.port),
            "-l", firewall.label,
            "-c", cidr,
        ])

        Log.info("Opened \(firewall.name) for \(cidr)")
    }

    /// Close a specific firewall rule.
    func closeAccess(firewallName: String, ruleId: String) async throws {
        Log.info("Removing rule \(ruleId) from \(firewallName)")

        try await runner.runCivo([
            "firewall", "rule", "remove", firewallName, ruleId, "--yes"
        ])

        Log.info("Removed rule \(ruleId) from \(firewallName)")
    }

    /// Close ALL manual-access rules across all firewalls. Returns number of rules removed.
    func closeAllAccess() async throws -> Int {
        var removedCount = 0

        for config in Firewalls.all {
            let rules = try await listRules(firewallName: config.name)
            let manualRules = rules.filter { $0.label?.hasPrefix("manual-access-") ?? false }

            for rule in manualRules {
                do {
                    try await closeAccess(firewallName: config.name, ruleId: rule.id)
                    removedCount += 1
                } catch {
                    Log.error("Failed to remove rule \(rule.id) from \(config.name): \(error.localizedDescription)")
                }
            }
        }

        Log.info("Closed \(removedCount) manual-access rules total")
        return removedCount
    }
}
