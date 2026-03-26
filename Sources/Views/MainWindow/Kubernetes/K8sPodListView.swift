import SwiftUI

struct K8sPodListView: View {
    let nodeName: String
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var execPod: K8sPod?

    var body: some View {
        List {
            if vm.nodePods.isEmpty && !vm.isLoadingK8s {
                EmptyStateView(icon: "square.grid.2x2", title: "No Pods", message: "No pods running on this node.")
            } else {
                ForEach(Array(vm.nodePods.enumerated()), id: \.element.id) { index, pod in
                    Button {
                        vm.selectedPod = pod
                        Task {
                            await vm.loadPodLog(namespace: pod.namespace, pod: pod.name)
                        }
                    } label: {
                        podRow(pod, index: index)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Execute Command") {
                            execPod = pod
                        }
                        Divider()
                        Button("Restart Pod") {
                            Task { await vm.restartPod(namespace: pod.namespace, name: pod.name, nodeName: nodeName) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pods on \(nodeName)")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await vm.loadPods(nodeName: nodeName) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoadingK8s)
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.k8sError { ErrorBanner(message: error) }
        }
        .overlay {
            if vm.isLoadingK8s && vm.nodePods.isEmpty { ProgressView("Loading pods...") }
        }
        .sheet(item: $execPod) { pod in
            PodExecView(pod: pod, vm: vm) {
                execPod = nil
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }

    private func podRow(_ pod: K8sPod, index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon(pod))
                .font(.title3)
                .foregroundStyle(statusColor(pod))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(pod.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 8) {
                    if let ns = pod.metadata.labels?["namespace"] ?? pod.spec?.namespace {
                        Label(ns, systemImage: "folder")
                    }
                    if let containers = pod.status?.containerStatuses {
                        let ready = containers.filter { $0.ready == true }.count
                        Label("\(ready)/\(containers.count) ready", systemImage: "square.stack.3d.up")
                    }
                    if let restarts = pod.status?.containerStatuses?.reduce(0, { $0 + ($1.restartCount ?? 0) }), restarts > 0 {
                        Label("\(restarts) restarts", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(status: pod.status?.phase ?? "Unknown")
        }
        .padding(.vertical, 4)
        .modifier(StaggeredAppear(index: index))
    }

    private func statusIcon(_ pod: K8sPod) -> String {
        switch pod.status?.phase?.lowercased() {
        case "running": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "succeeded": return "checkmark.seal.fill"
        case "failed": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private func statusColor(_ pod: K8sPod) -> Color {
        switch pod.status?.phase?.lowercased() {
        case "running": return .green
        case "pending": return .orange
        case "succeeded": return .blue
        case "failed": return .red
        default: return .secondary
        }
    }
}
