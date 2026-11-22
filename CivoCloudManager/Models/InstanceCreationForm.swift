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

    // MARK: Advanced

    /// How many instances to create; `count` is only sent above 1.
    var count = 1
    /// Sent as `public_ip`: `create` allocates a public IP address, `none` creates the instance without one.
    var createsPublicIp = true
    /// Left out when empty; Civo then uses the disk image's default user.
    var initialUser = ""
    /// Follows the hostname until it is edited. Left out when empty; Civo then uses the hostname.
    var reverseDns: String {
        get { editedReverseDns ?? trimmedHostname }
        set { editedReverseDns = newValue }
    }
    private var editedReverseDns: String?
    /// Sent as written, without trimming; left out when it holds only whitespace.
    var script = ""

    private var trimmedHostname: String { hostname.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Civo asks for a fully qualified domain name; this only rejects empty names and inner whitespace.
    private var hasValidHostname: Bool {
        !trimmedHostname.isEmpty && trimmedHostname.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }

    var isComplete: Bool {
        hasValidHostname && !size.isEmpty && !diskImage.isEmpty && !networkId.isEmpty
    }

    /// The tags as Civo expects them, nil when none were entered.
    private var tagChange: Result<InstanceTagChange?, InstanceTagInputError> {
        do {
            return .success(try InstanceTagChange.replacing(with: tags))
        } catch .empty {
            return .success(nil)
        } catch {
            return .failure(error)
        }
    }

    /// Why the entered tags cannot be sent, nil while they can.
    var tagsProblem: String? {
        guard case .failure(let error) = tagChange else { return nil }
        return error.message
    }

    /// The request body, or nil while a required field is missing or an entry is invalid, so that no request is sent.
    /// Without a firewall, `firewall_id` is left out; in the default network Civo then uses the default firewall.
    func requestBody() -> [String: Any]? {
        guard isComplete, count >= 1, case .success(let tagChange) = tagChange else { return nil }
        var body: [String: Any] = [
            "hostname": trimmedHostname,
            "size": size,
            "template_id": diskImage,
            "network_id": networkId,
            "public_ip": createsPublicIp ? "create" : "none",
        ]
        if !firewallId.isEmpty { body["firewall_id"] = firewallId }
        if !sshKeyId.isEmpty { body["ssh_key_id"] = sshKeyId }
        if let tagChange { body["tags"] = tagChange.parameter }
        if count > 1 { body["count"] = count }
        let user = initialUser.trimmingCharacters(in: .whitespacesAndNewlines)
        if !user.isEmpty { body["initial_user"] = user }
        let dns = reverseDns.trimmingCharacters(in: .whitespacesAndNewlines)
        if !dns.isEmpty { body["reverse_dns"] = dns }
        if !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { body["script"] = script }
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
