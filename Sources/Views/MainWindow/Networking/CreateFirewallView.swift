import SwiftUI

struct CreateFirewallView: View {
    @Bindable var vm: NetworkViewModel
    @State private var name = ""
    @State private var networkId = ""

    private var defaultNetworkId: String {
        vm.networks.first(where: { $0.isDefault == true })?.id ?? vm.networks.first?.id ?? ""
    }

    var body: some View {
        Form {
            Section("Firewall Details") {
                TextField("Name", text: $name)
                Picker("Network", selection: $networkId) {
                    ForEach(vm.networks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Firewall")
        .onAppear { networkId = defaultNetworkId }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingFirewall = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        let body: [String: Any] = [
                            "name": name,
                            "network_id": networkId,
                        ]
                        _ = await vm.createFirewall(body)
                    }
                }
                .disabled(name.isEmpty || networkId.isEmpty || vm.isSaving)
            }
        }
    }
}
