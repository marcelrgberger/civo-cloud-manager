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

    // MARK: - Pricing (user-editable, stored in UserDefaults)

    static let defaultHourlyRates: [String: Double] = [
        // Databases (0 additional nodes)
        "database-g3.db.small": 0.059524,
        "database-g3.db.medium": 0.119048,
        "database-g3.db.large": 0.238095,
        "database-g3.db.xlarge": 0.476190,
        "database-g3.db.2xlarge": 0.952381,
        // K8s Standard nodes (g4s)
        "kube-node-g4s.kube.xsmall": 0.007440,
        "kube-node-g4s.kube.small": 0.014881,
        "kube-node-g4s.kube.medium": 0.029762,
        "kube-node-g4s.kube.large": 0.059524,
        // K8s Performance nodes
        "kube-node-g4s.kube.small-perf": 0.119048,
        "kube-node-g4s.kube.medium-perf": 0.238095,
        "kube-node-g4s.kube.large-perf": 0.476190,
        "kube-node-g4s.kube.xlarge-perf": 0.952381,
        // K8s CPU Optimized
        "kube-node-g4s.kube.small-cpu": 0.190476,
        "kube-node-g4s.kube.medium-cpu": 0.380952,
        "kube-node-g4s.kube.large-cpu": 0.761905,
        "kube-node-g4s.kube.xlarge-cpu": 1.523810,
        // K8s RAM Optimized
        "kube-node-g4s.kube.small-ram": 0.107143,
        "kube-node-g4s.kube.medium-ram": 0.214286,
        "kube-node-g4s.kube.large-ram": 0.428571,
        "kube-node-g4s.kube.xlarge-ram": 0.857143,
        // Compute Standard
        "instance-g3.xsmall": 0.007440,
        "instance-g3.small": 0.014881,
        "instance-g3.medium": 0.029762,
        "instance-g3.large": 0.059524,
        "instance-g3.xlarge": 0.119048,
        "instance-g3.2xlarge": 0.238095,
        // Load Balancer
        "loadbalancer": 0.014881,
    ]

    private static let ratesKey = "CivoHourlyRates"

    static var hourlyRates: [String: Double] {
        get {
            if let data = UserDefaults.standard.data(forKey: ratesKey),
               let rates = try? JSONDecoder().decode([String: Double].self, from: data) {
                return rates
            }
            // First launch: seed with defaults
            saveHourlyRates(defaultHourlyRates)
            return defaultHourlyRates
        }
    }

    static func saveHourlyRates(_ rates: [String: Double]) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: ratesKey)
        }
    }

    static func resetToDefaultRates() {
        saveHourlyRates(defaultHourlyRates)
    }

    var estimatedHourlyCost: Double {
        // Exact match
        if let rate = Self.hourlyRates[code] {
            return rate
        }
        // Fuzzy match: try matching the size suffix
        for (key, rate) in Self.hourlyRates where code.contains(key.components(separatedBy: ".").last ?? "") {
            // Only match if the prefix type also matches
            if code.hasPrefix(key.components(separatedBy: "-").first ?? "") || code.hasPrefix(key.components(separatedBy: ".").first ?? "") {
                return rate
            }
        }
        // Volume: $0.11/GB/month = $0.000149/GB/hour
        if code == "volume" || code.contains("volume") {
            return (sizeGb ?? Double(size ?? 0)) * 0.000149
        }
        // Object Store: $0.01086/GB/month = $0.000015/GB/hour
        if code == "objectstore" || code.contains("object") {
            return (sizeGb ?? Double(size ?? 0)) * 0.000015
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
