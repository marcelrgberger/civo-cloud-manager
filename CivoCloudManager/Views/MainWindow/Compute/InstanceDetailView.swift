import SwiftUI

struct InstanceDetailView: View {
    let instance: CivoInstance
    @Bindable var vm: InstanceViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var showPassword = false
    @State private var showResize = false
    @State private var resizeTarget = ""
    @State private var editingReverseDns = false
    @State private var reverseDnsValue = ""

    private var sshKeyName: String {
        guard let keyId = instance.sshKeyId else { return "" }
        let name = vm.sshKeys.first(where: { $0.id == keyId })?.name ?? ""
        return name.replacingOccurrences(of: " ", with: "-").lowercased()
    }

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
                infoRow("Region", instance.region ?? CivoConfig.shared.region)
                infoRow("Network ID", instance.networkId ?? "Default")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reverse DNS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if editingReverseDns {
                        HStack(spacing: 6) {
                            TextField("e.g. mail.example.com", text: $reverseDnsValue)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                            Button("Save") {
                                Task {
                                    await vm.updateInstance(instance.id, reverseDns: reverseDnsValue)
                                    editingReverseDns = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(reverseDnsValue.isEmpty)
                            Button("Cancel") {
                                editingReverseDns = false
                            }
                            .controlSize(.small)
                        }
                    } else {
                        HStack {
                            Text(instance.reverseDns ?? "Not set")
                                .font(.subheadline)
                                .foregroundStyle(instance.reverseDns != nil ? .primary : .tertiary)
                            Button {
                                reverseDnsValue = instance.reverseDns ?? ""
                                editingReverseDns = true
                            } label: {
                                Image(systemName: "pencil")
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
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private var sshSection: some View {
        GroupBox("SSH Access") {
            VStack(alignment: .leading, spacing: 10) {
                if let ip = instance.publicIp, !ip.isEmpty, ip != "—" {
                    let user = instance.initialUser ?? "root"
                    let keyName = instance.sshKeyId != nil ? sshKeyName : nil
                    let sshCommand = keyName != nil
                        ? "ssh -i ~/.ssh/\(keyName!) \(user)@\(ip)"
                        : "ssh \(user)@\(ip)"
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect via SSH")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(sshCommand)
                                .font(.subheadline.monospaced())
                                .textSelection(.enabled)
                            if keyName != nil {
                                Text("Using SSH key: \(keyName!)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("No SSH key — use initial password")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
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
                    if instance.status?.lowercased() == "active" {
                        Button { Task { await vm.stopInstance(instance.id) } } label: {
                            Label("Stop", systemImage: "stop.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)

                        Button { Task { await vm.rebootInstance(instance.id) } } label: {
                            Label("Reboot", systemImage: "arrow.clockwise.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else if instance.status?.lowercased() == "shutoff" {
                        Button { Task { await vm.startInstance(instance.id) } } label: {
                            Label("Start", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.green)
                    }

                    Button {
                        showResize = true
                        resizeTarget = instance.size ?? ""
                    } label: {
                        Label("Resize", systemImage: "arrow.up.right.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Activity log for this instance
                let instanceLog = ActivityLog.shared.entries.filter { $0.resourceId == instance.id }
                if !instanceLog.isEmpty {
                    Divider()
                    Text("Recent Activity")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(instanceLog.prefix(5)) { entry in
                        HStack(spacing: 8) {
                            Image(systemName: entry.icon)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .frame(width: 16)
                            Text(entry.action)
                                .font(.caption)
                            Spacer()
                            Text(entry.timeAgo)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
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
