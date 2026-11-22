import Foundation

enum CivoAccessLabel {
    static let prefix = "civo-cloud-"

    static var hostname: String {
        Host.current().localizedName?.replacingOccurrences(of: " ", with: "-") ?? "unknown"
    }

    /// Whether the app opened the rule itself, on this Mac or another one, so only the app may change it.
    static func isAppManaged(_ label: String?) -> Bool {
        label?.hasPrefix(prefix) == true
    }

    static func make(firewallName: String) -> String {
        "\(prefix)\(hostname)-\(firewallName)"
    }
}
