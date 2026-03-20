import SwiftUI

struct CreateVolumeView: View {
    @Bindable var vm: VolumeViewModel
    @State private var name = ""
    @State private var sizeGb = 10
    @State private var networkId = ""

    var body: some View {
        Form {
            Section("Volume Details") {
                TextField("Name", text: $name)
                Stepper("Size: \(sizeGb) GB", value: $sizeGb, in: 1...10000, step: 10)
                Picker("Network", selection: $networkId) {
                    Text("Default").tag("")
                    ForEach(vm.availableNetworks) { net in
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
        .navigationTitle("Create Volume")
        .task { await vm.loadFormData() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingVolume = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = [
                            "name": name,
                            "size_gb": sizeGb,
                        ]
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        _ = await vm.createVolume(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
