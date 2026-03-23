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
                    K8sConnectingView()
                }
                infoSection
                if !vm.events.isEmpty { eventsSection }
                if vm.isK8sConnected && !vm.namespaces.isEmpty {
                    namespaceFilterPicker
                }
                if !vm.deployments.isEmpty || !vm.daemonSets.isEmpty || !vm.statefulSets.isEmpty {
                    workloadsSection
                }
                if !vm.services.isEmpty || !vm.ingresses.isEmpty { networkingSection }
                if !vm.configMaps.isEmpty || !vm.secrets.isEmpty { configSection }
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

    // MARK: - Namespace Filter

    private var namespaceFilterPicker: some View {
        HStack {
            Text("Filter by Namespace:")
                .font(.caption).foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: { vm.selectedNamespace ?? "All" },
                set: { vm.selectedNamespace = $0 == "All" ? nil : $0 }
            )) {
                Text("All").tag("All")
                ForEach(vm.namespaces) { ns in
                    Text(ns.name).tag(ns.name)
                }
            }
            .frame(width: 200)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.18), value: appeared)
    }

    // MARK: - Live Metrics

    private func liveMetricsRow(_ metrics: K8sClusterMetrics) -> some View {
        HStack(spacing: 16) {
            liveGauge("CPU", percent: metrics.cpuPercent,
                      detail: String(format: "%.1f / %.1f cores", metrics.cpuUsage, metrics.cpuCapacity),
                      color: metrics.cpuPercent > 0.8 ? .red : metrics.cpuPercent > 0.6 ? .orange : .blue, index: 0,
                      history: vm.cpuHistory)
            liveGauge("Memory", percent: metrics.memoryPercent,
                      detail: String(format: "%.0f / %.0f MB", metrics.memoryUsageMB, metrics.memoryCapacityMB),
                      color: metrics.memoryPercent > 0.8 ? .red : metrics.memoryPercent > 0.6 ? .orange : .purple, index: 1,
                      history: vm.memoryHistory)
            statCard("Pods", value: "\(metrics.podCount)/\(metrics.podCapacity)", icon: "square.grid.2x2",
                     color: .orange, index: 2)
            statCard("Nodes", value: "\(metrics.healthyNodes)/\(metrics.nodeCount)", icon: "square.stack.3d.up",
                     color: metrics.healthyNodes == metrics.nodeCount ? .green : .red, index: 3)
        }
    }

    private func liveGauge(_ title: String, percent: Double, detail: String, color: Color, index: Int, history: [Double] = []) -> some View {
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
            if history.count >= 2 {
                SparklineView(data: history, color: color, height: 20)
                    .padding(.horizontal, 4)
            }
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
                        if let ts = event.lastTimestamp {
                            Text(relativeTime(ts))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
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

    private func relativeTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return iso }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "\(Int(interval))s ago" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    // MARK: - Workloads

    private var workloadsSection: some View {
        GroupBox("Workloads") {
            VStack(spacing: 4) {
                if !vm.deployments.isEmpty {
                    DisclosureGroup("Deployments (\(vm.filteredDeployments.count))") {
                        ForEach(vm.filteredDeployments) { d in
                            workloadRow(d.name, ready: d.readyReplicas, desired: d.desiredReplicas, healthy: d.isHealthy, ns: d.namespace)
                                .contextMenu {
                                    Button {
                                        Task { await vm.restartDeployment(namespace: d.namespace, name: d.name) }
                                    } label: {
                                        Label("Restart Deployment", systemImage: "arrow.clockwise")
                                    }
                                }
                        }
                    }
                    .font(.caption.weight(.medium))
                }
                if !vm.daemonSets.isEmpty {
                    DisclosureGroup("DaemonSets (\(vm.daemonSets.count))") {
                        ForEach(vm.daemonSets) { d in
                            workloadRow(d.name, ready: d.ready, desired: d.desired, healthy: d.isHealthy, ns: d.namespace)
                        }
                    }
                    .font(.caption.weight(.medium))
                }
                if !vm.statefulSets.isEmpty {
                    DisclosureGroup("StatefulSets (\(vm.statefulSets.count))") {
                        ForEach(vm.statefulSets) { s in
                            workloadRow(s.name, ready: s.readyReplicas, desired: s.desiredReplicas, healthy: s.isHealthy, ns: s.namespace)
                        }
                    }
                    .font(.caption.weight(.medium))
                }
                if !vm.cronJobs.isEmpty {
                    DisclosureGroup("CronJobs (\(vm.cronJobs.count))") {
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
                    .font(.caption.weight(.medium))
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
            VStack(spacing: 4) {
                if !vm.services.isEmpty {
                    DisclosureGroup("Services (\(vm.filteredServices.count))") {
                        ForEach(vm.filteredServices) { svc in
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
                    .font(.caption.weight(.medium))
                }
                if !vm.ingresses.isEmpty {
                    DisclosureGroup("Ingresses (\(vm.filteredIngresses.count))") {
                        ForEach(vm.filteredIngresses) { ing in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.caption).foregroundStyle(.indigo)
                                    Text(ing.name).font(.caption.weight(.medium))
                                    Text(ing.namespace).font(.caption2).foregroundStyle(.tertiary)
                                    Spacer()
                                    if ing.spec?.tls != nil && !(ing.spec?.tls?.isEmpty ?? true) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                                            Text("TLS").font(.caption2.bold()).foregroundStyle(.green)
                                        }
                                        .padding(.horizontal, 5).padding(.vertical, 1)
                                        .background(.green.opacity(0.1)).clipShape(Capsule())
                                    } else {
                                        HStack(spacing: 2) {
                                            Image(systemName: "lock.open").font(.caption2).foregroundStyle(.orange)
                                            Text("No TLS").font(.caption2).foregroundStyle(.orange)
                                        }
                                        .padding(.horizontal, 5).padding(.vertical, 1)
                                        .background(.orange.opacity(0.1)).clipShape(Capsule())
                                    }
                                }
                                if let rules = ing.spec?.rules {
                                    ForEach(Array(rules.enumerated()), id: \.offset) { _, rule in
                                        VStack(alignment: .leading, spacing: 3) {
                                            if let host = rule.host {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "globe").font(.caption2).foregroundStyle(.blue)
                                                    let hasTLS = ing.spec?.tls?.contains(where: { $0.hosts?.contains(host) == true }) == true
                                                    let scheme = hasTLS ? "https" : "http"
                                                    let urlString = "\(scheme)://\(host)"
                                                    if let url = URL(string: urlString) {
                                                        Link(host, destination: url)
                                                            .font(.caption2.monospaced())
                                                            .foregroundStyle(.blue)
                                                            .help("Open \(urlString) in browser")
                                                    } else {
                                                        Text(host).font(.caption2.monospaced()).textSelection(.enabled)
                                                    }
                                                    if let tls = ing.spec?.tls, tls.contains(where: { $0.hosts?.contains(host) == true }) {
                                                        Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                                                        if let secretName = tls.first(where: { $0.hosts?.contains(host) == true })?.secretName {
                                                            Text(secretName).font(.caption2).foregroundStyle(.tertiary)
                                                        }
                                                    }
                                                }
                                            }
                                            if let paths = rule.http?.paths {
                                                ForEach(Array(paths.enumerated()), id: \.offset) { _, path in
                                                    HStack(spacing: 4) {
                                                        Text(path.path ?? "/")
                                                            .font(.caption2.monospaced())
                                                            .foregroundStyle(.secondary)
                                                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.tertiary)
                                                        if let svcName = path.backend?.service?.name {
                                                            Text(svcName).font(.caption2.weight(.medium)).foregroundStyle(.blue)
                                                        }
                                                        if let port = path.backend?.service?.port {
                                                            Text(":\(port.number.map { "\($0)" } ?? port.name ?? "—")")
                                                                .font(.caption2.monospaced()).foregroundStyle(.secondary)
                                                        }
                                                        if let pathType = path.pathType {
                                                            Text(pathType).font(.caption2).foregroundStyle(.tertiary)
                                                        }
                                                    }
                                                    .padding(.leading, 16)
                                                }
                                            }
                                        }
                                    }
                                }
                                // Show TLS details
                                if let tlsList = ing.spec?.tls, !tlsList.isEmpty {
                                    ForEach(Array(tlsList.enumerated()), id: \.offset) { _, tls in
                                        HStack(spacing: 4) {
                                            Image(systemName: "key.fill").font(.caption2).foregroundStyle(.green)
                                            Text("Secret:").font(.caption2).foregroundStyle(.secondary)
                                            Text(tls.secretName ?? "—").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                                            if let hosts = tls.hosts, !hosts.isEmpty {
                                                Text("(\(hosts.joined(separator: ", ")))").font(.caption2).foregroundStyle(.tertiary)
                                            }
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .font(.caption.weight(.medium))
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.24), value: appeared)
    }

    // MARK: - ConfigMaps & Secrets

    private var configSection: some View {
        GroupBox("Configuration") {
            VStack(spacing: 4) {
                if !vm.configMaps.isEmpty {
                    DisclosureGroup("ConfigMaps (\(vm.filteredConfigMaps.count))") {
                        ForEach(vm.filteredConfigMaps) { cm in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.text")
                                        .font(.caption).foregroundStyle(.teal)
                                    Text(cm.name).font(.caption.weight(.medium))
                                    Text(cm.namespace).font(.caption2).foregroundStyle(.tertiary)
                                    Spacer()
                                    Text("\(cm.dataEntries.count) key\(cm.dataEntries.count == 1 ? "" : "s")")
                                        .font(.caption2.monospaced()).foregroundStyle(.secondary)
                                }
                                if !cm.dataEntries.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(Array(cm.dataEntries.keys.sorted().prefix(5)), id: \.self) { key in
                                            Text(key)
                                                .font(.caption2.monospaced())
                                                .padding(.horizontal, 4).padding(.vertical, 1)
                                                .background(.teal.opacity(0.1)).clipShape(Capsule())
                                        }
                                        if cm.dataEntries.count > 5 {
                                            Text("+\(cm.dataEntries.count - 5)")
                                                .font(.caption2).foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(.leading, 24)
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                    .font(.caption.weight(.medium))
                }
                if !vm.secrets.isEmpty {
                    DisclosureGroup("Secrets (\(vm.filteredSecrets.count))") {
                        ForEach(vm.filteredSecrets) { secret in
                            HStack(spacing: 8) {
                                Image(systemName: "key")
                                    .font(.caption).foregroundStyle(.yellow)
                                Text(secret.name).font(.caption.weight(.medium))
                                Text(secret.namespace).font(.caption2).foregroundStyle(.tertiary)
                                Spacer()
                                Text(secret.secretType)
                                    .font(.caption2)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(.yellow.opacity(0.1)).clipShape(Capsule())
                                Text("\(secret.dataKeys.count) key\(secret.dataKeys.count == 1 ? "" : "s")")
                                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.caption.weight(.medium))
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
    }

    // MARK: - Storage

    private var storageSection: some View {
        GroupBox("Storage") {
            VStack(spacing: 4) {
                DisclosureGroup("Persistent Volume Claims (\(vm.pvcs.count))") {
                    ForEach(vm.pvcs) { pvc in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: pvc.phase == "Bound" ? "cylinder.fill" : "cylinder")
                                    .font(.caption).foregroundStyle(pvc.phase == "Bound" ? .green : .orange)
                                Text(pvc.name).font(.caption.weight(.medium))
                                Text(pvc.namespace).font(.caption2).foregroundStyle(.tertiary)
                                Spacer()
                                Text(pvc.capacity).font(.caption2.monospaced())
                                StatusBadge(status: pvc.phase)
                            }
                            if let civoId = vm.civoVolumeIdForPVC(pvc) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.caption2).foregroundStyle(.blue)
                                    Text("Civo Volume:")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(civoId)
                                        .font(.caption2.monospaced()).foregroundStyle(.blue)
                                        .textSelection(.enabled)
                                }
                                .padding(.leading, 24)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
                .font(.caption.weight(.medium))

                if !vm.pvs.isEmpty {
                    DisclosureGroup("Persistent Volumes (\(vm.pvs.count))") {
                        ForEach(vm.pvs) { pv in
                            HStack(spacing: 8) {
                                Image(systemName: "externaldrive.connected.to.line.below")
                                    .font(.caption).foregroundStyle(.blue)
                                Text(pv.name).font(.caption.weight(.medium)).lineLimit(1)
                                Spacer()
                                Text(pv.capacity).font(.caption2.monospaced())
                                if let civoId = pv.civoVolumeId {
                                    Text(civoId.prefix(8) + "...")
                                        .font(.caption2.monospaced()).foregroundStyle(.tertiary)
                                }
                                StatusBadge(status: pv.status?.phase ?? "—")
                            }
                        }
                    }
                    .font(.caption.weight(.medium))
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
