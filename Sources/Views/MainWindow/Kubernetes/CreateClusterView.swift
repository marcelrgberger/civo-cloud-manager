import SwiftUI

struct CreateClusterView: View {
    @Bindable var vm: KubernetesViewModel
    @State private var name = ""
    @State private var networkId = ""
    @State private var cniPlugin = "flannel"
    @State private var nodeSize = ""
    @State private var nodeCount = 3
    @State private var applications = ""

    private let cniOptions = ["flannel", "cilium"]

    var body: some View {
        Form {
            Section("Cluster Details") {
                TextField("Name", text: $name)
                Picker("CNI Plugin", selection: $cniPlugin) {
                    ForEach(cniOptions, id: \.self) { Text($0) }
                }
                .help("Network plugin for pod communication")
            }

            Section("Node Pool") {
                Stepper("Nodes: \(nodeCount)", value: $nodeCount, in: 1...10)
                    .help("Number of worker nodes")
            }

            Section("Select Node Size") {
                SizePickerGrid(sizes: vm.availableSizes, selectedSize: $nodeSize)
            }

            Section("Networking") {
                Picker("Network", selection: $networkId) {
                    Text("Default").tag("")
                    ForEach(vm.availableNetworks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
            }

            Section("Marketplace Apps") {
                TextField("Apps (comma-separated)", text: $applications)
                    .help("e.g. Traefik-v2-nodeport, metrics-server")
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Kubernetes Cluster")
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
                            "cni_plugin": cniPlugin,
                            "num_target_nodes": nodeCount,
                        ]
                        if !nodeSize.isEmpty { body["target_nodes_size"] = nodeSize }
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        if !applications.isEmpty {
                            let apps = applications.split(separator: ",").map {
                                ["application": $0.trimmingCharacters(in: .whitespaces)]
                            }
                            body["applications"] = apps
                        }
                        _ = await vm.createCluster(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
