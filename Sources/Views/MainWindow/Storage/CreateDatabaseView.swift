import SwiftUI

struct CreateDatabaseView: View {
    @Bindable var vm: DatabaseViewModel
    @State private var name = ""
    @State private var software = "PostgreSQL"
    @State private var softwareVersion = "16"
    @State private var size = ""
    @State private var nodes = 1
    @State private var networkId = ""
    @State private var firewallId = ""

    private let softwareOptions = ["PostgreSQL", "MySQL"]

    var body: some View {
        Form {
            Section("Database Details") {
                TextField("Name", text: $name)
                Picker("Software", selection: $software) {
                    ForEach(softwareOptions, id: \.self) { Text($0) }
                }
                TextField("Version", text: $softwareVersion)
                Picker("Size", selection: $size) {
                    Text("Select a size").tag("")
                    ForEach(vm.availableSizes) { s in
                        Text(s.displayName).tag(s.name)
                    }
                }
                Stepper("Nodes: \(nodes)", value: $nodes, in: 1...3)
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

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Database")
        .task { await vm.loadFormData() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreating = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = [
                            "name": name,
                            "software": software.lowercased(),
                            "software_version": softwareVersion,
                            "nodes": nodes,
                        ]
                        if !size.isEmpty { body["size"] = size }
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        if !firewallId.isEmpty { body["firewall_id"] = firewallId }
                        _ = await vm.createDatabase(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
