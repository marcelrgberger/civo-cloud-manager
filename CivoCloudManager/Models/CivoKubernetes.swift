import Foundation

struct CivoKubernetesCluster: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let version: String?
    let status: String
    let ready: Bool?
    let clusterType: String?
    let numTargetNodes: Int?
    let targetNodesSize: String?
    let builtAt: String?
    let kubernetesVersion: String?
    /// Civo's hint that this version is available as an upgrade, as named in its Go client `civogo`.
    let upgradeAvailableTo: String?
    let apiEndpoint: String?
    let masterIp: String?
    let dnsEntry: String?
    let networkId: String?
    let firewallId: String?
    let namespace: String?
    let cniPlugin: String?
    let createdAt: String?
    let pools: [CivoNodePool]?
    /// The pools Civo was last asked for, as named in its Go client `civogo`; they differ from `pools` until
    /// Civo has applied that request.
    let requiredPools: [CivoNodePool]?
    let installedApplications: [CivoK8sApp]?
    let conditions: [CivoK8sCondition]?
    let kubeconfig: String?

    enum CodingKeys: String, CodingKey {
        case id, name, version, status, ready, pools, conditions
        case clusterType = "cluster_type"
        case numTargetNodes = "num_target_nodes"
        case targetNodesSize = "target_nodes_size"
        case builtAt = "built_at"
        case kubernetesVersion = "kubernetes_version"
        case upgradeAvailableTo = "upgrade_available_to"
        case apiEndpoint = "api_endpoint"
        case masterIp = "master_ip"
        case dnsEntry = "dns_entry"
        case networkId = "network_id"
        case firewallId = "firewall_id"
        case namespace
        case cniPlugin = "cni_plugin"
        case createdAt = "created_at"
        case requiredPools = "required_pools"
        case installedApplications = "installed_applications"
        case kubeconfig
    }
}

extension CivoKubernetesCluster {
    /// Whether Civo reports the cluster as not yet on its desired version. The condition is named as in Civo's CLI.
    var isUpgradeRunning: Bool {
        conditions?.first(where: { $0.type == "ClusterVersionSync" }).map { !$0.isHealthy } ?? false
    }
}


struct CivoNodePool: Codable, Identifiable, Sendable {
    let id: String
    let count: Int?
    let size: String?
    let instanceNames: [String]?
    let publicIPNodePool: Bool?
    let labels: [String: String]?
    let taints: [CivoNodeTaint]?

    enum CodingKeys: String, CodingKey {
        case id, count, size, labels, taints
        case instanceNames = "instance_names"
        case publicIPNodePool = "public_ip_node_pool"
    }
}

struct CivoNodeTaint: Codable, Equatable, Sendable {
    let key: String?
    let value: String?
    let effect: String?
}

/// An entry of `installed_applications`. Its `configuration` and `post_install` can hold generated passwords and
/// are never read.
struct CivoK8sApp: Codable, Identifiable, Sendable {
    let application: String?
    let name: String?
    let version: String?
    let maintainer: String?
    let description: String?
    /// Civo's `installed`; nil when it is missing or not a boolean.
    let installedFlag: Bool?
    let plan: String?

    var id: String { name ?? application ?? "unknown-app" }

    var state: InstalledApplicationState { InstalledApplicationState(installedFlag: installedFlag) }

    /// The chosen plan; Civo reports an empty string for an application without one.
    var planLabel: String? { plan?.isEmpty == false ? plan : nil }

    enum CodingKeys: String, CodingKey {
        case application, name, version, maintainer, description, plan
        case installedFlag = "installed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        application = try container.decodeIfPresent(String.self, forKey: .application)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        maintainer = try container.decodeIfPresent(String.self, forKey: .maintainer)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        installedFlag = try? container.decode(Bool.self, forKey: .installedFlag)
        plan = try? container.decode(String.self, forKey: .plan)
    }
}

struct CivoK8sCondition: Codable, Identifiable, Sendable {
    let type: String?
    let status: String?
    let lastTransitionTime: String?

    var id: String { type ?? "unknown-condition" }

    var isHealthy: Bool { status?.lowercased() == "true" }

    enum CodingKeys: String, CodingKey {
        case type, status
        case lastTransitionTime = "last_transition_time"
    }
}
