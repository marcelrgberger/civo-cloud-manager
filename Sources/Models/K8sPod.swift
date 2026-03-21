import Foundation

struct K8sPodList: Codable, Sendable {
    let items: [K8sPod]
}

struct K8sPod: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sPodStatus?
    let spec: K8sPodSpec?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
}

struct K8sPodStatus: Codable, Sendable {
    let phase: String?
    let podIP: String?
    let hostIP: String?
    let startTime: String?
    let containerStatuses: [K8sContainerStatus]?
}

struct K8sContainerStatus: Codable, Identifiable, Sendable {
    let name: String?
    let ready: Bool?
    let restartCount: Int?
    let image: String?
    let containerID: String?

    var id: String { name ?? "unknown" }
}

struct K8sPodSpec: Codable, Sendable {
    let nodeName: String?
    let namespace: String?
    let containers: [K8sContainer]?
}

struct K8sContainer: Codable, Identifiable, Sendable {
    let name: String?
    let image: String?

    var id: String { name ?? "unknown" }
}
