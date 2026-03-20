import SwiftUI

struct DashboardView: View {
    @Bindable var vm: DashboardViewModel
    @Binding var selection: SidebarSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                resourceCountsSection
                if let quota = vm.quota {
                    quotaSection(quota)
                }
            }
            .padding(24)
        }
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await vm.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.quota == nil {
                ProgressView("Loading dashboard...")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dashboard")
                .font(.largeTitle.bold())
            if let error = vm.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            ForEach(vm.warnings, id: \.self) { warning in
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var resourceCountsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
            resourceCard("Kubernetes Clusters", count: vm.clusterCount, icon: "helm", color: .blue, target: .clusters)
            resourceCard("Databases", count: vm.databaseCount, icon: "cylinder.split.1x2", color: .purple, target: .databases)
            resourceCard("Volumes", count: vm.volumeCount, icon: "cylinder", color: .orange, target: .volumes)
            resourceCard("Object Stores", count: vm.objectStoreCount, icon: "tray.2", color: .teal, target: .objectStores)
            resourceCard("Load Balancers", count: vm.loadBalancerCount, icon: "arrow.triangle.branch", color: .indigo, target: .loadBalancers)
            resourceCard("Networks", count: vm.networkCount, icon: "point.3.connected.trianglepath.dotted", color: .green, target: .networks)
        }
    }

    @State private var hoveredCard: SidebarSection?

    private func resourceCard(_ title: String, count: Int?, icon: String, color: Color, target: SidebarSection) -> some View {
        Button {
            selection = target
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                    if let count {
                        Text("\(count)")
                            .font(.system(.title, design: .rounded).bold())
                            .contentTransition(.numericText())
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(16)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .scaleEffect(hoveredCard == target ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: hoveredCard)
        .onHover { isHovered in
            hoveredCard = isHovered ? target : nil
        }
        .animation(.easeOut(duration: 0.3), value: count)
    }

    private func quotaSection(_ quota: CivoQuota) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quota Usage")
                .font(.title2.bold())

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 20) {
                ForEach(quota.items) { item in
                    QuotaGauge(item: item)
                }
            }
        }
    }
}
