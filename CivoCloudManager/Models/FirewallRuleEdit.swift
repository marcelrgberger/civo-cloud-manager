import Foundation

// MARK: - Draft

/// The rule fields Civo lets a client change (https://www.civo.com/api/vpc, "Update a firewall rule").
/// `action` is not among them, so an edit always keeps the rule's action.
struct FirewallRuleDraft: Equatable, Sendable {
    static let protocols = ["tcp", "udp", "icmp"]
    static let directions = ["ingress", "egress"]
    private static let validPorts = 1...65535

    var proto: String
    var startPort: String
    var endPort: String
    var cidr: String
    var direction: String
    var label: String

    init(proto: String, startPort: String, endPort: String = "", cidr: String, direction: String, label: String = "") {
        self.proto = proto
        self.startPort = startPort
        self.endPort = endPort
        self.cidr = cidr
        self.direction = direction
        self.label = label
    }

    /// The rule as Civo reports it. A single port leaves the end port empty.
    init(rule: CivoRule) {
        let (start, end) = Self.portRange(of: rule)
        self.init(
            proto: rule.proto ?? "",
            startPort: start,
            endPort: end == start ? "" : end,
            cidr: rule.cidr ?? "",
            direction: rule.direction ?? "",
            label: rule.label ?? ""
        )
    }

    /// Civo sends `start_port`/`end_port`; a rule with only `ports` such as "443" or "8000-8100" is read from that.
    private static func portRange(of rule: CivoRule) -> (start: String, end: String) {
        if let start = rule.startPort, !start.isEmpty { return (start, rule.endPort ?? "") }
        let parts = (rule.ports ?? "").split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        guard (1...2).contains(parts.count), parts.allSatisfy({ Int($0) != nil }) else { return ("", "") }
        return (parts[0], parts[parts.count - 1])
    }

    /// Every field without surrounding whitespace, as it is compared and sent.
    var normalized: FirewallRuleDraft {
        FirewallRuleDraft(
            proto: proto.trimmed,
            startPort: startPort.trimmed,
            endPort: endPort.trimmed,
            cidr: cidr.trimmed,
            direction: direction.trimmed,
            label: label.trimmed
        )
    }

    /// The port range of a normalized draft as shown in the comparison: "443", "8000-8100" or empty for none.
    private var portsDisplay: String {
        guard !endPort.isEmpty, endPort != startPort else { return startPort }
        return "\(startPort)-\(endPort)"
    }

    // MARK: Validation

    /// Why the draft cannot be sent, nil when it can. Civo checks the rule again on its side.
    var problem: FirewallRuleDraftProblem? {
        let value = normalized
        guard Self.protocols.contains(value.proto) else { return .unknownProtocol }
        guard Self.directions.contains(value.direction) else { return .unknownDirection }
        if value.startPort.isEmpty {
            // ICMP has no ports; TCP and UDP need at least one.
            if value.proto != "icmp" { return .missingStartPort }
            if !value.endPort.isEmpty { return .invalidPortRange }
        } else {
            guard let start = Int(value.startPort), Self.validPorts.contains(start) else { return .invalidPort }
            if !value.endPort.isEmpty {
                guard let end = Int(value.endPort), Self.validPorts.contains(end) else { return .invalidPort }
                guard end >= start else { return .invalidPortRange }
            }
        }
        guard CIDRBlock(value.cidr) != nil else { return .invalidCIDR }
        // The menu bar's bulk closure deletes every rule with this prefix.
        guard !CivoAccessLabel.isAppManaged(value.label) else { return .reservedLabel }
        return nil
    }

    // MARK: Request

    /// The body of `PUT /v2/firewalls/:firewall_id/rules/:rule_id`. Every editable field is sent, so a
    /// cleared label or end port replaces the old value instead of leaving it. Without an end port the
    /// range ends at the start port, as Civo reports single ports.
    func requestBody(region: String) -> [String: Any] {
        let value = normalized
        var body: [String: Any] = [
            "protocol": value.proto,
            "cidr": [value.cidr],
            "direction": value.direction,
            "label": value.label,
            "region": region,
        ]
        if !value.startPort.isEmpty {
            body["start_port"] = value.startPort
            body["end_port"] = value.endPort.isEmpty ? value.startPort : value.endPort
        }
        return body
    }

    // MARK: Comparison

    /// The fields that differ from `rule`, in the order the editor shows them.
    func changes(from rule: CivoRule) -> [FirewallRuleChange] {
        let before = FirewallRuleDraft(rule: rule).normalized
        let after = normalized
        let fields: [(FirewallRuleChange.Field, String, String)] = [
            (.protocol, before.proto, after.proto),
            (.ports, before.portsDisplay, after.portsDisplay),
            (.cidr, before.cidr, after.cidr),
            (.direction, before.direction, after.direction),
            (.label, before.label, after.label),
        ]
        return fields.compactMap { field, old, new in
            old == new ? nil : FirewallRuleChange(field: field, before: old, after: new)
        }
    }

    /// Warnings for this edit of `rule`. `currentIP` is this Mac's public IP, nil when it could not be detected.
    /// A label change alone changes no access, so it is not warned about. The action stays as it is: an allow
    /// rule is checked for what it admits before and after, a deny rule for what it would block after the change.
    func warnings(editing rule: CivoRule, currentIP: String?) -> [FirewallRuleWarning] {
        guard changes(from: rule).contains(where: { $0.field != .label }) else { return [] }
        let after = normalized
        let before = FirewallRuleDraft(rule: rule).normalized

        let denies = rule.action?.lowercased() == "deny"
        let checked = denies ? after : before
        var warnings: [FirewallRuleWarning] = []
        if !denies, after.direction == "ingress", CIDRBlock(after.cidr)?.isGlobal == true {
            warnings.append(.globalAccess)
        }
        if checked.direction == "ingress", let block = CIDRBlock(checked.cidr) {
            if let currentIP {
                if block.contains(currentIP) { warnings.append(denies ? .blocksOwnAccess : .ownAccess) }
            } else {
                warnings.append(.ownAccessUnknown)
            }
        }
        return warnings
    }
}

