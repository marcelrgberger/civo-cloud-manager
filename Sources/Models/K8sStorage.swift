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
    var volumeName: String? { spec?.volumeName }
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

// MARK: - PersistentVolumes

struct K8sPVList: Codable, Sendable {
    let items: [K8sPV]
}

struct K8sPV: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let spec: K8sPVSpec?
    let status: K8sPVStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var capacity: String { spec?.capacity?["storage"] ?? "—" }
    var civoVolumeId: String? { spec?.csi?.volumeHandle }
}

struct K8sPVSpec: Codable, Sendable {
    let capacity: [String: String]?
    let storageClassName: String?
    let csi: K8sCSISource?
    let claimRef: K8sPVClaimRef?
    let accessModes: [String]?
}

struct K8sCSISource: Codable, Sendable {
    let driver: String?
    let volumeHandle: String?
}

struct K8sPVClaimRef: Codable, Sendable {
    let name: String?
    let namespace: String?
}

struct K8sPVStatus: Codable, Sendable {
    let phase: String?
}
