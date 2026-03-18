import Foundation

enum CivoAccessLabel {
    static let prefix = "civo-cloud-"

    static var hostname: String {
        Host.current().localizedName?.replacingOccurrences(of: " ", with: "-") ?? "unknown"
    }

    static func make(firewallName: String) -> String {
        "\(prefix)\(hostname)-\(firewallName)"
    }
}
