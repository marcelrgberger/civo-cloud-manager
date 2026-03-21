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
                if let metrics = vm.clusterMetrics {
                    liveMetricsRow(metrics)
                } else {
                    statsRow
                }
                if let k8sError = vm.k8sError {
                    ErrorBanner(message: k8sError)
                }
                if vm.isLoadingK8s && !vm.isK8sConnected {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Connecting to Kubernetes API...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                infoSection
                if !vm.events.isEmpty { eventsSection }
                if !vm.deployments.isEmpty || !vm.daemonSets.isEmpty || !vm.statefulSets.isEmpty {
                    workloadsSection
                }
                if !vm.services.isEmpty || !vm.ingresses.isEmpty { networkingSection }
                if !vm.pvcs.isEmpty { storageSection }
                if !vm.namespaces.isEmpty { namespacesSection }
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
                    .help("Return to list")
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .help("Delete this cluster")
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

    // Connect button removed — K8s API connects automatically in background

    // MARK: - Live Metrics

    private func liveMetricsRow(_ metrics: K8sClusterMetrics) -> some View {
        HStack(spacing: 16) {
            liveGauge("CPU", percent: metrics.cpuPercent,
                      detail: String(format: "%.1f / %.1f cores", metrics.cpuUsage, metrics.cpuCapacity),
                      color: metrics.cpuPercent > 0.8 ? .red : metrics.cpuPercent > 0.6 ? .orange : .blue, index: 0)
            liveGauge("Memory", percent: metrics.memoryPercent,
                      detail: String(format: "%.0f / %.0f MB", metrics.memoryUsageMB, metrics.memoryCapacityMB),
                      color: metrics.memoryPercent > 0.8 ? .red : metrics.memoryPercent > 0.6 ? .orange : .purple, index: 1)
            statCard("Pods", value: "\(metrics.podCount)/\(metrics.podCapacity)", icon: "square.grid.2x2",
                     color: .orange, index: 2)
            statCard("Nodes", value: "\(metrics.healthyNodes)/\(metrics.nodeCount)", icon: "square.stack.3d.up",
                     color: metrics.healthyNodes == metrics.nodeCount ? .green : .red, index: 3)
        }
    }

    private func liveGauge(_ title: String, percent: Double, detail: String, color: Color, index: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(percent, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percent * 100))%")
                    .font(.system(.caption, design: .rounded).bold())
            }
            .frame(width: 48, height: 48)
            Text(title)
                .font(.caption.bold())
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05 + 0.1), value: appeared)
    }

    // MARK: - Events

    private var eventsSection: some View {
        GroupBox("Recent Events (\(vm.events.count))") {
            VStack(spacing: 4) {
                ForEach(Array(vm.events.prefix(15).enumerated()), id: \.element.id) { index, event in
                    HStack(spacing: 8) {
                        Image(systemName: event.isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(event.isWarning ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(event.reason ?? "—")
                                    .font(.caption.weight(.medium))
                                if let obj = event.involvedObject {
                                    Text("\(obj.kind ?? "")/\(obj.name ?? "")")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let msg = event.message {
                                Text(msg)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .modifier(StaggeredAppear(index: index))
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    // MARK: - Workloads

    private var workloadsSection: some View {
        GroupBox("Workloads") {
            VStack(alignment: .leading, spacing: 8) {
                if !vm.deployments.isEmpty {
                    Text("Deployments (\(vm.deployments.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    ForEach(vm.deployments) { d in
                        workloadRow(d.name, ready: d.readyReplicas, desired: d.desiredReplicas, healthy: d.isHealthy, ns: d.namespace)
                    }
                }
                if !vm.daemonSets.isEmpty {
                    Text("DaemonSets (\(vm.daemonSets.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(vm.daemonSets) { d in
                        workloadRow(d.name, ready: d.ready, desired: d.desired, healthy: d.isHealthy, ns: d.namespace)
                    }
                }
                if !vm.statefulSets.isEmpty {
                    Text("StatefulSets (\(vm.statefulSets.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(vm.statefulSets) { s in
                        workloadRow(s.name, ready: s.readyReplicas, desired: s.desiredReplicas, healthy: s.isHealthy, ns: s.namespace)
                    }
                }
                if !vm.cronJobs.isEmpty {
                    Text("CronJobs (\(vm.cronJobs.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(vm.cronJobs) { cj in
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption).foregroundStyle(.blue)
                            Text(cj.name).font(.caption.weight(.medium))
                            Spacer()
                            Text(cj.schedule).font(.caption2.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.22), value: appeared)
    }

    private func workloadRow(_ name: String, ready: Int, desired: Int, healthy: Bool, ns: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: healthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption).foregroundStyle(healthy ? .green : .red)
            Text(name).font(.caption.weight(.medium))
            Text(ns).font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text("\(ready)/\(desired)").font(.caption2.monospaced())
                .foregroundStyle(healthy ? Color.secondary : Color.red)
        }
    }

    // MARK: - Networking

    private var networkingSection: some View {
        GroupBox("Networking") {
            VStack(alignment: .leading, spacing: 8) {
                if !vm.services.isEmpty {
                    Text("Services (\(vm.services.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    ForEach(vm.services) { svc in
                        HStack(spacing: 8) {
                            Image(systemName: svc.type == "LoadBalancer" ? "arrow.triangle.branch" : "network")
                                .font(.caption).foregroundStyle(.blue)
                            Text(svc.name).font(.caption.weight(.medium))
                            Text(svc.namespace).font(.caption2).foregroundStyle(.tertiary)
                            Spacer()
                            Text(svc.type).font(.caption2)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(.blue.opacity(0.1)).clipShape(Capsule())
                            if let ports = svc.spec?.ports {
                                Text(ports.map { "\($0.port ?? 0)" }.joined(separator: ","))
                                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if !vm.ingresses.isEmpty {
                    Text("Ingresses (\(vm.ingresses.count))")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(vm.ingresses) { ing in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ing.name).font(.caption.weight(.medium))
                            if let rules = ing.spec?.rules {
                                ForEach(Array(rules.enumerated()), id: \.offset) { _, rule in
                                    if let host = rule.host {
                                        HStack(spacing: 4) {
                                            Image(systemName: "globe").font(.caption2).foregroundStyle(.green)
                                            Text(host).font(.caption2.monospaced())
                                            if ing.spec?.tls != nil {
                                                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.24), value: appeared)
    }

    // MARK: - Storage

    private var storageSection: some View {
        GroupBox("Persistent Volume Claims (\(vm.pvcs.count))") {
            VStack(spacing: 4) {
                ForEach(vm.pvcs) { pvc in
                    HStack(spacing: 8) {
                        Image(systemName: pvc.phase == "Bound" ? "cylinder.fill" : "cylinder")
                            .font(.caption).foregroundStyle(pvc.phase == "Bound" ? .green : .orange)
                        Text(pvc.name).font(.caption.weight(.medium))
                        Text(pvc.namespace).font(.caption2).foregroundStyle(.tertiary)
                        Spacer()
                        Text(pvc.capacity).font(.caption2.monospaced())
                        StatusBadge(status: pvc.phase)
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.26), value: appeared)
    }

    // MARK: - Namespaces

    private var namespacesSection: some View {
        GroupBox("Namespaces (\(vm.namespaces.count))") {
            VStack(spacing: 4) {
                ForEach(vm.namespaces) { ns in
                    HStack(spacing: 8) {
                        Image(systemName: "folder").font(.caption).foregroundStyle(.blue)
                        Text(ns.name).font(.caption.weight(.medium))
                        Spacer()
                        StatusBadge(status: ns.phase)
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.28), value: appeared)
    }

    // MARK: - Info

    private var infoSection: some View {
        GroupBox("Cluster Info") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("API Endpoint", cluster.apiEndpoint ?? "—")
                    .help("Kubernetes API server address")
                infoRow("Master IP", cluster.masterIp ?? "—")
                    .help("Control plane IP address")
                infoRow("DNS", cluster.dnsEntry ?? "—")
                infoRow("CNI Plugin", cluster.cniPlugin ?? "—")
                    .help("Container Network Interface")
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
                        Button {
                            Task {
                                if vm.k8sNodes.isEmpty {
                                    await vm.connectToCluster(cluster.id)
                                    await vm.loadNodes()
                                }
                                if let node = vm.k8sNodes.first(where: { $0.name == name }) {
                                    vm.selectedNode = node
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "desktopcomputer")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(name)
                                    .font(.caption.monospaced())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Node Labels")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if vm.isK8sConnected {
                        Button {
                            editingLabelsPool = pool
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                let nodeLabels = labelsForPool(pool)
                if !nodeLabels.isEmpty {
                    ForEach(Array(nodeLabels.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        Text("\(key)=\(value)")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                } else if vm.isK8sConnected {
                    Text("No custom labels")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Connect to K8s API to view labels")
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

    private func labelsForPool(_ pool: CivoNodePool) -> [String: String] {
        guard let instanceNames = pool.instanceNames else { return [:] }
        // Find K8s nodes matching this pool's instances and collect their labels
        var allLabels: [String: String] = [:]
        let systemPrefixes = ["beta.kubernetes.io", "kubernetes.io", "node.kubernetes.io", "k3s.io"]
        for name in instanceNames {
            if let node = vm.k8sNodes.first(where: { $0.name == name }),
               let labels = node.metadata.labels {
                for (key, value) in labels {
                    if !systemPrefixes.contains(where: { key.hasPrefix($0) }) {
                        allLabels[key] = value
                    }
                }
            }
        }
        return allLabels
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
