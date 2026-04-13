import SwiftUI

struct CreateRuleView: View {
    @Bindable var vm: NetworkViewModel
    let firewallId: String

    @State private var proto = "tcp"
    @State private var startPort = ""
    @State private var endPort = ""
    @State private var cidr = "0.0.0.0/0"
    @State private var direction = "ingress"
    @State private var action = "allow"
    @State private var label = ""

    private let protocols = ["tcp", "udp", "icmp"]
    private let directions = ["ingress", "egress"]
    private let actions = ["allow", "deny"]

    var body: some View {
        Form {
            Section("Rule Details") {
                Picker("Protocol", selection: $proto) {
                    ForEach(protocols, id: \.self) { Text($0) }
                }
                TextField("Start Port", text: $startPort)
                    .help("e.g. 80, 443, 6443")
                TextField("End Port (optional)", text: $endPort)
                    .help("Leave empty for single port")
                TextField("CIDR", text: $cidr)
                    .help("e.g. 0.0.0.0/0 for all, or 10.0.0.1/32 for single IP")
            }

            Section("Direction & Action") {
                Picker("Direction", selection: $direction) {
                    ForEach(directions, id: \.self) { Text($0) }
                }
                Picker("Action", selection: $action) {
                    ForEach(actions, id: \.self) { Text($0) }
                }
            }

            Section("Label") {
                TextField("Label (optional)", text: $label)
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add Rule")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingRule = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await create() }
                }
                .disabled(startPort.isEmpty || cidr.isEmpty || vm.isSaving)
            }
        }
    }

    private func create() async {
        var body: [String: Any] = [
            "protocol": proto,
            "start_port": startPort,
            "cidr": [cidr],
            "direction": direction,
            "action": action,
            "region": CivoConfig.shared.region,
        ]
        if !endPort.isEmpty { body["end_port"] = endPort }
        if !label.isEmpty { body["label"] = label }
        _ = await vm.createRule(firewallId, body: body)
    }
}
