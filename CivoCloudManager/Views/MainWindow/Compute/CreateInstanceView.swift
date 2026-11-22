import SwiftUI

struct CreateInstanceView: View {
    @Bindable var vm: InstanceViewModel
    @State private var form = InstanceCreationForm()

    var body: some View {
        Form {
            Section("Instance Details") {
                TextField("Hostname", text: $form.hostname)
                Picker("Disk Image", selection: $form.diskImage) {
                    Text("Select an image").tag("")
                    ForEach(vm.availableDiskImages) { img in
                        Text(img.displayName).tag(img.id)
                    }
                }
            }

            Section("Select Size") {
                SizePickerGrid(sizes: vm.availableSizes, selectedSize: $form.size, filterPrefix: "Instance")
            }

            Section("Networking") {
                Picker("Network", selection: $form.networkId) {
                    Text("Select a network").tag("")
                    ForEach(vm.availableNetworks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
                Picker("Firewall", selection: $form.firewallId) {
                    Text("Default").tag("")
                    ForEach(InstanceCreationForm.firewalls(vm.availableFirewalls, in: form.networkId)) { fw in
                        Text(fw.name).tag(fw.id)
                    }
                }
            }

            Section("Authentication") {
                Picker("SSH Key", selection: $form.sshKeyId) {
                    Text("None").tag("")
                    ForEach(vm.sshKeys) { key in
                        Text(key.name).tag(key.id)
                    }
                }
            }

            Section("Tags") {
                TextField("Tags (comma-separated)", text: $form.tags)
            }

            if !form.isComplete {
                Section {
                    Text("Hostname, size, disk image and network are required.")
                        .foregroundStyle(.secondary)
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Instance")
        .task {
            await vm.loadFormData()
            form.selectDefaultNetwork(from: vm.availableNetworks)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingInstance = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { _ = await vm.createInstance(form) }
                }
                .disabled(!form.isComplete || vm.isSaving)
            }
        }
    }
}
