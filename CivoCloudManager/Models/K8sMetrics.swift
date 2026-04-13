import Foundation

struct K8sNodeMetricsList: Codable, Sendable {
    let items: [K8sNodeMetrics]
}

struct K8sNodeMetrics: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let usage: K8sMetricsUsage?

    var id: String { metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }
}

struct K8sMetricsUsage: Codable, Sendable {
    let cpu: String?
    let memory: String?
}

struct K8sPodMetricsList: Codable, Sendable {
    let items: [K8sPodMetrics]
}

struct K8sPodMetrics: Codable, Identifiable, Sendable {
    let metadata: K8sMetadata
    let containers: [K8sContainerMetrics]?

    var id: String { metadata.name ?? "unknown" }
    var name: String { metadata.name ?? "unknown" }

    var totalCPU: String {
        containers?.compactMap(\.usage?.cpu).first ?? "—"
    }
    var totalMemory: String {
        containers?.compactMap(\.usage?.memory).first ?? "—"
    }
}

struct K8sContainerMetrics: Codable, Sendable {
    let name: String?
    let usage: K8sMetricsUsage?
}

struct K8sClusterMetrics: Sendable {
    let cpuUsage: Double
    let cpuCapacity: Double
    let memoryUsageMB: Double
    let memoryCapacityMB: Double
    let podCount: Int
    let podCapacity: Int
    let nodeCount: Int
    let healthyNodes: Int

    var cpuPercent: Double { cpuCapacity > 0 ? cpuUsage / cpuCapacity : 0 }
    var memoryPercent: Double { memoryCapacityMB > 0 ? memoryUsageMB / memoryCapacityMB : 0 }
}

enum K8sMetricsParser {
    static func parseCPU(_ value: String) -> Double {
        if value.hasSuffix("n") {
            return (Double(value.dropLast()) ?? 0) / 1_000_000_000
        }
        if value.hasSuffix("m") {
            return (Double(value.dropLast()) ?? 0) / 1000
        }
        return Double(value) ?? 0
    }

    static func parseMemoryMB(_ value: String) -> Double {
        if value.hasSuffix("Ki") {
            return (Double(value.dropLast(2)) ?? 0) / 1024
        }
        if value.hasSuffix("Mi") {
            return Double(value.dropLast(2)) ?? 0
        }
        if value.hasSuffix("Gi") {
            return (Double(value.dropLast(2)) ?? 0) * 1024
        }
        if value.hasSuffix("K") || value.hasSuffix("k") {
            return (Double(value.dropLast()) ?? 0) / 1024
        }
        if value.hasSuffix("M") {
            return Double(value.dropLast()) ?? 0
        }
        if value.hasSuffix("G") {
            return (Double(value.dropLast()) ?? 0) * 1024
        }
        return (Double(value) ?? 0) / (1024 * 1024)
    }
}
