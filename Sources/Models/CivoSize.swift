import Foundation

struct CivoSize: Codable, Identifiable, Sendable {
    let name: String
    let description: String?
    let cpu: Int?
    let ram: Int?
    let disk: Int?
    let type: String?
    let cpuCores: Int?
    let ramMb: Int?
    let diskGb: Int?
    let niceName: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, description, cpu, ram, disk, type
        case cpuCores = "cpu_cores"
        case ramMb = "ram_mb"
        case diskGb = "disk_gb"
        case niceName = "nice_name"
    }

    var effectiveCpu: Int? { cpuCores ?? cpu }
    var effectiveRam: Int? { ramMb ?? ram }
    var effectiveDisk: Int? { diskGb ?? disk }

    var displayName: String {
        if let niceName, !niceName.isEmpty { return niceName }
        if let description, !description.isEmpty { return description }
        return name
    }

    var specSummary: String {
        var parts: [String] = []
        if let c = effectiveCpu { parts.append("\(c) vCPU") }
        if let r = effectiveRam {
            if r >= 1024 {
                parts.append("\(r / 1024) GB RAM")
            } else {
                parts.append("\(r) MB RAM")
            }
        }
        if let d = effectiveDisk { parts.append("\(d) GB Disk") }
        return parts.joined(separator: " · ")
    }

    var detailLabel: String {
        if specSummary.isEmpty { return displayName }
        return "\(displayName)  —  \(specSummary)"
    }
}
