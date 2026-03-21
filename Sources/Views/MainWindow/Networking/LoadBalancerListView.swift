import SwiftUI

struct LoadBalancerListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoLoadBalancer?

    var body: some View {
        List {
            if vm.loadBalancers.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "arrow.triangle.branch", title: "No Load Balancers", message: "No load balancers found in your account.")
            } else {
                ForEach(Array(vm.loadBalancers.enumerated()), id: \.element.id) { index, lb in
                    ResourceListRow(
                        icon: "arrow.triangle.branch",
                        name: lb.name,
                        subtitle: "\(lb.algorithm ?? "—") — \(lb.publicIp ?? "no public IP") — \(lb.backendList.count) backends",
                        status: lb.state,
                        index: index
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
                Button { Task { await vm.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.loadBalancers.isEmpty { ProgressView("Loading load balancers...") }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Load Balancer",
                    resourceName: target.name,
                    onConfirm: {
                        Task { await vm.removeLoadBalancer(target.id) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil }
                )
            }
        }
    }
}
