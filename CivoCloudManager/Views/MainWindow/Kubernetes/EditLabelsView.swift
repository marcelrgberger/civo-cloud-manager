import SwiftUI

struct EditLabelsView: View {
    /// The cluster, account and region the labels were loaded from, captured when the editor opened.
    let target: KubernetesNodePoolTarget
    let poolId: String
    let initialLabels: [String: String]
    @Bindable var vm: KubernetesViewModel
    let onDismiss: () -> Void

    @State private var labels: [(key: String, value: String)]
    @State private var newKey = ""
    @State private var newValue = ""

    init(target: KubernetesNodePoolTarget, poolId: String, initialLabels: [String: String], vm: KubernetesViewModel, onDismiss: @escaping () -> Void) {
        self.target = target
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
        // The labels being sent are fixed once saving starts.
        .disabled(vm.isSaving)
        .navigationTitle("Edit Labels")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onDismiss() }
                    .disabled(vm.isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(vm.isSaving)
            }
        }
        // Once sent, the labels can no longer be called back, so the editor stays until Civo answers.
        .interactiveDismissDisabled(vm.isSaving)
    }

    private func save() async {
        var labelDict: [String: String] = [:]
        for label in labels {
            labelDict[label.key] = label.value
        }
        let success = await vm.updateLabels(labelDict, shownLabels: initialLabels, ofPool: poolId, in: target)
        if success {
            await vm.loadClusterDetail(target.clusterId)
            onDismiss()
        }
    }
}
