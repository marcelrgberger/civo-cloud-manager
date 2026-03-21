import Foundation

struct K8sDeploymentList: Codable, Sendable {
    let items: [K8sDeployment]
}

struct K8sDeployment: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sDeploymentStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }

    var readyReplicas: Int { status?.readyReplicas ?? 0 }
    var desiredReplicas: Int { status?.replicas ?? 0 }
    var isHealthy: Bool { readyReplicas >= desiredReplicas && desiredReplicas > 0 }
}

struct K8sDeploymentStatus: Codable, Sendable {
    let replicas: Int?
    let readyReplicas: Int?
    let availableReplicas: Int?
    let unavailableReplicas: Int?
}
