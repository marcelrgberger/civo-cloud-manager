import Foundation

struct CivoCharge: Codable, Identifiable, Sendable {
    let code: String
    let label: String
    let from: String
    let to: String
    let numHours: Double
    let sizeGb: Double?
    let perHour: Double?

    var id: String { "\(code)-\(from)" }

    var totalCost: Double {
        numHours * (perHour ?? 0)
    }

    var resourceType: String {
        if code.hasPrefix("k8s") || label.lowercased().contains("kubernetes") { return "Kubernetes" }
        if code.hasPrefix("db") || label.lowercased().contains("database") { return "Database" }
        if code.hasPrefix("ins") || label.lowercased().contains("instance") { return "Instance" }
        if code.hasPrefix("vol") || label.lowercased().contains("volume") { return "Volume" }
        if code.hasPrefix("obj") || label.lowercased().contains("object") { return "Object Store" }
        if code.hasPrefix("lb") || label.lowercased().contains("load") { return "Load Balancer" }
        if code.hasPrefix("ip") || label.lowercased().contains("ip") { return "IP Address" }
        if code.hasPrefix("snap") || label.lowercased().contains("snapshot") { return "Snapshot" }
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
        case code, label, from, to
        case numHours = "num_hours"
        case sizeGb = "size_gb"
        case perHour = "per_hour"
    }
}

import SwiftUI
