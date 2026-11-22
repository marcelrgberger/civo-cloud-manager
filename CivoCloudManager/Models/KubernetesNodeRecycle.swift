import Foundation

/// The worker node a replacement was started for, with the cluster, account and region its detail was loaded from.
struct KubernetesNodeRecycleTarget: Equatable, Sendable {
    let clusterId: String
    let clusterName: String
    let region: String
    /// The account the cluster was loaded with, so a replacement never reaches another account.
    let account: CivoAccount
    let hostname: String
    /// The pool that listed the node when the replacement was started.
    let poolId: String
}

/// Why a node replacement cannot be offered or sent. Nothing was sent in any of these cases.
enum KubernetesNodeRecycleError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case accountChanged
    case clusterRemoved
    case clusterBusy(String)
    case upgradeInProgress
    case nodeRemoved(String)
    case nodeAmbiguous(String)
    case nodeMoved(String)
    case nodeListUnavailable
    case replacementAlreadyRequested(String)

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Replacing a node requires Full Access.")
        case .noRegion:
            String(localized: "The region of this cluster is unknown. Reload the cluster and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the node replacement was cancelled. Nothing was sent.")
        case .accountChanged:
            String(localized: "The API key changed, so the node replacement was cancelled. Nothing was sent.")
        case .clusterRemoved:
            String(localized: "The cluster no longer exists, so nothing was sent.")
        case .clusterBusy(let status):
            String(localized: "The cluster is busy (status \(status)), so no node is replaced. Wait until it is active, then try again.")
        case .upgradeInProgress:
            String(localized: "The cluster is not on its desired version yet, so no node is replaced. Wait until the upgrade has finished, then try again.")
        case .nodeRemoved(let hostname):
            String(localized: "The node \"\(hostname)\" is no longer part of the cluster, so nothing was sent.")
        case .nodeAmbiguous(let hostname):
            String(localized: "The hostname \"\(hostname)\" is listed more than once in the cluster, so the node cannot be identified and nothing was sent.")
        case .nodeMoved(let hostname):
            String(localized: "The node \"\(hostname)\" is now listed in another node pool, so nothing was sent. Check the node and try again.")
        case .nodeListUnavailable:
            String(localized: "Civo did not list the nodes of this cluster, so the node cannot be identified and nothing was sent.")
        case .replacementAlreadyRequested(let hostname):
            String(localized: "A replacement of \"\(hostname)\" was already requested. Wait until the cluster no longer lists this node.")
        }
    }
}

enum KubernetesNodeIdentity {
    /// The pool that lists `hostname`. A node is identified only when exactly one entry of one pool names it;
    /// Civo's recycle request names the node by hostname alone, so a duplicate could replace the wrong node.
    /// Without the node names of every pool, neither uniqueness nor removal can be told.
    static func pool(listing hostname: String, in cluster: CivoKubernetesCluster) -> Result<CivoNodePool, KubernetesNodeRecycleError> {
        guard let pools = cluster.pools, pools.allSatisfy({ $0.instanceNames != nil }) else { return .failure(.nodeListUnavailable) }
        let listing = hostname.isEmpty ? [] : pools.flatMap { pool in
            (pool.instanceNames ?? []).filter { $0 == hostname }.map { _ in pool }
        }
        switch listing.count {
        case 0: return .failure(.nodeRemoved(hostname))
        case 1: return .success(listing[0])
        default: return .failure(.nodeAmbiguous(hostname))
        }
    }

    /// Why no node of `cluster` can be replaced right now, nil while it can.
    static func busyStatus(of cluster: CivoKubernetesCluster) -> KubernetesNodeRecycleError? {
        guard cluster.status.lowercased() == "active" else { return .clusterBusy(cluster.status) }
        return cluster.isUpgradeRunning ? .upgradeInProgress : nil
    }
}
