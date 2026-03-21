import SwiftUI

struct EditLabelsView: View {
    let clusterId: String
    let poolId: String
    let initialLabels: [String: String]
    @Bindable var vm: KubernetesViewModel
    let onDismiss: () -> Void

    @State private var labels: [(key: String, value: String)]
    @State private var newKey = ""
    @State private var newValue = ""

    init(clusterId: String, poolId: String, initialLabels: [String: String], vm: KubernetesViewModel, onDismiss: @escaping () -> Void) {
        self.clusterId = clusterId
        self.poolId = poolId
        self.initialLabels = initialLabels
        self.vm = vm
        self.onDismiss = onDismiss
        _labels = State(initialValue: initialLabels.sorted(by: { $0.key < $1.key }).map { (key: $0.key, value: $0.value) })
    }

    var body: some View {
        Form {
            Section("Labels") {
                if labels.isEmpty {
                    Text("No labels configured")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        HStack {
                            Text(label.key)
                                .font(.body.monospaced())
                                .frame(minWidth: 100, alignment: .leading)
                            Text("=")
                                .foregroundStyle(.secondary)
                            Text(label.value)
                                .font(.body.monospaced())
                            Spacer()
                            Button {
                                labels.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section("Add Label") {
                HStack {
                    TextField("Key", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                    Text("=")
                        .foregroundStyle(.secondary)
                    TextField("Value", text: $newValue)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        guard !newKey.isEmpty else { return }
                        labels.append((key: newKey, value: newValue))
                        newKey = ""
                        newValue = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.borderless)
                    .disabled(newKey.isEmpty)
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Labels")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onDismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(vm.isSaving)
            }
        }
    }

    private func save() async {
        var labelDict: [String: String] = [:]
        for label in labels {
            labelDict[label.key] = label.value
        }

        let body: [String: Any] = [
            "pools": [
                ["id": poolId, "labels": labelDict]
            ]
        ]
        let success = await vm.updateCluster(clusterId, body: body)
        if success {
            await vm.loadClusterDetail(clusterId)
            onDismiss()
        }
    }
}
