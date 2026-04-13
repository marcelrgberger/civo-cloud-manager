import SwiftUI

struct CreateNetworkView: View {
    @Bindable var vm: NetworkViewModel
    @State private var label = ""
    @State private var cidrV4 = ""

    var body: some View {
        Form {
            Section("Network Details") {
                TextField("Label", text: $label)
                TextField("CIDR v4 (optional)", text: $cidrV4)
                    .help("e.g. 10.0.0.0/24")
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Network")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingNetwork = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = ["label": label]
                        if !cidrV4.isEmpty { body["cidr_v4"] = cidrV4 }
                        _ = await vm.createNetwork(body)
                    }
                }
                .disabled(label.isEmpty || vm.isSaving)
            }
        }
    }
}
