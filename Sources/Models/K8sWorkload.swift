import Foundation

// MARK: - Deployments

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

// MARK: - DaemonSets

struct K8sDaemonSetList: Codable, Sendable {
    let items: [K8sDaemonSet]
}

struct K8sDaemonSet: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sDaemonSetStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }

    var desired: Int { status?.desiredNumberScheduled ?? 0 }
    var ready: Int { status?.numberReady ?? 0 }
    var isHealthy: Bool { ready >= desired && desired > 0 }
}

struct K8sDaemonSetStatus: Codable, Sendable {
    let desiredNumberScheduled: Int?
    let numberReady: Int?
    let numberAvailable: Int?
}

// MARK: - StatefulSets

struct K8sStatefulSetList: Codable, Sendable {
    let items: [K8sStatefulSet]
}

struct K8sStatefulSet: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sStatefulSetStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }

    var readyReplicas: Int { status?.readyReplicas ?? 0 }
    var desiredReplicas: Int { status?.replicas ?? 0 }
    var isHealthy: Bool { readyReplicas >= desiredReplicas && desiredReplicas > 0 }
}

struct K8sStatefulSetStatus: Codable, Sendable {
    let replicas: Int?
    let readyReplicas: Int?
}

// MARK: - CronJobs

struct K8sCronJobList: Codable, Sendable {
    let items: [K8sCronJob]
}

struct K8sCronJob: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let spec: K8sCronJobSpec?
    let status: K8sCronJobStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
    var schedule: String { spec?.schedule ?? "—" }
    var activeCount: Int { status?.active?.count ?? 0 }
}

struct K8sCronJobSpec: Codable, Sendable {
    let schedule: String?
    let suspend: Bool?
}

struct K8sCronJobStatus: Codable, Sendable {
    let active: [K8sObjectReference]?
    let lastScheduleTime: String?
    let lastSuccessfulTime: String?
}
