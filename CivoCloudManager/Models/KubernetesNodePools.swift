import Foundation

/// One pool as sent in the `pools` array of `PUT /v2/kubernetes/clusters/:id`. Civo treats that array as the
/// complete desired state: a pool left out is deleted, and an empty array deletes every pool.
struct CivoNodePoolSpec: Equatable, Sendable {
    let id: String
    /// Civo does not change the size of an existing pool.
    let size: String
    var count: Int
    var labels: [String: String]?
    let taints: [CivoNodeTaint]?
    let publicIPNodePool: Bool?

    /// A pool the cluster does not have yet. Labels, taints and public IPs are left to Civo's defaults.
    init(newPoolId id: String, size: String, count: Int) {
        self.id = id
        self.size = size
        self.count = count
        labels = nil
        taints = nil
        publicIPNodePool = nil
    }

    /// The pool as Civo reported it, nil while its size or node count is unknown, since it could not be sent unchanged.
    init?(_ pool: CivoNodePool) {
        guard let size = pool.size, !size.isEmpty, let count = pool.count else { return nil }
        id = pool.id
        self.size = size
        self.count = count
        labels = pool.labels
        taints = pool.taints
        publicIPNodePool = pool.publicIPNodePool
    }

    /// The pool fields of Civo's Go client `civogo`. Labels, taints and public IPs are sent as Civo reported them,
    /// so a pool that is only kept does not lose them.
    var body: [String: Any] {
        var body: [String: Any] = ["id": id, "size": size, "count": count]
        if let labels { body["labels"] = labels }
        if let taints {
            body["taints"] = taints.map { taint in
                ["key": taint.key, "value": taint.value, "effect": taint.effect].compactMapValues { $0 }
            }
        }
        if let publicIPNodePool { body["public_ip_node_pool"] = publicIPNodePool }
        return body
    }
}

/// One change the user made to the pools of a cluster.
enum KubernetesNodePoolChange: Equatable, Sendable {
    case scale(poolId: String, size: String, from: Int, to: Int)
    case add(poolId: String, size: String, count: Int)
    case remove(poolId: String, size: String, count: Int)

    var poolId: String {
        switch self {
        case .scale(let poolId, _, _, _), .add(let poolId, _, _), .remove(let poolId, _, _): poolId
        }
    }

    var size: String {
        switch self {
        case .scale(_, let size, _, _), .add(_, let size, _), .remove(_, let size, _): size
        }
    }

    /// Nodes added, or removed when negative.
    var nodeDelta: Int {
        switch self {
        case .scale(_, _, let from, let to): to - from
        case .add(_, _, let count): count
        case .remove(_, _, let count): -count
        }
    }

    /// Deletes nodes, so the user confirms it separately.
    var removesNodes: Bool { nodeDelta < 0 }

    var summary: String {
        switch self {
        case .scale(let poolId, let size, let from, let to):
            String(localized: "Change pool \(poolId) (\(size)) from \(KubernetesNodePoolText.nodes(from)) to \(KubernetesNodePoolText.nodes(to))")
        case .add(_, let size, let count):
            String(localized: "Add a pool of \(KubernetesNodePoolText.nodes(count)) of size \(size)")
        case .remove(let poolId, let size, let count):
            String(localized: "Remove pool \(poolId) (\(size)) with \(KubernetesNodePoolText.nodes(count))")
        }
    }
}

enum KubernetesNodePoolText {
    /// "1 node", "3 nodes", with the plural rules of the user's language.
    static func nodes(_ count: Int) -> String {
        String(localized: "\(count) nodes")
    }
}

/// The changes made in the pool editor, against the pools shown when editing began.
struct KubernetesNodePoolDraft: Equatable, Sendable {
    /// The pools as loaded when editing began; every change is checked against them before it is sent.
    let shownPools: [CivoNodePoolSpec]
    private(set) var counts: [String: Int] = [:]
    private(set) var removals: Set<String> = []
    private(set) var additions: [CivoNodePoolSpec] = []

    /// The fewest nodes a pool keeps; a pool is removed instead of scaled to zero.
    static let minimumCount = 1

    init(shownPools: [CivoNodePoolSpec]) {
        self.shownPools = shownPools
    }

    func count(ofPool id: String) -> Int {
        counts[id] ?? shownPools.first(where: { $0.id == id })?.count ?? Self.minimumCount
    }

    func isRemoved(_ id: String) -> Bool { removals.contains(id) }

