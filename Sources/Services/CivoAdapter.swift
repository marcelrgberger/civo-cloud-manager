import Foundation

enum CivoAdapterError: LocalizedError {
    case cliNotFound
    case notAuthenticated
    case parseError(String)
    case operationFailed(String)
    case noRegion

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "civo CLI not found. Install with: brew install civo"
        case .notAuthenticated:
            return "civo CLI is not authenticated. Run: civo apikey save YOUR_KEY --name default"
        case .parseError(let detail):
            return "Failed to parse civo output: \(detail)"
        case .operationFailed(let detail):
            return "Operation failed: \(detail)"
        case .noRegion:
            return "No region configured. Run: civo region use REGION"
        }
    }
}

/// The label prefix used to identify rules created by this app.
/// Full label format: civo-cloud-HOSTNAME-FIREWALLNAME
enum CivoAccessLabel {
    static let prefix = "civo-cloud-"

    static var hostname: String {
        Host.current().localizedName?.replacingOccurrences(of: " ", with: "-") ?? "unknown"
    }

    static func make(firewallName: String) -> String {
        "\(prefix)\(hostname)-\(firewallName)"
    }
}

final class CivoAdapter: Sendable {
    private let runner = ProcessRunner()

    // MARK: - Setup checks

    /// Check if civo CLI binary exists.
    func isCLIInstalled() -> Bool {
        let path = runner.findExecutable("civo")
        return FileManager.default.isExecutableFile(atPath: path)
    }

    /// Check if civo CLI is authenticated (`civo apikey show` succeeds).
    func isAuthenticated() async -> Bool {
        do {
            let result = try await runner.run(
                runner.findExecutable("civo"),
                arguments: ["apikey", "show"],
                timeout: 15
            )
            return result.exitCode == 0
        } catch {
            Log.error("civo auth check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Get the current region from `civo region ls --output json`.
    /// Returns the name of the region marked as default/current.
    func getCurrentRegion() async throws -> String {
        let output = try await runner.runCivo(["region", "ls", "--output", "json"])

        guard let data = output.data(using: .utf8) else {
            throw CivoAdapterError.parseError("Invalid UTF-8 output from region ls")
        }

        struct CivoRegion: Decodable {
            let code: String
            let name: String
            let current: Bool?
        }

        do {
            let regions = try JSONDecoder().decode([CivoRegion].self, from: data)
            if let current = regions.first(where: { $0.current == true }) {
                return "\(current.name) (\(current.code))"
            }
            // Fallback: if there's only one region, use that
            if let first = regions.first {
                return "\(first.name) (\(first.code))"
            }
            throw CivoAdapterError.noRegion
        } catch let error as CivoAdapterError {
            throw error
        } catch {
            throw CivoAdapterError.parseError("region parse: \(error.localizedDescription)")
        }
    }

    // MARK: - Firewall discovery

    /// Discover all firewalls from the account: `civo firewall ls --output json`.
    func discoverFirewalls() async throws -> [CivoFirewall] {
        let output = try await runner.runCivo(["firewall", "ls", "--output", "json"])

        guard let data = output.data(using: .utf8) else {
            throw CivoAdapterError.parseError("Invalid UTF-8 output from firewall ls")
        }

        do {
            let firewalls = try JSONDecoder().decode([CivoFirewall].self, from: data)
            return firewalls
        } catch {
            Log.error("JSON parse error for firewall ls: \(error.localizedDescription)")
            Log.debug("Raw output: \(output)")
            throw CivoAdapterError.parseError(error.localizedDescription)
        }
    }

    /// List all rules for a firewall.
    func getRulesForFirewall(_ firewallName: String) async throws -> [CivoRule] {
        let output = try await runner.runCivo([
            "firewall", "rule", "ls", firewallName, "--output", "json",
        ])

        guard let data = output.data(using: .utf8) else {
            throw CivoAdapterError.parseError("Invalid UTF-8 output")
        }

        do {
            let rules = try JSONDecoder().decode([CivoRule].self, from: data)
            return rules
        } catch {
            Log.error("JSON parse error for \(firewallName) rules: \(error.localizedDescription)")
            Log.debug("Raw output: \(output)")
            throw CivoAdapterError.parseError(error.localizedDescription)
        }
    }

    // MARK: - Rule management

    /// Open access for a given firewall, port, and IP.
    func openAccess(firewall: String, port: Int, ip: String, label: String) async throws {
        let cidr = "\(ip)/32"
        Log.info("Opening \(firewall) port \(port) for \(cidr) with label \(label)")

        try await runner.runCivo([
            "firewall", "rule", "create", firewall,
            "-s", String(port),
            "-l", label,
            "-c", cidr,
        ])

        Log.info("Opened \(firewall) port \(port) for \(cidr)")
    }

    /// Close a specific firewall rule by ID.
    func closeAccess(firewall: String, ruleId: String) async throws {
        Log.info("Removing rule \(ruleId) from \(firewall)")

        try await runner.runCivo([
            "firewall", "rule", "remove", firewall, ruleId, "--yes",
        ])

        Log.info("Removed rule \(ruleId) from \(firewall)")
    }

    // MARK: - Status

    /// Get status of all managed firewalls against the current IP.
    func getStatus(managedFirewalls: [ManagedFirewall], currentIP: String) async throws -> [FirewallStatus] {
        var statuses: [FirewallStatus] = []

        for managed in managedFirewalls where managed.enabled {
            let status = try await getFirewallStatus(managed: managed, currentIP: currentIP)
            statuses.append(status)
        }

        return statuses
    }

    private func getFirewallStatus(managed: ManagedFirewall, currentIP: String) async throws -> FirewallStatus {
        let rules = try await getRulesForFirewall(managed.name)
        let cidr = "\(currentIP)/32"
        let hostname = CivoAccessLabel.hostname
        let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

        // Find a rule created by THIS machine that matches the current IP
        let matchingRule = rules.first { rule in
            guard let label = rule.label else { return false }
            let isOurRule = label.hasPrefix(fullLabelPrefix)
            let matchesCidr = rule.cidr?.contains(cidr) ?? false
            return isOurRule && matchesCidr
        }

        return FirewallStatus(
            managed: managed,
            isOpen: matchingRule != nil,
            ruleId: matchingRule?.id,
            ruleCidr: matchingRule?.cidr?.first
        )
    }

    // MARK: - Bulk close

    /// Close ALL rules created by this machine (matching the full label prefix including hostname) across managed firewalls.
    /// Returns number of rules removed and the count of failures.
    func closeAllManagedRules(managedFirewalls: [ManagedFirewall]) async throws -> (removed: Int, failed: Int) {
        var removedCount = 0
        var failedCount = 0
        let hostname = CivoAccessLabel.hostname
        let fullLabelPrefix = "\(CivoAccessLabel.prefix)\(hostname)-"

        for managed in managedFirewalls where managed.enabled {
            let rules = try await getRulesForFirewall(managed.name)
            let ourRules = rules.filter { $0.label?.hasPrefix(fullLabelPrefix) ?? false }

            for rule in ourRules {
                do {
                    try await closeAccess(firewall: managed.name, ruleId: rule.id)
                    removedCount += 1
                } catch {
                    failedCount += 1
                    Log.error("Failed to remove rule \(rule.id) from \(managed.name): \(error.localizedDescription)")
                }
            }
        }

        Log.info("Closed \(removedCount) civo-access rules total, \(failedCount) failed")
        return (removed: removedCount, failed: failedCount)
    }
}
