import SwiftUI

struct CreateInstanceView: View {
    @Bindable var vm: InstanceViewModel
    @State private var hostname = ""
    @State private var size = ""
    @State private var diskImage = ""
    @State private var networkId = ""
    @State private var firewallId = ""
    @State private var sshKeyId = ""
    @State private var tags = ""

    var body: some View {
        Form {
            Section("Instance Details") {
                TextField("Hostname", text: $hostname)
                Picker("Disk Image", selection: $diskImage) {
                    Text("Select an image").tag("")
                    ForEach(vm.availableDiskImages) { img in
                        Text(img.displayName).tag(img.id)
                    }
                }
            }

            Section("Select Size") {
                SizePickerGrid(sizes: vm.availableSizes, selectedSize: $size)
            }

            Section("Networking") {
                Picker("Network", selection: $networkId) {
                    Text("Default").tag("")
                    ForEach(vm.availableNetworks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
                Picker("Firewall", selection: $firewallId) {
                    Text("Default").tag("")
                    ForEach(vm.availableFirewalls) { fw in
                        Text(fw.name).tag(fw.id)
                    }
                }
            }

            Section("Authentication") {
                Picker("SSH Key", selection: $sshKeyId) {
                    Text("None").tag("")
                    ForEach(vm.sshKeys) { key in
                        Text(key.name).tag(key.id)
                    }
                }
            }

            Section("Tags") {
                TextField("Tags (comma-separated)", text: $tags)
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Instance")
        .task { await vm.loadFormData() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingInstance = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = ["hostname": hostname]
                        if !size.isEmpty { body["size"] = size }
                        if !diskImage.isEmpty { body["template_id"] = diskImage }
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        if !firewallId.isEmpty { body["firewall_id"] = firewallId }
                        if !sshKeyId.isEmpty { body["ssh_key_id"] = sshKeyId }
                        if !tags.isEmpty {
                            body["tags"] = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
                        }
                        _ = await vm.createInstance(body)
                    }
                }
                .disabled(hostname.isEmpty || vm.isSaving)
            }
        }
    }
}
