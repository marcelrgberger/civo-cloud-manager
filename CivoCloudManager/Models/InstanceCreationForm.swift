import Foundation

/// Input of the Create Instance form. `POST /v2/instances` requires `hostname`, `size`,
/// `network_id` and `template_id` (https://www.civo.com/api/instances).
struct InstanceCreationForm {
    var hostname = ""
    var size = ""
    var diskImage = ""
    /// A firewall must exist in the instance's network, so a network change drops the chosen firewall.
    var networkId = "" {
        didSet { if networkId != oldValue { firewallId = "" } }
    }
    var firewallId = ""
    var sshKeyId = ""
    var tags = ""

    private var trimmedHostname: String { hostname.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Civo asks for a fully qualified domain name; this only rejects empty names and inner whitespace.
    private var hasValidHostname: Bool {
        !trimmedHostname.isEmpty && trimmedHostname.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }

    var isComplete: Bool {
        hasValidHostname && !size.isEmpty && !diskImage.isEmpty && !networkId.isEmpty
    }

    /// The request body, or nil while a required field is missing so that no request is sent.
    /// Without a firewall, `firewall_id` is left out; in the default network Civo then uses the default firewall.
    func requestBody() -> [String: Any]? {
        guard isComplete else { return nil }
        var body: [String: Any] = [
            "hostname": trimmedHostname,
            "size": size,
            "template_id": diskImage,
            "network_id": networkId,
        ]
        if !firewallId.isEmpty { body["firewall_id"] = firewallId }
        if !sshKeyId.isEmpty { body["ssh_key_id"] = sshKeyId }
        if !tags.isEmpty {
            body["tags"] = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        }
        return body
    }

    /// Preselects the network Civo flags as default unless a listed network is already chosen.
    /// Like the official Go client (civogo `NewInstanceConfig` via `GetDefaultNetwork`), the request
    /// then carries the default network's ID explicitly instead of leaving `network_id` out.
    mutating func selectDefaultNetwork(from networks: [CivoNetwork]) {
        guard !networks.contains(where: { $0.id == networkId }) else { return }
        networkId = networks.first { $0.isDefault == true }?.id ?? ""
    }

    static func firewalls(_ firewalls: [CivoFirewall], in networkId: String) -> [CivoFirewall] {
        firewalls.filter { $0.networkId == networkId }
    }
}
