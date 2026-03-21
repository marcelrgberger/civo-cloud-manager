import SwiftUI

struct FirewallDetailView: View {
    let firewall: CivoFirewall
    @Bindable var vm: NetworkViewModel
    let onBack: () -> Void
    @State private var deleteTarget: CivoRule?

    var body: some View {
        List {
            if vm.rules.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "shield.slash", title: "No Rules", message: "No firewall rules configured.")
            } else {
                ForEach(vm.rules) { rule in
                    ruleRow(rule)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                deleteTarget = rule
                            }
                        }
                }
            }
        }
        .animation(.easeOut, value: vm.rules.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle(firewall.name)
        .task { await vm.loadRules(firewall.id) }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingRule = true } label: {
                    Label("Add Rule", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.loadRules(firewall.id) } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
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

    private func ruleRow(_ rule: CivoRule) -> some View {
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
                    Text(rule.action ?? "—")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rule.action == "allow" ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .clipShape(Capsule())
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
        }
        .padding(.vertical, 4)
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
