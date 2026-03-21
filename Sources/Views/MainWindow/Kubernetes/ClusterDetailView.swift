import SwiftUI

struct ClusterDetailView: View {
    let cluster: CivoKubernetesCluster
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var appeared = false
    @State private var editingLabelsPool: CivoNodePool?

    private var totalNodes: Int {
        cluster.pools?.reduce(0) { $0 + ($1.count ?? 0) } ?? cluster.numTargetNodes ?? 0
    }

    private var healthyConditions: Int {
        cluster.conditions?.filter(\.isHealthy).count ?? 0
    }

    private var totalConditions: Int {
        cluster.conditions?.count ?? 0
    }

    private var appCount: Int {
        cluster.installedApplications?.count ?? 0
    }

    private var poolCount: Int {
        cluster.pools?.count ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statsRow
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
        .sheet(isPresented: Binding(get: { editingLabelsPool != nil }, set: { if !$0 { editingLabelsPool = nil } })) {
            if let pool = editingLabelsPool {
                EditLabelsView(
                    clusterId: cluster.id,
                    poolId: pool.id,
                    initialLabels: pool.labels ?? [:],
                    vm: vm
                ) {
                    editingLabelsPool = nil
                }
                .frame(minWidth: 500, minHeight: 300)
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DeleteConfirmationSheet(resourceType: "Kubernetes Cluster", resourceName: cluster.name, onConfirm: {
                Task {
                    let success = await vm.removeCluster(cluster.id)
                    if success { onBack() }
                }
                showDeleteConfirmation = false
            }, onCancel: { showDeleteConfirmation = false })
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cluster.name)
                    .font(.largeTitle.bold())
                HStack(spacing: 8) {
                    Text(cluster.clusterType ?? "k3s")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let version = cluster.kubernetesVersion ?? cluster.version {
                        Text(version)
                            .font(.caption.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            StatusBadge(status: cluster.status)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard("Nodes", value: "\(totalNodes)", icon: "square.stack.3d.up", color: .blue, index: 0)
            statCard("Pools", value: "\(poolCount)", icon: "rectangle.3.group", color: .purple, index: 1)
            statCard("Health", value: "\(healthyConditions)/\(totalConditions)", icon: "heart.fill", color: healthyConditions == totalConditions ? .green : .orange, index: 2)
            statCard("Apps", value: "\(appCount)", icon: "app.badge.checkmark", color: .indigo, index: 3)
        }
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color, index: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05 + 0.1), value: appeared)
    }

    // MARK: - Info

    private var infoSection: some View {
        GroupBox("Cluster Info") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("API Endpoint", cluster.apiEndpoint ?? "—")
                infoRow("Master IP", cluster.masterIp ?? "—")
                infoRow("DNS", cluster.dnsEntry ?? "—")
                infoRow("CNI Plugin", cluster.cniPlugin ?? "—")
                infoRow("Node Size", cluster.targetNodesSize ?? "—")
                infoRow("Created", cluster.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    // MARK: - Conditions

    private var conditionsSection: some View {
        GroupBox("Conditions") {
            if let conditions = cluster.conditions, !conditions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(conditions.enumerated()), id: \.offset) { index, condition in
                        HStack {
                            Image(systemName: condition.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(condition.isHealthy ? .green : .red)
                            Text(condition.type ?? "Unknown")
                                .font(.subheadline)
                            Spacer()
                            StatusBadge(status: condition.status ?? "Unknown")
                        }
                        .padding(.vertical, 2)
                        .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(8)
            } else {
                Text("No conditions available")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
    }

    // MARK: - Node Pools

    private var nodePoolsSection: some View {
        GroupBox("Node Pools") {
            if let pools = cluster.pools, !pools.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(pools.enumerated()), id: \.element.id) { index, pool in
                        DisclosureGroup {
                            nodePoolDetail(pool)
                        } label: {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pool.id)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    Text("\(pool.count ?? 0) node(s) — \(pool.size ?? "unknown")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(pool.count ?? 0)")
                                    .font(.system(.title3, design: .rounded).bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                        .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(8)
            } else {
                Text("No node pools")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
    }

    private func nodePoolDetail(_ pool: CivoNodePool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                poolInfoRow("Pool ID", pool.id)
                poolInfoRow("Size", pool.size ?? "—")
                poolInfoRow("Node Count", "\(pool.count ?? 0)")
                poolInfoRow("Public IPs", pool.publicIPNodePool == true ? "Yes" : "No")
            }

            if let names = pool.instanceNames, !names.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instances")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                        HStack(spacing: 6) {
                            Image(systemName: "desktopcomputer")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(name)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Labels")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        editingLabelsPool = pool
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                if let labels = pool.labels, !labels.isEmpty {
                    ForEach(Array(labels.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        Text("\(key)=\(value)")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                } else {
                    Text("No labels")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let taints = pool.taints, !taints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Taints")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    ForEach(Array(taints.enumerated()), id: \.offset) { _, taint in
                        HStack(spacing: 4) {
                            Text("\(taint.key ?? "")=\(taint.value ?? ""):\(taint.effect ?? "")")
                                .font(.caption2.monospaced())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 28)
    }

    private func poolInfoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }

    // MARK: - Apps

    private var applicationsSection: some View {
        GroupBox("Installed Applications (\(appCount))") {
            if let apps = cluster.installedApplications, !apps.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(apps.enumerated()), id: \.offset) { index, app in
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
                        .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(8)
            } else {
                Text("No applications installed")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.35), value: appeared)
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
