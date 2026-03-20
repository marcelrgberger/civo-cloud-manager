import SwiftUI

struct LoadBalancerListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoLoadBalancer?

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
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = lb
                        }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.loadBalancers.map(\.id))
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
        .overlay {
            SuccessOverlay(isPresented: $vm.showSuccess)
        }
        .confirmationDialog("Delete Load Balancer", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeLoadBalancer(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the load balancer. This action cannot be undone.")
        }
    }
}
