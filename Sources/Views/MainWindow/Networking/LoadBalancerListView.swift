import SwiftUI

struct LoadBalancerListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoLoadBalancer?

    var body: some View {
        Group {
            if let lb = vm.selectedLoadBalancer {
                LoadBalancerDetailView(lb: lb) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedLoadBalancer = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                lbList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedLoadBalancer?.id)
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
    }

    private var lbList: some View {
        List {
            if vm.loadBalancers.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "arrow.triangle.branch", title: "No Load Balancers", message: "No load balancers found in your account.")
            } else {
                ForEach(Array(vm.loadBalancers.enumerated()), id: \.element.id) { index, lb in
                    Button {
                        vm.selectedLoadBalancer = lb
                    } label: {
                        ResourceListRow(
                            icon: "arrow.triangle.branch",
                            name: lb.name,
                            subtitle: "\(lb.algorithm ?? "—") — \(lb.publicIp ?? "no public IP") — \(lb.backendList.count) backends",
                            status: lb.state,
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) { deleteTarget = lb }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.loadBalancers.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Load Balancers")
        .overlay { if vm.isLoading && vm.loadBalancers.isEmpty { ProgressView("Loading load balancers...") } }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Load Balancer", resourceName: target.name, onConfirm: {
                    Task { await vm.removeLoadBalancer(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }
}
