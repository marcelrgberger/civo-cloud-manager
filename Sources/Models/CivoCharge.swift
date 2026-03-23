import Foundation
import SwiftUI

struct CivoCharge: Codable, Identifiable, Sendable {
    let id: Int
    let code: String
    let label: String
    let from: String
    let to: String?
    let numHours: Double
    let sizeGb: Double?
    let nodes: Int?
    let region: String?
    let size: Double?
    let unit: String?
    let productId: String?
    let previousChargeId: Int?
    let parentProductId: String?

    // Civo pricing per hour (from civo.com/pricing, March 2026)
    private static let hourlyRates: [String: Double] = [
        // Databases
        "database-g3.db.xsmall": 0.0595,
        "database-g3.db.small": 0.119,
        "database-g3.db.medium": 0.238,
        "database-g3.db.large": 0.476,
        "database-g3.db.xlarge": 0.952,
        "database-g3.db.2xlarge": 1.904,
        // K8s nodes (g4s)
        "kube-node-g4s.kube.xsmall": 0.0069,
        "kube-node-g4s.kube.small": 0.0137,
        "kube-node-g4s.kube.medium": 0.0274,
        "kube-node-g4s.kube.large": 0.0548,
        "kube-node-g4s.kube.xlarge": 0.1096,
        "kube-node-g4s.kube.2xlarge": 0.2192,
        // Load Balancer
        "loadbalancer": 0.0137,
        // Volumes: $0.10/GB/month = $0.000137/GB/hour
        // Object Store: $5/500GB/month
        // IP: $3/month
    ]

    var estimatedHourlyCost: Double {
        if let rate = Self.hourlyRates[code] {
            return rate
        }
        // Volume: per GB per hour
        if code == "volume" {
            return (sizeGb ?? 0) * 0.000137
        }
        // Object Store: per GB per hour
        if code == "objectstore" {
            return (sizeGb ?? 0) * 0.0000149
        }
        return 0
    }

    var totalCost: Double {
        numHours * estimatedHourlyCost
    }

    var resourceType: String {
        if code.contains("database") { return "Database" }
        if code.contains("loadbalancer") { return "Load Balancer" }
        if code.contains("kube") { return "Kubernetes" }
        if code.contains("instance") { return "Instance" }
        if code == "volume" { return "Volume" }
        if code == "objectstore" { return "Object Store" }
        if code.contains("ip") { return "IP Address" }
        if code.contains("snapshot") { return "Snapshot" }
        return "Other"
    }

    var icon: String {
        switch resourceType {
        case "Kubernetes": return "helm"
        case "Database": return "cylinder.split.1x2"
        case "Instance": return "desktopcomputer"
        case "Volume": return "cylinder"
        case "Object Store": return "tray.2"
        case "Load Balancer": return "arrow.triangle.branch"
        case "IP Address": return "network"
        case "Snapshot": return "camera"
        default: return "dollarsign.circle"
        }
    }

    var iconColor: Color {
        switch resourceType {
        case "Kubernetes": return .blue
        case "Database": return .purple
        case "Instance": return .green
        case "Volume": return .orange
        case "Object Store": return .cyan
        case "Load Balancer": return .indigo
        case "IP Address": return .teal
        case "Snapshot": return .mint
        default: return .secondary
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, code, label, from, to, nodes, region, size, unit
        case numHours = "num_hours"
        case sizeGb = "size_gb"
        case productId = "product_id"
        case previousChargeId = "previous_charge_id"
        case parentProductId = "parent_product_id"
    }
}