enum FirewallRuleDraftProblem: Error, Equatable {
    case unknownProtocol, unknownDirection, missingStartPort, invalidPort, invalidPortRange, invalidCIDR, reservedLabel

    var message: String {
        switch self {
        case .unknownProtocol:
            String(localized: "Choose TCP, UDP or ICMP as the protocol.")
        case .unknownDirection:
            String(localized: "Choose ingress or egress as the direction.")
        case .missingStartPort:
            String(localized: "TCP and UDP rules need a start port.")
        case .invalidPort:
            String(localized: "Ports must be whole numbers from 1 to 65535.")
        case .invalidPortRange:
            String(localized: "The end port needs a start port and must not be lower than it.")
        case .invalidCIDR:
            String(localized: "Enter the CIDR as an address with prefix length, such as 203.0.113.10/32.")
        case .reservedLabel:
            String(localized: "Labels starting with civo-cloud- are reserved for rules the app opens and closes itself.")
        }
    }
}

struct FirewallRuleChange: Equatable, Sendable {
    enum Field: Equatable, Sendable {
        case `protocol`, ports, cidr, direction, label
    }

    let field: Field
    let before: String
    let after: String
}

enum FirewallRuleWarning: Equatable, Sendable {
    /// The rule would admit traffic from every address.
    case globalAccess
    /// The rule admits this Mac's public IP today; the change may end that access.
    case ownAccess
    /// A deny rule would cover this Mac's public IP after the change.
    case blocksOwnAccess
    /// The public IP could not be detected, so a lockout cannot be ruled out.
    case ownAccessUnknown

    var message: String {
        switch self {
        case .globalAccess:
            String(localized: "After this change the rule admits traffic from every address on the internet.")
        case .ownAccess:
            String(localized: "This rule currently admits your own public IP address. After the change you may lose access, for example over SSH.")
        case .blocksOwnAccess:
            String(localized: "After this change the rule may block your own public IP address, for example over SSH.")
        case .ownAccessUnknown:
            String(localized: "Your public IP address could not be detected, so it is unknown whether this change ends your own access.")
        }
    }
}

// MARK: - Editability

/// Whether the editor may change a rule. Rules the app opens and closes itself keep their label and
/// deadline, so the menu bar, timers and the Kubernetes connection still find and close them.
enum FirewallRuleEditability: Equatable, Sendable {
    case editable
    /// Labeled `civo-cloud-...`: opened by the menu bar, an IP preset or the Kubernetes connection.
    case appManaged
    /// A timer will delete this rule.
    case scheduledClosure
    /// The editor changes one CIDR; sending it would drop the others.
    case multipleCIDRs

    init(rule: CivoRule, isScheduledForClosure: Bool) {
        if isScheduledForClosure {
            self = .scheduledClosure
        } else if CivoAccessLabel.isAppManaged(rule.label) {
            self = .appManaged
        } else if rule.cidrs.count > 1 {
            self = .multipleCIDRs
        } else {
            self = .editable
        }
    }

    var message: String? {
        switch self {
        case .editable:
            nil
        case .appManaged:
            String(localized: "The app opens and closes this rule itself, so it cannot be edited.")
        case .scheduledClosure:
            String(localized: "A timer will close this rule, so it cannot be edited.")
        case .multipleCIDRs:
            String(localized: "This rule has several CIDR ranges and cannot be edited here.")
        }
    }
}

// MARK: - CIDR

/// An IPv4 or IPv6 network in CIDR notation, such as 203.0.113.0/24.
struct CIDRBlock: Equatable, Sendable {
    let address: [UInt8]
    let prefixLength: Int

    init?(_ text: String) {
        let parts = text.trimmed.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2, let prefix = Int(parts[1]), String(prefix) == parts[1],
              let address = Self.bytes(of: parts[0]),
              (0...address.count * 8).contains(prefix) else { return nil }
        self.address = address
        self.prefixLength = prefix
    }

    /// 0.0.0.0/0, ::/0 or any other block with prefix length 0.
    var isGlobal: Bool { prefixLength == 0 }

    func contains(_ ip: String) -> Bool {
        guard let other = Self.bytes(of: ip.trimmed), other.count == address.count else { return false }
        var remaining = prefixLength
        for (lhs, rhs) in zip(address, other) where remaining > 0 {
            let bits = min(remaining, 8)
            let mask = UInt8(truncatingIfNeeded: 0xFF << (8 - bits))
            if lhs & mask != rhs & mask { return false }
            remaining -= bits
        }
        return true
    }

    /// The 4 bytes of an IPv4 or the 16 bytes of an IPv6 address, nil for anything else, including scoped addresses.
    static func bytes(of address: String) -> [UInt8]? {
        var v4 = in_addr()
        if inet_pton(AF_INET, address, &v4) == 1 {
            return withUnsafeBytes(of: &v4) { Array($0) }
        }
        var v6 = in6_addr()
        if inet_pton(AF_INET6, address, &v6) == 1 {
            return withUnsafeBytes(of: &v6) { Array($0) }
        }
        return nil
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
