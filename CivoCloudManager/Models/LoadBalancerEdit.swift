import Foundation

// MARK: - Ownership

/// Who changes a load balancer. Only one the app may change is offered for editing.
enum LoadBalancerOwnership: Equatable, Sendable {
    /// Created by Civo's Kubernetes cloud controller; changes belong to the Kubernetes Service.
    case managed
    /// Civo reported, in the documented form, that no cluster owns it.
    case verifiedUnmanaged
    /// Civo's answer does not show who owns it.
    case unknown

    /// Civo's cloud controller manager sets `cluster_id` on every load balancer it creates and finds its own load
    /// balancers again by that value (civo/civo-cloud-controller-manager, `createLoadBalancer` and
    /// `loadBalancerBelongsToService`), so Civo reports it for every controller-managed one. An answer without the
    /// field, or in the older `Backends` string form, decides nothing.
    static func evaluate(_ lb: CivoLoadBalancer) -> LoadBalancerOwnership {
        if let clusterId = lb.clusterId, !clusterId.trimmed.isEmpty { return .managed }
        guard lb.reportsClusterId, lb.backendEntries != nil else { return .unknown }
        return .verifiedUnmanaged
    }
}

// MARK: - Editability

/// Whether the editor may change a load balancer.
enum LoadBalancerEditability: Equatable, Sendable {
    case editable
    case managed
    case ownershipUnknown
    /// The backends are not all reported with IP, protocol and ports, so an update could not send them back unchanged.
    case unreadableBackends
    /// Only an available load balancer is changed; the value is Civo's state.
    case unavailable(String)

    init(_ lb: CivoLoadBalancer) {
        switch LoadBalancerOwnership.evaluate(lb) {
        case .managed:
            self = .managed
        case .unknown:
            self = .ownershipUnknown
        case .verifiedUnmanaged:
            if lb.backendEntries?.allSatisfy({ LoadBalancerBackendKey($0) != nil }) != true {
                self = .unreadableBackends
            } else if lb.state?.caseInsensitiveCompare("available") != .orderedSame {
                self = .unavailable(lb.state ?? "")
            } else {
                self = .editable
            }
        }
    }

    var message: String? {
        switch self {
        case .editable:
            nil
        case .managed:
            String(localized: "Kubernetes manages this load balancer. Change it through its Kubernetes Service.")
        case .ownershipUnknown:
            String(localized: "Editing is not offered because Civo's answer does not show whether Kubernetes manages this load balancer.")
        case .unreadableBackends:
            String(localized: "Civo does not report every backend with IP address, protocol and ports, so this load balancer cannot be edited here.")
        case .unavailable(let state):
            String(localized: "Only an available load balancer can be edited. Its state is \(state.isEmpty ? "-" : state).")
        }
    }
}

// MARK: - Settings

enum LoadBalancerAlgorithm: String, CaseIterable, Sendable {
    case roundRobin = "round_robin"
    case leastConnections = "least_connections"

    var title: String {
        switch self {
        case .roundRobin: String(localized: "Round Robin")
        case .leastConnections: String(localized: "Least Connections")
        }
    }

    static func title(of value: String) -> String {
        LoadBalancerAlgorithm(rawValue: value)?.title ?? value
    }
}

/// Kubernetes' own names for the policies, shown as they are in every language.
enum LoadBalancerTrafficPolicy: String, CaseIterable, Sendable {
    case cluster = "Cluster"
    case local = "Local"
}

// MARK: - Backends

/// A backend compared by value: the address as bytes, so `2001:db8::1` and `2001:0DB8:0:0:0:0:0:1` are the same,
/// the protocol in capitals and both ports. An IPv4-mapped IPv6 address stays distinct from the IPv4 form.
struct LoadBalancerBackendKey: Hashable, Sendable {
    let address: [UInt8]
    let `protocol`: String
    let sourcePort: Int
    let targetPort: Int

