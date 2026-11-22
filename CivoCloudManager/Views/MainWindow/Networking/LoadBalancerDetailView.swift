import SwiftUI

struct LoadBalancerDetailView: View {
    let lb: CivoLoadBalancer
    @Bindable var vm: NetworkViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var editor = LoadBalancerEditor()

    private var editability: LoadBalancerEditability { LoadBalancerEditability(lb) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let reason = editability.message {
                    Label(reason, systemImage: "lock")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                networkSection
                configSection
                backendsSection
            }
            .padding(24)
        }
        .safeAreaInset(edge: .top) {
            if let notice = editor.notice { ErrorBanner(message: notice) }
        }
        .navigationTitle(lb.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.backward") { onBack() }
                    .help("Return to list")
            }
            if editability == .editable {
                ToolbarItem(placement: .automatic) {
                    Button("Edit", systemImage: "pencil") {
                        editor.begin(editing: lb, context: vm.selectedLoadBalancerContext)
                    }
                    .help("Edit Load Balancer")
                    .disabled(editor.isSaving)
                }
            }
        }
        .sheet(isPresented: Binding(get: { editor.session != nil }, set: { if !$0 { editor.cancel() } })) {
            if let session = editor.session {
                EditLoadBalancerView(editor: editor, session: session) { draft in
                    Task { await save(draft, in: session.target) }
                }
                .frame(minWidth: 620, minHeight: 560)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lb.name)
                    .font(.largeTitle.bold())
                Text(lb.algorithm ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: lb.state ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var networkSection: some View {
        GroupBox("Network") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Public IP", lb.publicIp ?? "—")
                infoRow("Private IP", lb.privateIp ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Configuration") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Algorithm", lb.algorithm.map(LoadBalancerAlgorithm.title(of:)) ?? "-")
                infoRow("Traffic Policy", lb.externalTrafficPolicy ?? "—")
                infoRow("Network ID", lb.networkId ?? "-")
                infoRow("Cluster ID", lb.clusterId ?? "—")
                infoRow("Firewall ID", lb.firewallId ?? "—")
                infoRow("Created", lb.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private var backendsSection: some View {
        GroupBox("Backends (\(lb.backendList.count))") {
            Group {
                if lb.backendList.isEmpty {
                    Text("No backends configured")
                        .foregroundStyle(.secondary)
                } else if let entries = lb.backendEntries {
                    LoadBalancerBackendTable(existing: entries, rows: .constant([]), allowsAdding: false)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(lb.backendList.enumerated()), id: \.offset) { index, backend in
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(.blue)
                                Text(verbatim: backend)
                                    .font(.subheadline.monospaced())
                                    .textSelection(.enabled)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .modifier(StaggeredAppear(index: index))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private func save(_ draft: LoadBalancerDraft, in target: LoadBalancerTarget) async {
        guard let outcome = await editor.save(draft) else { return }
        if case .saved(let confirmed) = outcome {
            vm.replaceSelectedLoadBalancer(with: confirmed, editedIn: target.context)
            vm.showSuccess = true
        }
        if outcome != .cancelled { await vm.refresh() }
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
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
