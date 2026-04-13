import Foundation

// MARK: - Services

struct K8sServiceList: Codable, Sendable {
    let items: [K8sService]
}

struct K8sService: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let spec: K8sServiceSpec?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
    var type: String { spec?.type ?? "ClusterIP" }
    var clusterIP: String { spec?.clusterIP ?? "—" }
}

struct K8sServiceSpec: Codable, Sendable {
    let type: String?
    let clusterIP: String?
    let ports: [K8sServicePort]?
    let selector: [String: String]?
    let externalIPs: [String]?
    let loadBalancerIP: String?
}

struct K8sServicePort: Codable, Identifiable, Sendable {
    let name: String?
    let port: Int?
    let targetPort: K8sIntOrString?
    let nodePort: Int?
    let `protocol`: String?

    var id: String { "\(name ?? "")-\(port ?? 0)" }
}

enum K8sIntOrString: Codable, Sendable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else { self = .int(0) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }

    var display: String {
        switch self {
        case .int(let v): return "\(v)"
        case .string(let v): return v
        }
    }
}

// MARK: - Ingresses

struct K8sIngressList: Codable, Sendable {
    let items: [K8sIngress]
}

struct K8sIngress: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let spec: K8sIngressSpec?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var namespace: String { metadata.namespace ?? "default" }
}

struct K8sIngressSpec: Codable, Sendable {
    let rules: [K8sIngressRule]?
    let tls: [K8sIngressTLS]?
}

struct K8sIngressRule: Codable, Sendable {
    let host: String?
    let http: K8sIngressHTTP?
}

struct K8sIngressHTTP: Codable, Sendable {
    let paths: [K8sIngressPath]?
}

struct K8sIngressPath: Codable, Sendable {
    let path: String?
    let pathType: String?
    let backend: K8sIngressBackend?
}

struct K8sIngressBackend: Codable, Sendable {
    let service: K8sIngressBackendService?
}

struct K8sIngressBackendService: Codable, Sendable {
    let name: String?
    let port: K8sIngressBackendPort?
}

struct K8sIngressBackendPort: Codable, Sendable {
    let number: Int?
    let name: String?
}

struct K8sIngressTLS: Codable, Sendable {
    let hosts: [String]?
    let secretName: String?
}

// MARK: - Namespaces

struct K8sNamespaceList: Codable, Sendable {
    let items: [K8sNamespace]
}

struct K8sNamespace: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let status: K8sNamespaceStatus?

    var id: String { metadata.uid ?? metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
    var phase: String { status?.phase ?? "Active" }
}

struct K8sNamespaceStatus: Codable, Sendable {
    let phase: String?
}
