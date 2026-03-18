import SwiftUI

struct ClusterListView: View {
    @Bindable var vm: KubernetesViewModel

    var body: some View {
        Group {
            if vm.selectedCluster != nil {
                ClusterDetailView(cluster: vm.selectedCluster!, vm: vm) {
                    vm.selectedCluster = nil
                }
            } else {
                clusterList
            }
        }
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
    }

    private var clusterList: some View {
        List {
            if vm.clusters.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "helm", title: "No Clusters", message: "No Kubernetes clusters found in your account.")
            } else {
                ForEach(vm.clusters) { cluster in
                    Button {
                        Task { await vm.loadClusterDetail(cluster.id) }
                    } label: {
                        ResourceListRow(
                            icon: "helm",
                            name: cluster.name,
                            subtitle: "\(cluster.clusterType ?? "k3s") — \(cluster.numTargetNodes ?? 0) nodes",
                            status: cluster.status
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
