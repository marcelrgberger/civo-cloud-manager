import SwiftUI

struct ClusterListView: View {
    @Bindable var vm: KubernetesViewModel

    var body: some View {
        Group {
            if let cluster = vm.selectedCluster {
                ClusterDetailView(cluster: cluster, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedCluster = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                clusterList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedCluster?.id)
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    vm.isCreating = true
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
            SuccessOverlay(isPresented: $vm.showSuccess)
        }
        .sheet(isPresented: $vm.isCreating) {
            CreateClusterView(vm: vm)
                .frame(minWidth: 500, minHeight: 400)
        }
    }

    private var clusterList: some View {
        List {
            if vm.clusters.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "helm", title: "No Clusters", message: "No Kubernetes clusters found in your account.")
            } else {
                ForEach(Array(vm.clusters.enumerated()), id: \.element.id) { index, cluster in
                    Button {
                        Task { await vm.loadClusterDetail(cluster.id) }
                    } label: {
                        ResourceListRow(
                            icon: "helm",
                            name: cluster.name,
                            subtitle: "\(cluster.clusterType ?? "k3s") — \(cluster.numTargetNodes ?? 0) nodes",
                            status: cluster.status,
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.easeOut, value: vm.clusters.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Kubernetes Clusters")
        .overlay {
            if vm.isLoading && vm.clusters.isEmpty {
                ProgressView("Loading clusters...")
            }
        }
    }
}
