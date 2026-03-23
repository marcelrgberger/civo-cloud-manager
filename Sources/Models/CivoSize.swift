import Foundation

struct CivoSize: Codable, Identifiable, Sendable {
    let name: String
    let description: String?
    let cpu: Int?
    let ram: Int?
    let disk: Int?
    let type: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, description, cpu, ram, disk, type
    }

    var displayName: String {
        if let description, !description.isEmpty { return description }
        return name
    }

    var specSummary: String {
        var parts: [String] = []
        if let cpu { parts.append("\(cpu) vCPU") }
        if let ram {
            if ram >= 1024 {
                parts.append("\(ram / 1024) GB RAM")
            } else {
                parts.append("\(ram) MB RAM")
            }
        }
        if let disk { parts.append("\(disk) GB Disk") }
        return parts.joined(separator: " · ")
    }

    var detailLabel: String {
        if specSummary.isEmpty { return displayName }
        return "\(displayName)  —  \(specSummary)"
    }
}
