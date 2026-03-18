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
    let apiEndpoint: String?
    let masterIp: String?
    let dnsEntry: String?
    let networkId: String?
    let firewallId: String?
    let namespace: String?
    let cniPlugin: String?
    let createdAt: String?
    let pools: [CivoNodePool]?
    let installedApplications: [CivoK8sApp]?
    let conditions: [CivoK8sCondition]?

    enum CodingKeys: String, CodingKey {
        case id, name, version, status, ready, pools, conditions
        case clusterType = "cluster_type"
        case numTargetNodes = "num_target_nodes"
        case targetNodesSize = "target_nodes_size"
        case builtAt = "built_at"
        case kubernetesVersion = "kubernetes_version"
        case apiEndpoint = "api_endpoint"
        case masterIp = "master_ip"
        case dnsEntry = "dns_entry"
        case networkId = "network_id"
        case firewallId = "firewall_id"
        case namespace
        case cniPlugin = "cni_plugin"
        case createdAt = "created_at"
        case installedApplications = "installed_applications"
    }
}

struct CivoKubernetesListItem: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let clusterType: String?
    let status: String
    let nodes: String?
    let pools: String?
    let conditions: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, nodes, pools, conditions
        case clusterType = "cluster_type"
    }
}

struct CivoNodePool: Codable, Identifiable, Sendable {
    let id: String
    let count: Int?
    let size: String?
    let instanceNames: [String]?

    enum CodingKeys: String, CodingKey {
        case id, count, size
        case instanceNames = "instance_names"
    }
}

struct CivoK8sApp: Codable, Identifiable, Sendable {
    let application: String?
    let name: String?
    let version: String?
    let maintainer: String?
    let description: String?

    var id: String { name ?? application ?? "unknown-app" }

    enum CodingKeys: String, CodingKey {
        case application, name, version, maintainer, description
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