    init?(_ backend: LoadBalancerBackend) {
        guard let address = Self.address(of: backend.ip),
              let proto = backend.protocol?.uppercased(), LoadBalancerDraft.protocols.contains(proto),
              let source = backend.sourcePort, LoadBalancerDraft.validPorts.contains(source),
              let target = backend.targetPort, LoadBalancerDraft.validPorts.contains(target) else { return nil }
        self.address = address
        self.protocol = proto
        self.sourcePort = source
        self.targetPort = target
    }

    /// The bytes of a plain IPv4 or IPv6 address. A zone such as `%en0` names an interface of this Mac, not a backend.
    static func address(of ip: String) -> [UInt8]? {
        let text = ip.trimmed
        guard !text.contains("%") else { return nil }
        return CIDRBlock.bytes(of: text)
    }
}

extension LoadBalancerBackend {
    /// "10.0.0.5 TCP 80->8080", as the comparison shows it.
    var display: String {
        let ports = "\(sourcePort.map(String.init) ?? "?")->\(targetPort.map(String.init) ?? "?")"
        return "\(ip) \(self.protocol ?? "?") \(ports)"
    }
}

/// A backend as the conflict check and the read back compare it: its value plus the health check port, which an
/// update sends back unchanged and must therefore find unchanged.
private struct ComparedBackend: Hashable {
    let key: LoadBalancerBackendKey
    let healthCheckPort: Int?

    init?(_ backend: LoadBalancerBackend) {
        guard let key = LoadBalancerBackendKey(backend) else { return nil }
        self.key = key
        healthCheckPort = backend.healthCheckPort
    }
}

/// How often each backend occurs, so a backend listed twice is counted twice. nil when one cannot be read.
private func multiset(_ backends: [LoadBalancerBackend]) -> [ComparedBackend: Int]? {
    var counts: [ComparedBackend: Int] = [:]
    for backend in backends {
        guard let compared = ComparedBackend(backend) else { return nil }
        counts[compared, default: 0] += 1
    }
    return counts
}

/// One editable backend row. The id keeps rows apart that hold the same values while they are typed.
struct LoadBalancerBackendRow: Identifiable, Equatable, Sendable {
    let id = UUID()
    var ip = ""
    var proto = "TCP"
    var sourcePort = ""
    var targetPort = ""

    /// The row as Civo receives it; ports that are not numbers stay unknown and fail validation.
    var backend: LoadBalancerBackend {
        LoadBalancerBackend(
            ip: ip.trimmed, protocol: proto,
            sourcePort: Int(sourcePort.trimmed), targetPort: Int(targetPort.trimmed)
        )
    }
}

// MARK: - Draft

/// The load balancer settings the app creates and changes. Everything else Civo knows, such as session
/// affinity, proxy protocol or TLS, is left alone. Existing backends are never removed or changed: Civo
/// documents the update's `backends` only as "an array of backend objects to update", which does not show
/// whether an omitted backend is removed. An edit therefore sends every existing backend unchanged plus the
/// added ones, which is the same result either way.
struct LoadBalancerDraft: Equatable, Sendable {
    static let protocols = ["TCP", "UDP"]
    static let validPorts = 1...65535

    var name: String
    var algorithm: String
    /// nil leaves the policy to Civo on create; on edit nil means Civo did not report it, so it is not offered.
    var trafficPolicy: LoadBalancerTrafficPolicy?
    var networkId: String
    /// New backends; on edit they are added to the existing ones.
    var backends: [LoadBalancerBackendRow]

    /// An empty form with one backend row.
    init() {
        name = ""
        algorithm = LoadBalancerAlgorithm.roundRobin.rawValue
        trafficPolicy = nil
        networkId = ""
        backends = [LoadBalancerBackendRow()]
    }

    /// The editable settings of `lb`, without added backends.
    init(editing lb: CivoLoadBalancer) {
        name = lb.name
        algorithm = lb.algorithm ?? ""
        trafficPolicy = lb.externalTrafficPolicy.flatMap(LoadBalancerTrafficPolicy.init(rawValue:))
        networkId = lb.networkId ?? ""
        backends = []
    }

    // MARK: Validation

