import SwiftUI

struct LoadBalancerListView: View {
    @Bindable var vm: NetworkViewModel

    var body: some View {
        List {
            if vm.loadBalancers.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "arrow.triangle.branch", title: "No Load Balancers", message: "No load balancers found in your account.")
            } else {
                ForEach(vm.loadBalancers) { lb in
                    ResourceListRow(
                        icon: "arrow.triangle.branch",
                        name: lb.name,
                        subtitle: "\(lb.algorithm ?? "—") — \(lb.publicIp ?? "no public IP") — \(lb.backendList.count) backends",
                        status: lb.state
                    )
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Load Balancers")
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
            if vm.isLoading && vm.loadBalancers.isEmpty {
                ProgressView("Loading load balancers...")
            }
        }
    }
}
