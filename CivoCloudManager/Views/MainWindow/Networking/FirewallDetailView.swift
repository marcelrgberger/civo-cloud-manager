import SwiftUI

struct FirewallDetailView: View {
    let firewall: CivoFirewall
    @Bindable var vm: NetworkViewModel
    let onBack: () -> Void
    @Environment(FirewallClosureQueue.self) private var firewallClosures
    @State private var deleteTarget: CivoRule?
    @State private var editor = FirewallRuleEditor()

    var body: some View {
        List {
            if vm.rules.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "shield.slash", title: "No Rules", message: "No firewall rules configured.")
            } else {
                ForEach(Array(vm.rules.enumerated()), id: \.element.id) { index, rule in
                    ruleRow(rule, index: index)
                        .contextMenu {
                            Button("Edit Rule") {
                                editor.begin(
                                    editing: rule, of: firewall, region: vm.rulesRegion,
                                    account: vm.rulesAccount, isScheduledForClosure: isScheduledForClosure
                                )
                            }
                            .disabled(editability(of: rule) != .editable)
                            Button("Delete", role: .destructive) {
                                deleteTarget = rule
                            }
                        }
                }
            }
        }
        .animation(.easeOut, value: vm.rules.map(\.id))
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                if let error = vm.error { ErrorBanner(message: error) }
                if let notice = editor.notice { ErrorBanner(message: notice) }
            }
        }
        .navigationTitle(firewall.name)
        .task { await vm.loadRules(firewall.id) }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.backward") { onBack() }
                    .help("Return to list")
            }
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingRule = true } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .help("Create new rule")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.loadRules(firewall.id) } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Reload data from API")
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.rules.isEmpty {
                ProgressView("Loading rules...")
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingRule) {
            CreateRuleView(vm: vm, firewallId: firewall.id)
                .frame(minWidth: 450, minHeight: 350)
        }
        .sheet(isPresented: Binding(get: { editor.session != nil }, set: { if !$0 { editor.cancel() } })) {
            if let session = editor.session {
                EditRuleView(editor: editor, session: session) { draft in
                    Task { await save(draft) }
                }
                .frame(minWidth: 480, minHeight: 460)
            }
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Firewall Rule",
                    resourceName: target.label ?? "\(target.startPort ?? target.ports ?? "?") \(target.direction ?? "")",
                    onConfirm: {
                        Task { await vm.deleteRule(firewall.id, ruleId: target.id) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil }
                )
            }
        }
    }

    private func ruleRow(_ rule: CivoRule, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rule.action == "allow" ? "checkmark.shield" : "xmark.shield")
                .font(.title3)
                .foregroundStyle(rule.action == "allow" ? .green : .red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(portDisplay(rule))
                        .font(.body.weight(.medium))
                    Text(rule.direction ?? "—")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rule.direction == "ingress" ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                        .help("Traffic direction")
                    Text(rule.action ?? "—")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rule.action == "allow" ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .clipShape(Capsule())
                        .help("Rule action")
                }
                HStack(spacing: 8) {
                    if let cidr = rule.cidr {
                        Label(cidr, systemImage: "network")
                    }
                    if let label = rule.label, !label.isEmpty {
                        Label(label, systemImage: "tag")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let reason = editability(of: rule).message {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                    .help(reason)
                    .accessibilityLabel(reason)
            }
        }
        .padding(.vertical, 4)
        .modifier(StaggeredAppear(index: index))
    }

    private func isScheduledForClosure(firewallId: String, ruleId: String) -> Bool {
        firewallClosures.jobs.contains { $0.firewallId == firewallId && $0.ruleId == ruleId }
    }

    private func editability(of rule: CivoRule) -> FirewallRuleEditability {
        FirewallRuleEditability(rule: rule, isScheduledForClosure: isScheduledForClosure(firewallId: firewall.id, ruleId: rule.id))
    }

    private func save(_ draft: FirewallRuleDraft) async {
        guard let outcome = await editor.save(draft, isScheduledForClosure: isScheduledForClosure) else { return }
        if outcome == .saved { vm.showSuccess = true }
        await vm.loadRules(firewall.id)
    }

    private func portDisplay(_ rule: CivoRule) -> String {
        if let ports = rule.ports, !ports.isEmpty { return ports }
        guard let start = rule.startPort else { return "—" }
        if let end = rule.endPort, !end.isEmpty, end != start {
            return "\(start)-\(end)"
        }
        return start
    }
}
