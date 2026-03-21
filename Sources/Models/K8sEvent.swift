import Foundation

struct K8sEventList: Codable, Sendable {
    let items: [K8sEvent]
}

struct K8sEvent: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let type: String?
    let reason: String?
    let message: String?
    let involvedObject: K8sObjectReference?
    let firstTimestamp: String?
    let lastTimestamp: String?
    let count: Int?

    var id: String { metadata.uid ?? metadata.name ?? "\(reason ?? "")-\(firstTimestamp ?? "")" }

    var isWarning: Bool { type == "Warning" }
}

struct K8sObjectReference: Codable, Sendable {
    let kind: String?
    let name: String?
    let namespace: String?
}
