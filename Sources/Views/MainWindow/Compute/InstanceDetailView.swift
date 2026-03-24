import SwiftUI

struct InstanceDetailView: View {
    let instance: CivoInstance
    @Bindable var vm: InstanceViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var showPassword = false
    @State private var showResize = false
    @State private var resizeTarget = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                specsRow
                networkSection
                sshSection
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
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
        .sheet(isPresented: $showResize) {
            resizeSheet
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
                if let reverseDns = instance.reverseDns, !reverseDns.isEmpty {
                    infoRow("Reverse DNS", reverseDns)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private var sshSection: some View {
        GroupBox("SSH Access") {
            VStack(alignment: .leading, spacing: 10) {
                if let ip = instance.publicIp, !ip.isEmpty, ip != "—" {
                    let user = instance.initialUser ?? "root"
                    let sshCommand = "ssh \(user)@\(ip)"
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect via SSH")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(sshCommand)
                                .font(.subheadline.monospaced())
                                .textSelection(.enabled)
                        }
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sshCommand, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .help("Copy SSH command")
                    }
                } else {
                    Text("SSH not available — waiting for public IP")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.22), value: appeared)
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
        GroupBox("Actions & Metadata") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        showResize = true
                        resizeTarget = instance.size ?? ""
                    } label: {
                        Label("Resize", systemImage: "arrow.up.right.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    infoRow("Instance ID", instance.id)
                    infoRow("Created", instance.createdAt ?? "—")
                    if let tags = instance.tags, !tags.isEmpty {
                        infoRow("Tags", tags.joined(separator: ", "))
                    }
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
    }

    // MARK: - Resize Sheet

    private var resizeSheet: some View {
        VStack(spacing: 16) {
            Text("Resize Instance")
                .font(.title2.bold())
            Text("Select a new size. Instance will be rebooted.")
                .font(.caption)
                .foregroundStyle(.secondary)

            SizePickerGrid(sizes: vm.availableSizes, selectedSize: $resizeTarget, filterPrefix: "Instance")
                .frame(maxHeight: 300)

            HStack {
                Button("Cancel") { showResize = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Resize") {
                    Task {
                        await vm.resizeInstance(instance.id, size: resizeTarget)
                        showResize = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(resizeTarget.isEmpty || resizeTarget == instance.size)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
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
