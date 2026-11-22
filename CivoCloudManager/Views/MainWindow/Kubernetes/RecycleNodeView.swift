import SwiftUI

/// Names the node to be replaced and what a replacement costs the workloads on it, before anything is sent.
/// The controller checks the captured target and the reloaded cluster again when the user confirms.
struct RecycleNodeView: View {
    let controller: KubernetesNodeRecycleController
    let request: KubernetesNodeRecycleController.Request
    let onConfirm: () -> Void

    private var target: KubernetesNodeRecycleTarget { request.target }

    var body: some View {
        Form {
            Section {
                LabeledContent("Cluster", value: target.clusterName)
                LabeledContent("Region", value: target.region)
                LabeledContent("Hostname") {
                    Text(target.hostname)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
                LabeledContent("Node Pool", value: target.poolId)
            }

            Section {
                Label("Civo deletes this node and creates a new one in its place. Workloads running on it are interrupted, and data stored locally on the node is lost.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } footer: {
                Text("The node is not drained first, and Pod Disruption Budgets are not guaranteed. To restart a single pod or deployment, use its restart action instead. Civo does not state how a replacement is billed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = controller.sheetError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Replace Node")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { controller.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                if controller.isSending {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Replace Node", role: .destructive, action: onConfirm)
                }
            }
        }
    }
}
