import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case instances = "Instances"
    case sshKeys = "SSH Keys"
    case clusters = "Kubernetes"
    case networks = "Networks"
    case firewalls = "Firewalls"
    case loadBalancers = "Load Balancers"
    case domains = "Domains"
    case databases = "Databases"
    case volumes = "Volumes"
    case objectStores = "Object Stores"
    case credentials = "Credentials"
    case costs = "Cost Estimate"
    case apiHealth = "API Health"
    case regions = "Regions"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .instances: return "desktopcomputer"
        case .sshKeys: return "key"
        case .clusters: return "helm"
        case .networks: return "point.3.connected.trianglepath.dotted"
        case .firewalls: return "shield"
        case .loadBalancers: return "arrow.triangle.branch"
        case .domains: return "globe"
        case .databases: return "cylinder.split.1x2"
        case .volumes: return "cylinder"
        case .objectStores: return "tray.2"
        case .credentials: return "key.horizontal"
        case .costs: return "dollarsign.circle"
        case .apiHealth: return "waveform.path.ecg"
        case .regions: return "map"
        case .about: return "info.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .dashboard: return .blue
        case .instances: return .green
        case .sshKeys: return .orange
        case .clusters: return .blue
        case .networks: return .green
        case .firewalls: return .red
        case .loadBalancers: return .indigo
        case .domains: return .teal
        case .databases: return .purple
        case .volumes: return .orange
        case .objectStores: return .cyan
        case .credentials: return .yellow
        case .costs: return .green
        case .apiHealth: return .pink
        case .regions: return .mint
        case .about: return .secondary
        }
    }

    var category: SidebarCategory {
        switch self {
        case .dashboard: return .overview
        case .instances, .sshKeys: return .compute
        case .clusters: return .kubernetes
        case .networks, .firewalls, .loadBalancers, .domains: return .networking
        case .databases, .volumes, .objectStores, .credentials: return .storage
        case .costs: return .account
        case .apiHealth: return .account
        case .regions: return .account
        case .about: return .account
        }
    }
}

enum SidebarCategory: String, CaseIterable {
    case overview = "Overview"
    case compute = "Compute"
    case kubernetes = "Kubernetes"
    case networking = "Networking"
    case storage = "Storage & Data"
    case account = "Account"

    var sections: [SidebarSection] {
        SidebarSection.allCases.filter { $0.category == self }
    }
}

struct MainWindowView: View {
    @State private var store = StoreManager.shared
    @State private var selection: SidebarSection = .dashboard
    @State private var showSearch = false
    @State private var showExport = false
    @State private var dashboardVM = DashboardViewModel()
    @State private var kubernetesVM = KubernetesViewModel()
    @State private var databaseVM = DatabaseViewModel()
    @State private var networkVM = NetworkViewModel()
    @State private var volumeVM = VolumeViewModel()
    @State private var instanceVM = InstanceViewModel()
    @State private var domainVM = DomainViewModel()
    @State private var regionVM = RegionViewModel()

    var body: some View {
        Group {
            if store.isFullAccessUnlocked {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detailView
                        .contentTransition(.opacity)
                        .animation(.spring(duration: 0.3, bounce: 0.1), value: selection)
                }
                .sheet(isPresented: $showSearch) {
                    QuickSearchView(
                        isPresented: $showSearch,
                        selection: $selection,
                        instanceVM: instanceVM,
                        kubernetesVM: kubernetesVM,
                        databaseVM: databaseVM,
                        networkVM: networkVM,
                        volumeVM: volumeVM,
                        domainVM: domainVM
                    )
                }
                .sheet(isPresented: $showExport) {
                    ExportView(
                        instanceVM: instanceVM,
                        kubernetesVM: kubernetesVM,
                        databaseVM: databaseVM,
                        networkVM: networkVM,
                        volumeVM: volumeVM,
                        domainVM: domainVM
                    )
                }
                .background {
                    Button("") { showSearch = true }
                        .keyboardShortcut("k", modifiers: .command)
                        .hidden()
                    Button("") { showExport = true }
                        .keyboardShortcut("e", modifiers: [.command, .shift])
                        .hidden()
                }
                .overlay(alignment: .bottomTrailing) {
                    // TEMP: paywall debug — remove after investigation
                    Text(store.isDebugBuild ? "⚠️ DEBUG BUILD" : "✅ RELEASE (ids: \(store.purchasedProductIDs.joined(separator: ",")))")
                        .font(.caption2.monospaced())
                        .padding(4)
                        .background(.black.opacity(0.7))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                }
            } else {
                PaywallView()
            }
        }
        .navigationTitle("")
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await store.refreshPurchaseStatus()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SidebarCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(category.sections) { section in
                        Label {
                            Text(section.rawValue)
                        } icon: {
                            Image(systemName: section.icon)
                                .foregroundStyle(section.iconColor)
                        }
                        .tag(section)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView(vm: dashboardVM, selection: $selection)
        case .instances:
            InstanceListView(vm: instanceVM)
        case .sshKeys:
            SSHKeyListView(vm: instanceVM)
        case .clusters:
            ClusterListView(vm: kubernetesVM)
        case .networks:
            NetworkListView(vm: networkVM)
        case .firewalls:
            FirewallListView(vm: networkVM)
        case .loadBalancers:
            LoadBalancerListView(vm: networkVM)
        case .domains:
            DomainListView(vm: domainVM)
        case .databases:
            DatabaseListView(vm: databaseVM)
        case .volumes:
            VolumeListView(vm: volumeVM)
        case .objectStores:
            ObjectStoreListView(vm: volumeVM)
        case .credentials:
            CredentialListView(vm: volumeVM)
        case .apiHealth:
            APIHealthView()
        case .costs:
            CostDashboardView(
                instanceVM: instanceVM,
                kubernetesVM: kubernetesVM,
                databaseVM: databaseVM,
                volumeVM: volumeVM
            )
        case .regions:
            RegionListView(vm: regionVM)
        case .about:
            AboutView()
        }
    }
}