    /// Why the draft cannot be sent, each reason once and empty when it can. `editing` is the load balancer as
    /// last loaded, nil for a new one. Civo checks the request again, for example the network and the quota.
    func problems(editing lb: CivoLoadBalancer? = nil) -> [LoadBalancerDraftProblem] {
        var problems: [LoadBalancerDraftProblem] = []
        if name.trimmed.isEmpty { problems.append(.emptyName) }
        if lb == nil, networkId.isEmpty { problems.append(.noNetwork) }
        let algorithmChanged = lb.map { algorithm != ($0.algorithm ?? "") } ?? true
        if algorithmChanged, LoadBalancerAlgorithm(rawValue: algorithm) == nil { problems.append(.unknownAlgorithm) }

        let existing = lb?.backendEntries ?? []
        if existing.isEmpty, backends.isEmpty { problems.append(.noBackends) }
        var seen = Set(existing.compactMap(LoadBalancerBackendKey.init))
        for row in backends {
            let backend = row.backend
            if LoadBalancerBackendKey.address(of: backend.ip) == nil { problems.append(.invalidIP) }
            if !Self.protocols.contains(row.proto) { problems.append(.unknownProtocol) }
            if !(backend.sourcePort.map(Self.validPorts.contains) ?? false)
                || !(backend.targetPort.map(Self.validPorts.contains) ?? false) {
                problems.append(.invalidPort)
            }
            if let key = LoadBalancerBackendKey(backend), !seen.insert(key).inserted { problems.append(.duplicateBackend) }
        }
        return problems.reduce(into: []) { unique, problem in
            if !unique.contains(problem) { unique.append(problem) }
        }
    }

    // MARK: Comparison

    /// What the edit changes on `lb`, in the order the editor shows it. A policy Civo did not report is not compared.
    func changes(from lb: CivoLoadBalancer) -> [LoadBalancerChange] {
        var changes: [LoadBalancerChange] = []
        if name.trimmed != lb.name {
            changes.append(LoadBalancerChange(field: .name, before: lb.name, after: name.trimmed))
        }
        if algorithm != (lb.algorithm ?? "") {
            changes.append(LoadBalancerChange(
                field: .algorithm, before: LoadBalancerAlgorithm.title(of: lb.algorithm ?? ""), after: LoadBalancerAlgorithm.title(of: algorithm)
            ))
        }
        if let trafficPolicy, let current = lb.externalTrafficPolicy, trafficPolicy.rawValue != current {
            changes.append(LoadBalancerChange(field: .trafficPolicy, before: current, after: trafficPolicy.rawValue))
        }
        for (index, row) in backends.enumerated() {
            changes.append(LoadBalancerChange(field: .addedBackend(index), before: "", after: row.backend.display))
        }
        return changes
    }

    /// The backends `lb` has after the edit: all existing ones, then the added ones.
    func backendsAfterEdit(of lb: CivoLoadBalancer) -> [LoadBalancerBackend] {
        (lb.backendEntries ?? []) + backends.map(\.backend)
    }

    /// The differences between what `original` should look like after this edit and what Civo reports afterwards in
    /// `actual`, nil when they match. Settings the edit left alone are expected unchanged.
    func mismatch(in actual: CivoLoadBalancer, requestedFrom original: CivoLoadBalancer) -> LoadBalancerMismatch? {
        var fields: [LoadBalancerChange.Field] = []
        if actual.name != name.trimmed { fields.append(.name) }
        if (actual.algorithm ?? "") != algorithm { fields.append(.algorithm) }
        if actual.externalTrafficPolicy != trafficPolicy?.rawValue ?? original.externalTrafficPolicy { fields.append(.trafficPolicy) }

        let expected = backendsAfterEdit(of: original)
        let reported = actual.backendEntries ?? []
        var missing: [LoadBalancerBackend] = []
        var unexpected: [LoadBalancerBackend] = []
        if let expectedCounts = multiset(expected), let reportedCounts = multiset(reported) {
            if expectedCounts != reportedCounts {
                missing = Self.surplus(of: expected, over: reportedCounts)
                unexpected = Self.surplus(of: reported, over: expectedCounts)
            }
        } else {
            unexpected = reported
        }
        guard !fields.isEmpty || !missing.isEmpty || !unexpected.isEmpty else { return nil }
        return LoadBalancerMismatch(fields: fields, missingBackends: missing, unexpectedBackends: unexpected)
    }

