import SwiftUI

struct InstanceDetailView: View {
    let instance: CivoInstance
    @Bindable var vm: InstanceViewModel
    let onBack: () -> Void
    @Environment(\.openWindow) private var openWindow
    @State private var appeared = false
    @State private var passwordAccess = PasswordAccess()
    @State private var copiedPassword = false
    @State private var credentialsTarget: ConsoleTarget?
    @State private var resizeSize = ""
    /// Set while the reverse DNS is edited, captured when editing starts.
    @State private var reverseDnsTarget: ConsoleTarget?
    @State private var reverseDnsValue = ""
    private let store = StoreManager.shared

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
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle(instance.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.backward") { onBack() }
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
        .relocksPassword(passwordAccess)
        .onChange(of: instance.id) { passwordAccess.invalidate() }
        .onChange(of: store.isFullAccessUnlocked) { _, unlocked in
            if !unlocked { passwordAccess.invalidate() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .civoAPIKeyDidChange)) { _ in
            passwordAccess.invalidate()
        }
        .task(id: copiedPassword) {
            guard copiedPassword else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copiedPassword = false }
        }
        .sheet(isPresented: Binding(
            get: { vm.pendingAction?.kind == .resize && vm.pendingAction?.target.instanceId == instance.id },
            set: { if !$0 { vm.cancelConfirmation() } }
        )) {
            resizeSheet
        }
        .sheet(isPresented: Binding(get: { credentialsTarget != nil }, set: { if !$0 { credentialsTarget = nil } })) {
            if let target = credentialsTarget {
                InstanceCredentialsView(target: target)
            }
        }
        .instancePowerConfirmation(vm)
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
            specCard("CPU", value: instance.cpuCores.map { "\($0)" } ?? "—", unit: String(localized: "cores"), icon: "cpu", color: .blue, index: 0)
            specCard("RAM", value: instance.ramMb.map { "\($0)" } ?? "—", unit: "MB", icon: "memorychip", color: .purple, index: 1)
            specCard("Disk", value: instance.diskGb.map { "\($0)" } ?? "—", unit: "GB", icon: "externaldrive", color: .orange, index: 2)
        }
    }

    private func specCard(_ title: LocalizedStringKey, value: String, unit: String, icon: String, color: Color, index: Int) -> some View {
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
                infoRow("Network ID", instance.networkId ?? String(localized: "Default"))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reverse DNS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let target = reverseDnsTarget {
                        HStack(spacing: 6) {
                            TextField("e.g. mail.example.com", text: $reverseDnsValue)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                            Button("Save") {
                                Task {
                                    await vm.updateInstance(target, reverseDns: reverseDnsValue)
                                    reverseDnsTarget = nil
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(reverseDnsValue.isEmpty)
                            Button("Cancel") {
                                reverseDnsTarget = nil
                            }
                            .controlSize(.small)
                        }
                    } else {
                        HStack {
                            Text(instance.reverseDns ?? "Not set")
                                .font(.subheadline)
                                .foregroundStyle(instance.reverseDns != nil ? .primary : .tertiary)
                            if let target = vm.consoleTarget(for: instance) {
                                Button {
                                    reverseDnsValue = instance.reverseDns ?? ""
                                    reverseDnsTarget = target
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
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
                infoRow("Firewall ID", instance.firewallId ?? String(localized: "Default"))
                if let password = instance.initialPassword, !password.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Initial Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        passwordRow(password)
                        if passwordAccess.isDeviceAuthenticationUnavailable {
                            DeviceAuthenticationRequiredHint()
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
                if let target = vm.consoleTarget(for: instance) {
                    actionButtons(target)
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
                            Text(entry.localizedAction)
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

    /// Every action uses the target captured from the listed instance, never the Settings region.
    private func actionButtons(_ target: ConsoleTarget) -> some View {
        HStack(spacing: 10) {
            if instance.status?.lowercased() == "active" {
                Button { vm.beginConfirmation(.power(.stop), for: instance) } label: {
                    Label("Stop", systemImage: "stop.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)

                Menu {
                    Button("Soft Reboot") { vm.beginConfirmation(.power(.softReboot), for: instance) }
                    Button("Hard Reboot...") { vm.beginConfirmation(.power(.hardReboot), for: instance) }
                } label: {
                    Label("Reboot", systemImage: "arrow.clockwise.circle")
                } primaryAction: {
                    vm.beginConfirmation(.power(.softReboot), for: instance)
                }
                .menuStyle(.button)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .fixedSize()
                .help("Click for a soft reboot, open the menu for a hard reboot")

                Button {
                    vm.handOverConsoleLogin(of: instance, to: target)
                    openWindow(id: "console", value: target)
                } label: {
                    Label("Open Console", systemImage: "terminal")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open the instance console in a new window")
            } else if instance.status?.lowercased() == "shutoff" {
                Button { vm.beginConfirmation(.power(.start), for: instance) } label: {
                    Label("Start", systemImage: "play.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.green)
            }

            // Unlike the console, available in every state, so credentials can be kept up to date.
            Button {
                credentialsTarget = target
            } label: {
                Label("Credentials…", systemImage: "key")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Save a username and password for this instance in this Mac's keychain")

            Button {
                resizeSize = instance.size ?? ""
                vm.beginConfirmation(.resize, for: instance)
            } label: {
                Label("Resize", systemImage: "arrow.up.right.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Resize Sheet

    private var resizeSheet: some View {
        VStack(spacing: 16) {
            Text("Resize Instance")
                .font(.title2.bold())
            Text("Select a new size. Instance will be rebooted.")
                .font(.caption)
                .foregroundStyle(.secondary)

            SizePickerGrid(sizes: vm.availableSizes, selectedSize: $resizeSize, filterPrefix: "Instance")
                .frame(maxHeight: 300)

            HStack {
                Button("Cancel") { vm.cancelConfirmation() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Resize") {
                    guard let target = vm.confirmPendingAction() else { return }
                    let size = resizeSize
                    Task { await vm.resizeInstance(target, size: size) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(resizeSize.isEmpty || resizeSize == instance.size)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private func passwordRow(_ password: String) -> some View {
        HStack {
            // Not selectable: copying goes through `SecretPasteboard` only.
            if passwordAccess.isRevealed {
                Text(verbatim: password)
                    .font(.subheadline.monospaced())
            } else {
                Text(verbatim: String(repeating: "*", count: 12))
                    .font(.subheadline.monospaced())
            }
            Button {
                if passwordAccess.isRevealed {
                    passwordAccess.hide()
                } else {
                    Task { await passwordAccess.reveal() }
                }
            } label: {
                Label(
                    passwordAccess.isRevealed ? "Hide password" : "Show password",
                    systemImage: passwordAccess.isRevealed ? "eye.slash" : "eye"
                )
                .labelStyle(.iconOnly)
                .font(.caption)
            }
            .buttonStyle(.borderless)
            .help(passwordAccess.isRevealed ? "Hide password" : "Show password")
            Button {
                Task {
                    if await passwordAccess.copy(password) { copiedPassword = true }
                }
            } label: {
                Label("Copy password", systemImage: copiedPassword ? "checkmark" : "doc.on.doc")
                    .labelStyle(.iconOnly)
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy password")
        }
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
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
