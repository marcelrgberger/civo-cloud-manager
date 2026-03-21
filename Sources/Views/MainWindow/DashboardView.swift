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
        .overlay {
            SuccessOverlay(isPresented: $vm.showSuccess)
        }
        .sheet(isPresented: $vm.isEditingQuota) {
            if let quota = vm.quota {
                QuotaEditView(vm: vm, currentQuota: quota)
                    .frame(minWidth: 500, minHeight: 500)
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
            resourceCard("Kubernetes Clusters", count: vm.clusterCount, icon: "helm", color: .blue, target: .clusters, index: 0)
            resourceCard("Databases", count: vm.databaseCount, icon: "cylinder.split.1x2", color: .purple, target: .databases, index: 1)
            resourceCard("Volumes", count: vm.volumeCount, icon: "cylinder", color: .orange, target: .volumes, index: 2)
            resourceCard("Object Stores", count: vm.objectStoreCount, icon: "tray.2", color: .teal, target: .objectStores, index: 3)
            resourceCard("Load Balancers", count: vm.loadBalancerCount, icon: "arrow.triangle.branch", color: .indigo, target: .loadBalancers, index: 4)
            resourceCard("Networks", count: vm.networkCount, icon: "point.3.connected.trianglepath.dotted", color: .green, target: .networks, index: 5)
        }
        .onAppear {
            withAnimation { cardsAppeared = true }
        }
    }

    @State private var hoveredCard: SidebarSection?
    @State private var cardsAppeared = false

    private static let cardTargets: [(String, String, Color, SidebarSection)] = [
        ("Kubernetes Clusters", "helm", .blue, .clusters),
        ("Databases", "cylinder.split.1x2", .purple, .databases),
        ("Volumes", "cylinder", .orange, .volumes),
        ("Object Stores", "tray.2", .teal, .objectStores),
        ("Load Balancers", "arrow.triangle.branch", .indigo, .loadBalancers),
        ("Networks", "point.3.connected.trianglepath.dotted", .green, .networks),
    ]

    private func resourceCard(_ title: String, count: Int?, icon: String, color: Color, target: SidebarSection, index: Int = 0) -> some View {
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
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 10)
        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05), value: cardsAppeared)
        .animation(.easeOut(duration: 0.3), value: count)
    }

    private func quotaSection(_ quota: CivoQuota) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quota Usage")
                    .font(.title2.bold())
                Spacer()
                Button {
                    vm.isEditingQuota = true
                } label: {
                    Label("Request Change", systemImage: "arrow.up.arrow.down")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 20) {
                ForEach(quota.items) { item in
                    QuotaGauge(item: item)
                }
            }
        }
    }
}
