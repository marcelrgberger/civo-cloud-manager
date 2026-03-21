import SwiftUI
import AppKit

struct ClusterListView: View {
    @Bindable var vm: KubernetesViewModel

    var body: some View {
        Group {
            if let pod = vm.selectedPod {
                PodLogView(pod: pod, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedPod = nil
                        vm.podLog = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if vm.selectedNode != nil && !vm.nodePods.isEmpty {
                K8sPodListView(nodeName: vm.selectedNode!.name, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.nodePods = []
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let node = vm.selectedNode {
                K8sNodeDetailView(node: node, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedNode = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let cluster = vm.selectedCluster {
                ClusterDetailView(cluster: cluster, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedCluster = nil
                        vm.k8sNodes = []
                        vm.k8sError = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                clusterList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: navigationKey)
        .task { await vm.refresh() }
        .toolbar {
            if vm.selectedCluster != nil && vm.selectedNode == nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await saveKubeconfig() }
                    } label: {
                        Label("Save Kubeconfig", systemImage: "arrow.down.doc")
                    }
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreating = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreating) {
            CreateClusterView(vm: vm).frame(minWidth: 500, minHeight: 400)
        }
    }

    private var navigationKey: String {
        if vm.selectedPod != nil { return "podLog" }
        if !vm.nodePods.isEmpty { return "podList" }
        if vm.selectedNode != nil { return "nodeDetail" }
        if vm.selectedCluster != nil { return "clusterDetail" }
        return "list"
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
            if vm.isLoading && vm.clusters.isEmpty { ProgressView("Loading clusters...") }
        }
    }

    private func saveKubeconfig() async {
        guard let cluster = vm.selectedCluster else { return }
        guard let yaml = await vm.saveKubeconfig(cluster.id) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(cluster.name)-kubeconfig.yaml"
        panel.allowedContentTypes = [.yaml]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try yaml.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                vm.error = error.localizedDescription
            }
        }
    }
}
