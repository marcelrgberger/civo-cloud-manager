import Foundation

struct K8sNodeList: Codable, Sendable {
    let items: [K8sNode]
}

struct K8sNode: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sNodeStatus?
    let spec: K8sNodeSpec?

    var id: String { metadata.name ?? metadata.uid ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
}

struct K8sMetadata: Codable, Sendable {
    let name: String?
    let uid: String?
    let labels: [String: String]?
    let annotations: [String: String]?
    let creationTimestamp: String?
}

struct K8sNodeStatus: Codable, Sendable {
    let conditions: [K8sNodeCondition]?
    let addresses: [K8sNodeAddress]?
    let capacity: K8sResourceList?
    let allocatable: K8sResourceList?
    let nodeInfo: K8sNodeSystemInfo?
}

struct K8sNodeCondition: Codable, Identifiable, Sendable {
    let type: String?
    let status: String?
    let reason: String?
    let message: String?
    let lastHeartbeatTime: String?

    var id: String { type ?? "unknown" }
    var isHealthy: Bool {
        if type == "Ready" { return status == "True" }
        return status == "False"
    }
}

struct K8sNodeAddress: Codable, Identifiable, Sendable {
    let type: String?
    let address: String?

    var id: String { "\(type ?? "")-\(address ?? "")" }
}

struct K8sResourceList: Codable, Sendable {
    let cpu: String?
    let memory: String?
    let pods: String?
    let ephemeralStorage: String?

    enum CodingKeys: String, CodingKey {
        case cpu, memory, pods
        case ephemeralStorage = "ephemeral-storage"
    }
}

struct K8sNodeSystemInfo: Codable, Sendable {
    let machineID: String?
    let systemUUID: String?
    let kernelVersion: String?
    let osImage: String?
    let containerRuntimeVersion: String?
    let kubeletVersion: String?
    let architecture: String?
    let operatingSystem: String?
}

struct K8sNodeSpec: Codable, Sendable {
    let podCIDR: String?
    let providerID: String?
    let taints: [K8sNodeTaint]?
}

struct K8sNodeTaint: Codable, Sendable {
    let key: String?
    let value: String?
    let effect: String?
}
