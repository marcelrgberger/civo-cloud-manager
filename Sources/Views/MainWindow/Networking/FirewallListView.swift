import SwiftUI

struct FirewallListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoFirewall?

    var body: some View {
        Group {
            if let firewall = vm.selectedFirewall {
                FirewallDetailView(firewall: firewall, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedFirewall = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                firewallList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedFirewall?.id)
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingFirewall = true } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingFirewall) {
            CreateFirewallView(vm: vm)
                .frame(minWidth: 400, minHeight: 200)
        }
    }

    private var firewallList: some View {
        List {
            if vm.firewalls.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "shield", title: "No Firewalls", message: "No firewalls found in your account.")
            } else {
                ForEach(Array(vm.firewalls.enumerated()), id: \.element.id) { index, fw in
                    Button {
                        vm.selectedFirewall = fw
                    } label: {
                        ResourceListRow(
                            icon: "shield",
                            name: fw.name,
                            subtitle: "\(fw.rulesCountInt) rules",
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = fw
                        }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.firewalls.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Firewalls")
        .overlay {
            if vm.isLoading && vm.firewalls.isEmpty { ProgressView("Loading firewalls...") }
        }
        .sheet(isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Firewall",
                    resourceName: target.name,
                    onConfirm: {
                        Task { await vm.removeFirewall(target.id) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil }
                )
            }
        }
    }
}
