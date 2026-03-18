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
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Firewalls")
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
            if vm.isLoading && vm.firewalls.isEmpty {
                ProgressView("Loading firewalls...")
            }
        }
    }
}
