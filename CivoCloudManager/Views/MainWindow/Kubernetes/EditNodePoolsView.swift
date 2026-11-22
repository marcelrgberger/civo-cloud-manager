import SwiftUI

/// Changes the node count of pools, adds pools and removes them, with a summary and a cost estimate of every
/// change before anything is sent. Changes that delete nodes are confirmed separately.
struct EditNodePoolsView: View {
    let controller: KubernetesNodePoolController
    let session: KubernetesNodePoolController.Session
    let onSave: (_ confirmingRemoval: Bool) -> Void

    @State private var newPoolSize = ""
    @State private var newPoolCount = 1
    @State private var isConfirmingRemoval = false

    private var draft: KubernetesNodePoolDraft { session.draft }
    private var target: KubernetesNodePoolTarget { session.target }

    var body: some View {
        Form {
            Section {
                LabeledContent("Cluster", value: target.clusterName)
                LabeledContent("Region", value: target.region)
            }

            Section("Node Pools") {
                ForEach(draft.shownPools, id: \.id) { pool in
                    shownPoolRow(pool)
                }
                ForEach(draft.additions, id: \.id) { pool in
                    addedPoolRow(pool)
                }
            }
            .disabled(controller.isSending)

            addPoolSection
                .disabled(controller.isSending)
            summarySection

            if let error = controller.sheetError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Node Pools")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { controller.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                if controller.isSending {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Save Changes") {
                        if controller.removesNodes {
                            isConfirmingRemoval = true
                        } else {
                            onSave(false)
                        }
                    }
                    .disabled(controller.changes.isEmpty)
                }
            }
        }
        .confirmationDialog("Delete nodes?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button("Delete Nodes", role: .destructive) { onSave(true) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(removalMessage)
        }
    }

    // MARK: - Pools

    @ViewBuilder
    private func shownPoolRow(_ pool: CivoNodePoolSpec) -> some View {
        HStack {
            poolLabel(id: pool.id, size: pool.size)
                .strikethrough(draft.isRemoved(pool.id))
            Spacer()
            if draft.isRemoved(pool.id) {
                Text("Will be removed")
                    .font(.caption)
                    .foregroundStyle(.red)
                Button("Keep") { controller.edit { $0.keep(pool.id) } }
                    .buttonStyle(.borderless)
            } else {
                Stepper(
                    KubernetesNodePoolText.nodes(draft.count(ofPool: pool.id)),
                    value: Binding(
                        get: { draft.count(ofPool: pool.id) },
                        set: { count in controller.edit { $0.setCount(count, ofPool: pool.id) } }
                    ),
                    in: KubernetesNodePoolDraft.minimumCount...Int.max
                )
                .fixedSize()
                Button("Remove Pool", systemImage: "trash", role: .destructive) {
                    controller.edit { $0.remove(pool.id) }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Remove this pool and all its nodes")
                .disabled(draft.remainingPoolCount <= 1)
            }
        }
    }

    private func addedPoolRow(_ pool: CivoNodePoolSpec) -> some View {
        HStack {
            poolLabel(id: pool.id, size: pool.size)
            Spacer()
            Text("New")
                .font(.caption)
                .foregroundStyle(.green)
            Text(KubernetesNodePoolText.nodes(pool.count))
            Button("Discard", systemImage: "minus.circle", role: .destructive) {
                controller.edit { $0.discardAddition(pool.id) }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Do not add this pool")
            .disabled(draft.remainingPoolCount <= 1)
        }
    }

    private func poolLabel(id: String, size: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(id)
                .font(.body.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
            Text(size)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var addPoolSection: some View {
        Section {
            if let sizes = session.sizes {
                SizePickerGrid(sizes: sizes, selectedSize: $newPoolSize, filterPrefix: "Kubernetes")
                HStack {
                    Stepper(KubernetesNodePoolText.nodes(newPoolCount), value: $newPoolCount, in: KubernetesNodePoolDraft.minimumCount...Int.max)
                    Spacer()
                    Button("Add Pool", systemImage: "plus.circle") {
                        controller.edit { $0.addPool(size: newPoolSize, count: newPoolCount) }
                        newPoolSize = ""
                        newPoolCount = KubernetesNodePoolDraft.minimumCount
                    }
                    .disabled(newPoolSize.isEmpty)
                }
            } else if let error = session.sizesError {
                Text("The sizes could not be loaded, so no pool can be added: \(error)")
                    .foregroundStyle(.red)
            } else {
                ProgressView().controlSize(.small)
            }
        } header: {
            Text("Add Pool")
        } footer: {
            Text("The size of a pool cannot be changed later. To use another size, add a pool and remove the old one.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            if controller.changes.isEmpty {
                Text("No changes yet.")
                    .foregroundStyle(.secondary)
            } else {
                let estimate = controller.costEstimate
                ForEach(Array(estimate.rows.enumerated()), id: \.offset) { _, row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.change.summary)
                        Text(KubernetesNodePoolCostEstimate.rowText(row))
                            .font(.caption)
                            .foregroundStyle(row.hourlyDelta == nil ? .orange : .secondary)
                    }
                }
                Text(estimate.totalText)
                    .font(.body.weight(.medium))
                ForEach(controller.quotaShortfalls, id: \.resource) { shortfall in
                    Label(shortfall.message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                if session.quota == nil, let quotaError = session.quotaError {
                    Text("The quota could not be checked: \(quotaError)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if controller.removesNodes {
                    Label("Removing a pool or lowering its node count deletes nodes. Workloads running on them are interrupted, and data stored locally on them is lost.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Summary")
        } footer: {
            Text("Costs are estimated from the hourly rates in Cost Estimate and may differ from Civo's bill. Before saving, the cluster is loaded again; if a changed pool differs from what is shown here, nothing is sent.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var removalMessage: String {
        let removing = controller.changes.filter(\.removesNodes).map(\.summary)
        return String(localized: "\(removing.joined(separator: "\n"))\n\nThe app does not drain the nodes first. Workloads on them are interrupted, and their local data is lost.")
    }
}