    /// Pools that stay after saving; the last one cannot be removed.
    var remainingPoolCount: Int { shownPools.count - removals.count + additions.count }

    mutating func setCount(_ count: Int, ofPool id: String) {
        guard let shown = shownPools.first(where: { $0.id == id }), !removals.contains(id), count >= Self.minimumCount else { return }
        counts[id] = count == shown.count ? nil : count
    }

    /// Marks a shown pool for removal; a removed pool is not scaled. Ignored for the last remaining pool.
    mutating func remove(_ id: String) {
        guard shownPools.contains(where: { $0.id == id }), !removals.contains(id), remainingPoolCount > 1 else { return }
        removals.insert(id)
        counts[id] = nil
    }

    mutating func keep(_ id: String) {
        removals.remove(id)
    }

    /// Adds a pool under a new UUID, the id Civo's CLI gives a pool created without a name.
    mutating func addPool(size: String, count: Int) {
        guard !size.isEmpty, count >= Self.minimumCount else { return }
        additions.append(CivoNodePoolSpec(newPoolId: UUID().uuidString.lowercased(), size: size, count: count))
    }

    /// Ignored while the added pool is the last remaining one.
    mutating func discardAddition(_ id: String) {
        guard remainingPoolCount > 1 else { return }
        additions.removeAll { $0.id == id }
    }

    /// Every change in the order of the pools shown, then the added pools.
    var changes: [KubernetesNodePoolChange] {
        let existing: [KubernetesNodePoolChange] = shownPools.compactMap { pool in
            if removals.contains(pool.id) { return .remove(poolId: pool.id, size: pool.size, count: pool.count) }
            guard let count = counts[pool.id] else { return nil }
            return .scale(poolId: pool.id, size: pool.size, from: pool.count, to: count)
        }
        return existing + additions.map { .add(poolId: $0.id, size: $0.size, count: $0.count) }
    }
}

/// Why pool changes cannot be offered or sent. Nothing was sent in any of these cases.
enum KubernetesNodePoolError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case accountChanged
    case clusterRemoved
    case clusterBusy(String)
    case upgradeInProgress
    case poolListUnavailable
    case poolStateUnknown(String)
    case poolRemoved(String)
    case poolChanged(String)
    case poolIdTaken(String)
    case labelsChanged(String)
    case sizeUnavailable(String)
    case removesAllPools
    case changeAlreadyPending

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Changing node pools requires Full Access.")
        case .noRegion:
            String(localized: "The region of this cluster is unknown. Reload the cluster and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the node pool changes were cancelled. Nothing was sent.")
        case .accountChanged:
            String(localized: "The API key changed, so the node pool changes were cancelled. Nothing was sent.")
        case .clusterRemoved:
            String(localized: "The cluster no longer exists, so nothing was sent.")
        case .clusterBusy(let status):
            String(localized: "The cluster is busy (status \(status)), so its node pools are not changed. Wait until it is active, then try again.")
        case .upgradeInProgress:
            String(localized: "The cluster is not on its desired version yet, so its node pools are not changed. Wait until the upgrade has finished, then try again.")
        case .poolListUnavailable:
            String(localized: "Civo did not list the node pools of this cluster, so nothing was sent.")
        case .poolStateUnknown(let poolId):
            String(localized: "Civo did not report the size or node count of pool \(poolId), so the pools cannot be sent unchanged and nothing was sent.")
        case .poolRemoved(let poolId):
            String(localized: "Pool \(poolId) no longer exists, so nothing was sent. Open the node pools again to see the current state.")
        case .poolChanged(let poolId):
            String(localized: "Pool \(poolId) changed since you opened the editor, so nothing was sent. Open the node pools again to see the current state.")
        case .poolIdTaken(let poolId):
            String(localized: "The cluster already has a pool \(poolId), so nothing was sent.")
        case .labelsChanged(let poolId):
            String(localized: "The labels of pool \(poolId) changed since you opened the editor, so nothing was saved. Open the labels again to see the current state.")
        case .sizeUnavailable(let size):
            String(localized: "Civo no longer offers the size \(size), so nothing was sent.")
        case .removesAllPools:
            String(localized: "A cluster keeps at least one node pool, so nothing was sent.")
        case .changeAlreadyPending:
            String(localized: "Node pool changes for this cluster were already requested. Wait until the cluster shows them, then try again.")
        }
    }
}

