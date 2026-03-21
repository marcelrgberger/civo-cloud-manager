import SwiftUI

struct VolumeDetailView: View {
    let volume: CivoVolume
    let instances: [CivoInstance]
    let onBack: () -> Void
    @State private var appeared = false

    private var attachedTo: String {
        if let instanceId = volume.instanceId {
            if let instance = instances.first(where: { $0.id == instanceId }) {
                return "Instance: \(instance.name)"
            }
            return "Instance: \(instanceId)"
        }
        if let clusterId = volume.clusterId {
            return "Kubernetes Cluster: \(clusterId)"
        }
        return "Not attached"
    }

    private var attachmentIcon: String {
        if volume.instanceId != nil { return "desktopcomputer" }
        if volume.clusterId != nil { return "helm" }
        return "eject"
    }

    private var attachmentColor: Color {
        if volume.instanceId != nil || volume.clusterId != nil { return .green }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                attachmentSection
                configSection
            }
            .padding(24)
        }
        .navigationTitle(volume.name)
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
                Text(volume.name)
                    .font(.largeTitle.bold())
                Text(volume.sizeDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: volume.status ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var attachmentSection: some View {
        GroupBox("Attachment") {
            HStack(spacing: 12) {
                Image(systemName: attachmentIcon)
                    .font(.title2)
                    .foregroundStyle(attachmentColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachedTo)
                        .font(.subheadline.weight(.medium))
                    if let mountpoint = volume.mountpoint {
                        Text("Mounted at: \(mountpoint)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not mounted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Details") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Size", volume.sizeDisplay)
                infoRow("Status", volume.status ?? "—")
                infoRow("Region", volume.region ?? "—")
                infoRow("Network ID", volume.networkId ?? "Default")
                infoRow("Bootable", volume.bootable == true ? "Yes" : "No")
                infoRow("Created", volume.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
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
