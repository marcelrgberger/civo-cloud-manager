import Foundation

struct K8sPVCList: Codable, Sendable {
    let items: [K8sPVC]
}

struct K8sPVC: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let spec: K8sPVCSpec?
    let status: K8sPVCStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
    var phase: String { status?.phase ?? "—" }
    var capacity: String { status?.capacity?["storage"] ?? "—" }
    var storageClass: String { spec?.storageClassName ?? "—" }
}

struct K8sPVCSpec: Codable, Sendable {
    let storageClassName: String?
    let volumeName: String?
    let accessModes: [String]?
}

struct K8sPVCStatus: Codable, Sendable {
    let phase: String?
    let capacity: [String: String]?
    let accessModes: [String]?
}
