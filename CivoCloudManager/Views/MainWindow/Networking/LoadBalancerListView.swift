import SwiftUI

struct LoadBalancerListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoLoadBalancer?

    var body: some View {
        Group {
            if let lb = vm.selectedLoadBalancer {
                LoadBalancerDetailView(lb: lb, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectLoadBalancer(nil)
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
                Button {
                    Task { await creator.beginForm() }
                } label: {
                    Label("New Load Balancer", systemImage: "plus")
                }
                .help("New Load Balancer")
                .disabled(creator.isSubmitting || creator.form != nil)
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload data from API")
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: Binding(get: { creator.form != nil }, set: { if !$0 { creator.endForm() } })) {
            CreateLoadBalancerView(creator: creator) { outcome in
                switch outcome {
                case .created:
                    vm.showSuccess = true
                    Task { await vm.refresh() }
                case .unknown:
                    Task { await vm.refresh() }
                case .refused, .rejected, .alreadyInFlight:
                    break
                }
            }
            .frame(minWidth: 620, minHeight: 560)
        }
    }

    private var creator: LoadBalancerCreateController { vm.loadBalancerCreator }

    private var lbList: some View {
        List {
            if vm.loadBalancers.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "arrow.triangle.branch", title: "No Load Balancers", message: "No load balancers found in your account.")
            } else {
                ForEach(Array(vm.loadBalancers.enumerated()), id: \.element.id) { index, lb in
                    Button {
                        vm.selectLoadBalancer(lb)
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
            VStack(spacing: 0) {
                if let error = vm.error { ErrorBanner(message: error) }
                ForEach(creator.unresolved(in: vm.loadBalancersContext)) { result in
                    HStack {
                        ErrorBanner(message: result.message)
                        Button("Dismiss") { creator.dismiss(result.id) }
                            .padding(.trailing, 8)
                    }
                }
            }
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
