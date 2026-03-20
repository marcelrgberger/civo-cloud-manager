import SwiftUI

struct CreateFirewallView: View {
    @Bindable var vm: NetworkViewModel
    @State private var name = ""
    @State private var networkId = ""

    var body: some View {
        Form {
            Section("Firewall Details") {
                TextField("Name", text: $name)
                Picker("Network", selection: $networkId) {
                    Text("Default").tag("")
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingFirewall = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = ["name": name]
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        _ = await vm.createFirewall(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