enum KubernetesNodePoolPlan {
    /// The complete `pools` array that applies `changes` to the pools in `cluster`, loaded again just before
    /// saving. Pools without a change are sent as Civo reports them now; a pool is left out only when its
    /// removal is one of `changes`. Nothing is sent when a changed pool differs from the one in `shownPools`.
    static func desiredPools(
        applying changes: [KubernetesNodePoolChange],
        shownPools: [CivoNodePoolSpec],
        to cluster: CivoKubernetesCluster
    ) -> Result<[CivoNodePoolSpec], KubernetesNodePoolError> {
        currentPools(of: cluster).flatMap { current in
            var desired = current
            for change in changes {
                let index = desired.firstIndex { $0.id == change.poolId }
                switch change {
                case .add(let poolId, let size, let count):
                    guard index == nil else { return .failure(.poolIdTaken(poolId)) }
                    desired.append(CivoNodePoolSpec(newPoolId: poolId, size: size, count: count))
                case .scale(let poolId, _, _, let count):
                    guard let index else { return .failure(.poolRemoved(poolId)) }
                    guard isUnchanged(desired[index], since: shownPools) else { return .failure(.poolChanged(poolId)) }
                    desired[index].count = count
                case .remove(let poolId, _, _):
                    guard let index else { return .failure(.poolRemoved(poolId)) }
                    guard isUnchanged(desired[index], since: shownPools) else { return .failure(.poolChanged(poolId)) }
                    desired.remove(at: index)
                }
            }
            // An empty array deletes every pool, which is never a normal save.
            return desired.isEmpty ? .failure(.removesAllPools) : .success(desired)
        }
    }

    /// The complete `pools` array that gives pool `poolId` the `labels` and keeps every pool otherwise as
    /// `cluster`, loaded again just before saving, reports it. Nothing is saved when the pool's labels are no
    /// longer `shownLabels`.
    static func relabeling(
        pool poolId: String,
        from shownLabels: [String: String],
        to labels: [String: String],
        in cluster: CivoKubernetesCluster
    ) -> Result<[CivoNodePoolSpec], KubernetesNodePoolError> {
        currentPools(of: cluster).flatMap { current in
            var desired = current
            guard let index = desired.firstIndex(where: { $0.id == poolId }) else { return .failure(.poolRemoved(poolId)) }
            guard (desired[index].labels ?? [:]) == shownLabels else { return .failure(.labelsChanged(poolId)) }
            desired[index].labels = labels
            return .success(desired)
        }
    }

    /// Why the pools of `cluster` cannot be changed right now, nil while they can.
    static func busyStatus(of cluster: CivoKubernetesCluster) -> KubernetesNodePoolError? {
        guard cluster.status.lowercased() == "active" else { return .clusterBusy(cluster.status) }
        return cluster.isUpgradeRunning ? .upgradeInProgress : nil
    }

    /// Every pool of `cluster` as it can be sent back unchanged.
    static func currentPools(of cluster: CivoKubernetesCluster) -> Result<[CivoNodePoolSpec], KubernetesNodePoolError> {
        guard let pools = cluster.pools, !pools.isEmpty else { return .failure(.poolListUnavailable) }
        var specs: [CivoNodePoolSpec] = []
        for pool in pools {
            guard let spec = CivoNodePoolSpec(pool) else { return .failure(.poolStateUnknown(pool.id)) }
            specs.append(spec)
        }
        return .success(specs)
    }

    /// Whether `cluster` reports every one of `changes`: changed and added pools with their node count, removed
    /// pools no longer. Pools the changes did not touch are not compared.
    static func reports(_ changes: [KubernetesNodePoolChange], in cluster: CivoKubernetesCluster) -> Bool {
        guard let pools = cluster.pools else { return false }
        return changes.allSatisfy { change in
            let count = pools.first(where: { $0.id == change.poolId })?.count
            switch change {
            case .scale(_, _, _, let to): return count == to
            case .add(_, _, let added): return count == added
            case .remove: return !pools.contains { $0.id == change.poolId }
            }
        }
    }

    private static func isUnchanged(_ pool: CivoNodePoolSpec, since shownPools: [CivoNodePoolSpec]) -> Bool {
        guard let shown = shownPools.first(where: { $0.id == pool.id }) else { return false }
        return shown.size == pool.size && shown.count == pool.count
    }
}

