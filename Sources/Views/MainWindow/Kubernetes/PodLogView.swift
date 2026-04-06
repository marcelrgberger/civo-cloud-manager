import SwiftUI

struct PodLogView: View {
    let pod: K8sPod
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void
    @State private var autoScroll = true
    @State private var autoRefresh = false
    @State private var refreshTimer: Timer?

    private var podNamespace: String { pod.namespace }

    var body: some View {
        VStack(spacing: 0) {
            logHeader
            Divider()
            logContent
        }
        .navigationTitle("Logs: \(pod.name)")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: autoRefresh) { _, on in
                        if on {
                            refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                                Task { @MainActor in
                                    await vm.loadPodLog(namespace: podNamespace, pod: pod.name)
                                }
                            }
                        } else {
                            refreshTimer?.invalidate()
                            refreshTimer = nil
                        }
                    }
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await vm.loadPodLog(namespace: podNamespace, pod: pod.name)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoadingK8s)
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private var logHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(pod.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let ns = pod.metadata.labels?["namespace"] ?? pod.spec?.namespace {
                        Text(ns)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    StatusBadge(status: pod.status?.phase ?? "Unknown")
                }
            }
            Spacer()
            if vm.isLoadingK8s {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
    }

    private var logContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if let log = vm.podLog, !log.isEmpty {
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .id("logBottom")
                } else if vm.isLoadingK8s {
                    ProgressView("Loading logs...")
                        .padding(40)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No logs available")
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                }
            }
            .onChange(of: vm.podLog) { _, _ in
                if autoScroll {
                    withAnimation {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.k8sError { ErrorBanner(message: error) }
        }
    }
}
