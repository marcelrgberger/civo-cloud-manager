import Foundation

// MARK: - ConfigMaps

struct K8sConfigMapList: Codable, Sendable {
    let items: [K8sConfigMap]
}

struct K8sConfigMap: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let data: [String: String]?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
    var dataEntries: [String: String] { data ?? [:] }
}

// MARK: - Secrets

struct K8sSecretList: Codable, Sendable {
    let items: [K8sSecret]
}

struct K8sSecret: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let type: String?
    let data: [String: String]?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
    var secretType: String { type ?? "Opaque" }
    /// Only expose key names, not values (security)
    var dataKeys: [String] { data.map { Array($0.keys) } ?? [] }
}