/// The estimated change of the hourly cost, from the user-editable rates (`CivoCharge.hourlyRates`).
struct KubernetesNodePoolCostEstimate: Equatable {
    struct Row: Equatable {
        let change: KubernetesNodePoolChange
        /// nil when no rate is known for the pool's size; never counted as zero.
        let hourlyDelta: Double?
    }

    let rows: [Row]

    init(changes: [KubernetesNodePoolChange], rates: [String: Double]) {
        rows = changes.map { change in
            Row(change: change, hourlyDelta: Self.hourlyRate(ofNodeSize: change.size, rates: rates).map { Double(change.nodeDelta) * $0 })
        }
    }

    /// The rate of a node size, keyed like Civo's charge codes (`kube-node-g4s.kube.small`).
    static func hourlyRate(ofNodeSize name: String, rates: [String: Double]) -> Double? {
        rates["kube-node-\(name)"] ?? rates[name]
    }

    var hasUnknownRate: Bool { rows.contains { $0.hourlyDelta == nil } }

    /// The sum of the rows with a known rate.
    var knownHourlyDelta: Double { rows.compactMap(\.hourlyDelta).reduce(0, +) }

    /// nil when a rate is unknown, since the total would then be wrong.
    var totalHourlyDelta: Double? { hasUnknownRate ? nil : knownHourlyDelta }

    static func formatted(_ hourlyDelta: Double) -> String {
        hourlyDelta.formatted(.currency(code: "USD").precision(.fractionLength(2...4)).sign(strategy: .always()))
    }

    static func rowText(_ row: Row) -> String {
        guard let delta = row.hourlyDelta else {
            return String(localized: "No hourly rate is known for size \(row.change.size)")
        }
        return String(localized: "\(formatted(delta)) per hour")
    }

    var totalText: String {
        if let totalHourlyDelta {
            return String(localized: "Estimated change: \(Self.formatted(totalHourlyDelta)) per hour")
        }
        if rows.allSatisfy({ $0.hourlyDelta == nil }) {
            return String(localized: "No hourly rate is known for the sizes involved, so no cost change can be estimated.")
        }
        return String(localized: "No total can be estimated, since a rate is unknown. The pools with a known rate change by \(Self.formatted(knownHourlyDelta)) per hour.")
    }
}

/// What the added nodes need beyond the free account quota, so Civo may refuse the change.
struct KubernetesNodePoolQuotaShortfall: Equatable {
    enum Resource: Equatable {
        case instances, cpuCores, ramMb, diskGb
    }

    let resource: Resource
    let needed: Int
    let free: Int

    var message: String {
        switch resource {
        case .instances:
            String(localized: "The changes add \(KubernetesNodePoolText.nodes(needed)), but the instance quota leaves \(free) free. Civo may refuse them.")
        case .cpuCores:
            String(localized: "The added nodes need \(needed) vCPU, but the quota leaves \(free) free. Civo may refuse the changes.")
        case .ramMb:
            String(localized: "The added nodes need \(needed) MB RAM, but the quota leaves \(free) MB free. Civo may refuse the changes.")
        case .diskGb:
            String(localized: "The added nodes need \(needed) GB disk, but the quota leaves \(free) GB free. Civo may refuse the changes.")
        }
    }

    /// The resources the nodes added by `changes` need beyond `quota`. Removed nodes are not counted as freed,
    /// since Civo may still hold them while the new ones start. A size without stated specs is not counted.
    static func shortfalls(for changes: [KubernetesNodePoolChange], sizes: [CivoSize], quota: CivoQuota) -> [Self] {
        let growing = changes.filter { $0.nodeDelta > 0 }
        func need(_ spec: (CivoSize) -> Int?) -> Int {
            growing.reduce(0) { total, change in
                guard let each = sizes.first(where: { $0.name == change.size }).flatMap(spec) else { return total }
                return total + each * change.nodeDelta
            }
        }
        let demands: [(Resource, Int, Int)] = [
            (.instances, growing.reduce(0) { $0 + $1.nodeDelta }, quota.instanceCountLimit - quota.instanceCountUsage),
            (.cpuCores, need(\.effectiveCpu), quota.cpuCoreLimit - quota.cpuCoreUsage),
            (.ramMb, need(\.effectiveRam), quota.ramMbLimit - quota.ramMbUsage),
            (.diskGb, need(\.effectiveDisk), quota.diskGbLimit - quota.diskGbUsage),
        ]
        return demands.compactMap { resource, needed, free in
            needed > free ? Self(resource: resource, needed: needed, free: max(0, free)) : nil
        }
    }
}
