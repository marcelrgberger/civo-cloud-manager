import SwiftUI

struct DomainListView: View {
    @Bindable var vm: DomainViewModel

    var body: some View {
        List {
            if vm.domains.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "globe", title: "No Domains", message: "No domains found in your account.")
            } else {
                ForEach(vm.domains) { domain in
                    ResourceListRow(
                        icon: "globe",
                        name: domain.name
                    )
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Domains")
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
            if vm.isLoading && vm.domains.isEmpty {
                ProgressView("Loading domains...")
            }
        }
    }
}
