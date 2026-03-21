import SwiftUI

struct LoadBalancerDetailView: View {
    let lb: CivoLoadBalancer
    let onBack: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                networkSection
                configSection
                backendsSection
            }
            .padding(24)
        }
        .navigationTitle(lb.name)
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
                Text(lb.name)
                    .font(.largeTitle.bold())
                Text(lb.algorithm ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: lb.state ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var networkSection: some View {
        GroupBox("Network") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Public IP", lb.publicIp ?? "—")
                infoRow("Private IP", lb.privateIp ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Configuration") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Algorithm", lb.algorithm ?? "—")
                infoRow("Traffic Policy", lb.externalTrafficPolicy ?? "—")
                infoRow("Cluster ID", lb.clusterId ?? "—")
                infoRow("Firewall ID", lb.firewallId ?? "—")
                infoRow("Created", lb.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private var backendsSection: some View {
        GroupBox("Backends (\(lb.backendList.count))") {
            if lb.backendList.isEmpty {
                Text("No backends configured")
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(lb.backendList.enumerated()), id: \.offset) { index, backend in
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundStyle(.blue)
                            Text(backend)
                                .font(.subheadline.monospaced())
                                .textSelection(.enabled)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                        .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(8)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}
