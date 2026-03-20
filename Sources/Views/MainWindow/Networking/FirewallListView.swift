import SwiftUI

struct FirewallListView: View {
    @Bindable var vm: NetworkViewModel

    var body: some View {
        List {
            if vm.firewalls.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "shield", title: "No Firewalls", message: "No firewalls found in your account.")
            } else {
                ForEach(vm.firewalls) { fw in
                    ResourceListRow(
                        icon: "shield",
                        name: fw.name,
                        subtitle: "\(fw.rulesCountInt) rules"
                    )
                }
            }
        }
        .animation(.easeOut, value: vm.firewalls.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Firewalls")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    vm.isCreatingFirewall = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
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
            if vm.isLoading && vm.firewalls.isEmpty {
                ProgressView("Loading firewalls...")
            }
        }
        .overlay {
            SuccessOverlay(isPresented: $vm.showSuccess)
        }
        .sheet(isPresented: $vm.isCreatingFirewall) {
            CreateFirewallView(vm: vm)
                .frame(minWidth: 400, minHeight: 200)
        }
    }
}
