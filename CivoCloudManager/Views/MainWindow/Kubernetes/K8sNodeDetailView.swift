import SwiftUI

struct K8sNodeDetailView: View {
    let node: K8sNode
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                resourceSection
                conditionsSection
                addressesSection
                systemInfoSection
                podsButton
            }
            .padding(24)
        }
        .navigationTitle(node.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.name)
                    .font(.largeTitle.bold())
                if let created = node.metadata.creationTimestamp {
                    Text("Created: \(created)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let conditions = node.status?.conditions,
               let ready = conditions.first(where: { $0.type == "Ready" }) {
                StatusBadge(status: ready.status == "True" ? "Ready" : "NotReady")
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var resourceSection: some View {
        GroupBox("Resources") {
            HStack(spacing: 16) {
                resourceCard("CPU", capacity: node.status?.capacity?.cpu, allocatable: node.status?.allocatable?.cpu, icon: "cpu", color: .blue, index: 0)
                resourceCard("Memory", capacity: node.status?.capacity?.memory, allocatable: node.status?.allocatable?.memory, icon: "memorychip", color: .purple, index: 1)
                resourceCard("Pods", capacity: node.status?.capacity?.pods, allocatable: node.status?.allocatable?.pods, icon: "square.grid.2x2", color: .orange, index: 2)
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private func resourceCard(_ title: String, capacity: String?, allocatable: String?, icon: String, color: Color, index: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(allocatable ?? "—")
                .font(.system(.title3, design: .rounded).bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let cap = capacity {
                Text("of \(cap)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05 + 0.15), value: appeared)
    }

    private var conditionsSection: some View {
        GroupBox("Conditions") {
            if let conditions = node.status?.conditions, !conditions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(conditions.enumerated()), id: \.element.id) { index, condition in
                        HStack {
                            Image(systemName: condition.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(condition.isHealthy ? .green : .red)
                            Text(condition.type ?? "—")
                                .font(.subheadline)
                            Spacer()
                            if let reason = condition.reason {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(8)
            } else {
                Text("No conditions").foregroundStyle(.secondary).padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private var addressesSection: some View {
        GroupBox("Addresses") {
            if let addresses = node.status?.addresses, !addresses.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(addresses) { addr in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(addr.type ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(addr.address ?? "—")
                                .font(.subheadline.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(8)
            } else {
                Text("No addresses").foregroundStyle(.secondary).padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
    }

    private var systemInfoSection: some View {
        GroupBox("System Info") {
            if let info = node.status?.nodeInfo {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    infoRow("OS", "\(info.operatingSystem ?? "—") \(info.architecture ?? "")")
                    infoRow("OS Image", info.osImage ?? "—")
                    infoRow("Kernel", info.kernelVersion ?? "—")
                    infoRow("Container Runtime", info.containerRuntimeVersion ?? "—")
                    infoRow("Kubelet", info.kubeletVersion ?? "—")
                }
                .padding(8)
            } else {
                Text("No system info").foregroundStyle(.secondary).padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
    }

    private var podsButton: some View {
        Button {
            Task {
                await vm.loadPods(nodeName: node.name)
                vm.selectedNode = node
            }
        } label: {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.blue)
                Text("View Pods on this Node")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.35), value: appeared)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).textSelection(.enabled)
        }
    }
}
