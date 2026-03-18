import SwiftUI

struct ClusterDetailView: View {
    let cluster: CivoKubernetesCluster
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                infoSection
                conditionsSection
                nodePoolsSection
                applicationsSection
            }
            .padding(24)
        }
        .navigationTitle(cluster.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .confirmationDialog("Delete Cluster", isPresented: $showDeleteConfirmation) {
            Button("Delete \(cluster.name)", role: .destructive) {
                Task {
                    let success = await vm.removeCluster(cluster.id)
                    if success { onBack() }
                }
            }
        } message: {
            Text("This will permanently delete the Kubernetes cluster and all its resources. This action cannot be undone.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cluster.name)
                    .font(.largeTitle.bold())
                Text(cluster.clusterType ?? "k3s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: cluster.status)
        }
    }

    private var infoSection: some View {
        GroupBox("Cluster Info") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Version", cluster.kubernetesVersion ?? cluster.version ?? "—")
                infoRow("API Endpoint", cluster.apiEndpoint ?? "—")
                infoRow("Master IP", cluster.masterIp ?? "—")
                infoRow("DNS", cluster.dnsEntry ?? "—")
                infoRow("CNI Plugin", cluster.cniPlugin ?? "—")
                infoRow("Target Nodes", "\(cluster.numTargetNodes ?? 0)")
                infoRow("Node Size", cluster.targetNodesSize ?? "—")
                infoRow("Created", cluster.createdAt ?? "—")
            }
            .padding(8)
        }
    }

    private var conditionsSection: some View {
        GroupBox("Conditions") {
            if let conditions = cluster.conditions, !conditions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(conditions.enumerated()), id: \.offset) { _, condition in
                        HStack {
                            Image(systemName: condition.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(condition.isHealthy ? .green : .red)
                            Text(condition.type ?? "Unknown")
                                .font(.subheadline)
                            Spacer()
                            StatusBadge(status: condition.status ?? "Unknown")
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
            } else {
                Text("No conditions available")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }

    private var nodePoolsSection: some View {
        GroupBox("Node Pools") {
            if let pools = cluster.pools, !pools.isEmpty {
                VStack(spacing: 8) {
                    ForEach(pools) { pool in
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pool.id)
                                    .font(.subheadline.weight(.medium))
                                Text("\(pool.count ?? 0) node(s) — \(pool.size ?? "unknown")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
            } else {
                Text("No node pools")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }

    private var applicationsSection: some View {
        GroupBox("Installed Applications") {
            if let apps = cluster.installedApplications, !apps.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(apps.enumerated()), id: \.offset) { _, app in
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name ?? app.application ?? "Unknown")
                                    .font(.subheadline.weight(.medium))
                                if let version = app.version {
                                    Text(version)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
            } else {
                Text("No applications installed")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}
