import SwiftUI

struct InstanceDetailView: View {
    let instance: CivoInstance
    let onBack: () -> Void
    @State private var appeared = false
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                specsRow
                networkSection
                securitySection
                metadataSection
            }
            .padding(24)
        }
        .navigationTitle(instance.name)
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
                Text(instance.name)
                    .font(.largeTitle.bold())
                Text(instance.size ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: instance.status ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var specsRow: some View {
        HStack(spacing: 16) {
            specCard("CPU", value: instance.cpuCores.map { "\($0)" } ?? "—", unit: "cores", icon: "cpu", color: .blue, index: 0)
            specCard("RAM", value: instance.ramMb.map { "\($0)" } ?? "—", unit: "MB", icon: "memorychip", color: .purple, index: 1)
            specCard("Disk", value: instance.diskGb.map { "\($0)" } ?? "—", unit: "GB", icon: "externaldrive", color: .orange, index: 2)
        }
    }

    private func specCard(_ title: String, value: String, unit: String, icon: String, color: Color, index: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05 + 0.1), value: appeared)
    }

    private var networkSection: some View {
        GroupBox("Network") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Public IP", instance.publicIp ?? "—")
                infoRow("Private IP", instance.privateIp ?? "—")
                infoRow("Region", instance.region ?? "—")
                infoRow("Network ID", instance.networkId ?? "Default")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private var securitySection: some View {
        GroupBox("Security") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow("Firewall ID", instance.firewallId ?? "Default")
                if let password = instance.initialPassword, !password.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Initial Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            if showPassword {
                                Text(password)
                                    .font(.subheadline.monospaced())
                                    .textSelection(.enabled)
                            } else {
                                Text(String(repeating: "*", count: 12))
                                    .font(.subheadline.monospaced())
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
    }

    private var metadataSection: some View {
        GroupBox("Metadata") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Created", instance.createdAt ?? "—")
                if let tags = instance.tags, !tags.isEmpty {
                    infoRow("Tags", tags.joined(separator: ", "))
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
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
