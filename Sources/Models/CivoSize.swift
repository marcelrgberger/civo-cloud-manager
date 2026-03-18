import Foundation

struct CivoSize: Codable, Identifiable, Sendable {
    let name: String
    let description: String?
    let cpuCores: String?
    let ramMb: String?
    let diskGb: String?
    let type: String?

    var id: String { name }

    var cpuCoresInt: Int { Int(cpuCores ?? "0") ?? 0 }
    var ramMbInt: Int { Int(ramMb ?? "0") ?? 0 }
    var diskGbInt: Int { Int(diskGb ?? "0") ?? 0 }

    enum CodingKeys: String, CodingKey {
        case name, description, type
        case cpuCores = "cpu_cores"
        case ramMb = "ram_mb"
        case diskGb = "disk_gb"
    }
}