    /// The backends of `list` beyond the counts in `other`.
    private static func surplus(of list: [LoadBalancerBackend], over other: [ComparedBackend: Int]) -> [LoadBalancerBackend] {
        var remaining = other
        return list.filter { backend in
            guard let key = ComparedBackend(backend) else { return true }
            guard let count = remaining[key], count > 0 else { return true }
            remaining[key] = count - 1
            return false
        }
    }

    // MARK: Requests

    /// The body of `POST /v2/loadbalancers`. A traffic policy left to Civo is not sent.
    func createBody(region: String) -> [String: Any] {
        var body: [String: Any] = [
            "name": name.trimmed,
            "network_id": networkId,
            "region": region,
            "algorithm": algorithm,
            "backends": backends.map(\.backend.requestValue),
        ]
        if let trafficPolicy { body["external_traffic_policy"] = trafficPolicy.rawValue }
        return body
    }

    /// The body of `PUT /v2/loadbalancers/:id`: the changed settings only, and with added backends the complete list.
    func updateBody(for lb: CivoLoadBalancer, region: String) -> [String: Any] {
        var body: [String: Any] = ["region": region]
        for change in changes(from: lb) {
            switch change.field {
            case .name: body["name"] = name.trimmed
            case .algorithm: body["algorithm"] = algorithm
            case .trafficPolicy: body["external_traffic_policy"] = trafficPolicy?.rawValue
            case .addedBackend: body["backends"] = backendsAfterEdit(of: lb).map(\.requestValue)
            }
        }
        return body
    }
}

extension CivoLoadBalancer {
    /// Whether `other` has the same editable settings, comparing backends regardless of their order.
    func hasSameSettings(as other: CivoLoadBalancer) -> Bool {
        guard name == other.name, algorithm == other.algorithm, externalTrafficPolicy == other.externalTrafficPolicy,
              let lhs = backendEntries.flatMap(multiset), let rhs = other.backendEntries.flatMap(multiset) else { return false }
        return lhs == rhs
    }
}

enum LoadBalancerDraftProblem: Error, Equatable, Sendable {
    case emptyName, noNetwork, noBackends, invalidIP, invalidPort, unknownProtocol, unknownAlgorithm, duplicateBackend

    var message: String {
        switch self {
        case .emptyName:
            String(localized: "Enter a name.")
        case .noNetwork:
            String(localized: "Choose a network.")
        case .noBackends:
            String(localized: "Add at least one backend.")
        case .invalidIP:
            String(localized: "Enter each backend IP address as an IPv4 or IPv6 address, such as 192.168.1.10.")
        case .invalidPort:
            String(localized: "Source and target ports must be whole numbers from 1 to 65535.")
        case .unknownProtocol:
            String(localized: "Choose TCP or UDP as the backend protocol.")
        case .unknownAlgorithm:
            String(localized: "Choose Round Robin or Least Connections as the algorithm.")
        case .duplicateBackend:
            String(localized: "Each backend may appear only once with the same IP address, protocol and ports.")
        }
    }
}

struct LoadBalancerChange: Equatable, Sendable, Identifiable {
    enum Field: Hashable, Sendable {
        case name, algorithm, trafficPolicy
        /// The added backend at this position of the draft.
        case addedBackend(Int)
    }

    let field: Field
    let before: String
    let after: String

    var id: Field { field }
}

/// What Civo reports differently from the requested edit.
struct LoadBalancerMismatch: Equatable, Sendable {
    let fields: [LoadBalancerChange.Field]
    /// Requested backends Civo does not report.
    let missingBackends: [LoadBalancerBackend]
    /// Backends Civo reports that were not requested.
    let unexpectedBackends: [LoadBalancerBackend]
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
