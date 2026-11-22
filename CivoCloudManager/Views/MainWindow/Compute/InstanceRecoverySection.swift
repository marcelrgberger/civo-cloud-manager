import SwiftUI

/// The Recovery Mode box of the instance detail page. Entering and exiting are confirmed first and use the
/// target captured then; the view model checks it and Full Access again on confirm. A change Civo accepted
/// stays marked as waiting for a reboot, with the reboot offered, until a reboot is sent from this app.
struct InstanceRecoverySection: View {
    let instance: CivoInstance
    let vm: InstanceViewModel
    @Environment(\.openWindow) private var openWindow

    private var isActive: Bool { instance.status?.lowercased() == "active" }
    private var awaitingReboot: InstanceRecoveryChange? { vm.recoveryChangeAwaitingReboot(for: instance) }

    private var pending: (change: InstanceRecoveryChange, instanceName: String)? {
        guard let pending = vm.pendingAction, pending.target.instanceId == instance.id,
              case .recovery(let change) = pending.kind else { return nil }
        return (change, pending.target.instanceName)
    }

    var body: some View {
        GroupBox("Recovery Mode") {
            VStack(alignment: .leading, spacing: 10) {
                statusRow
                if let awaitingReboot {
                    rebootWarning(awaitingReboot)
                } else if vm.offeredRecoveryChange(for: instance) == .exit {
                    consoleNotice
                }
            }
            .padding(8)
        }
        .task(id: instance.id) { await vm.loadRecoveryStatus(for: instance) }
        .alert(
            pending.map { $0.change.title($0.instanceName) } ?? Text(verbatim: ""),
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { vm.cancelConfirmation() } }),
            presenting: pending?.change
        ) { change in
            Button(role: change == .enter ? .destructive : nil) {
                guard let target = vm.confirmPendingAction() else { return }
                Task { await vm.changeRecovery(change, of: target) }
            } label: {
                Text(change.confirmLabel)
            }
            Button("Cancel", role: .cancel) { vm.cancelConfirmation() }
        } message: { change in
            change.message
        }
    }

    private var statusRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let message = vm.recoveryStatusError(for: instance) {
                    Text(verbatim: message)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let isOn = vm.recoveryMode(for: instance) {
                    Text(isOn ? "On" : "Off")
                        .font(.subheadline)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("Recovery mode starts an emergency operating system, so you can inspect and repair the boot volume.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if vm.recoveryStatusError(for: instance) != nil {
                Button("Retry") { Task { await vm.loadRecoveryStatus(for: instance) } }
                    .controlSize(.small)
            }
            if vm.consoleTarget(for: instance) != nil, let change = vm.offeredRecoveryChange(for: instance) {
                Button(change.buttonLabel) { vm.beginConfirmation(.recovery(change), for: instance) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private func rebootWarning(_ change: InstanceRecoveryChange) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                change.rebootWarning
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            if isActive, vm.consoleTarget(for: instance) != nil {
                HStack {
                    Spacer()
                    Button("Soft Reboot...") { vm.beginConfirmation(.power(.softReboot), for: instance) }
                    Button("Hard Reboot...") { vm.beginConfirmation(.power(.hardReboot), for: instance) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var consoleNotice: some View {
        HStack {
            Label("While recovery mode is active, the instance can be reached only through the console.", systemImage: "terminal")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if isActive, let target = vm.consoleTarget(for: instance) {
                Button("Open Console") {
                    vm.handOverConsoleLogin(of: instance, to: target)
                    openWindow(id: "console", value: target)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open the instance console in a new window")
            }
        }
    }
}

private extension InstanceRecoveryChange {
    var buttonLabel: LocalizedStringKey {
        switch self {
        case .enter: "Enter Recovery Mode..."
        case .exit: "Exit Recovery Mode..."
        }
    }

    var confirmLabel: LocalizedStringKey {
        switch self {
        case .enter: "Enter Recovery Mode"
        case .exit: "Exit Recovery Mode"
        }
    }

    func title(_ instanceName: String) -> Text {
        switch self {
        case .enter: Text("Enter recovery mode for \(instanceName)?")
        case .exit: Text("Exit recovery mode for \(instanceName)?")
        }
    }

    var message: Text {
        switch self {
        case .enter: Text("The instance has to be rebooted before recovery mode takes effect. While recovery mode is active, the instance can be reached only through the console, not through SSH or its services.")
        case .exit: Text("The instance has to be rebooted again before it can be reached as normal. Until then it stays in recovery mode and can be reached only through the console.")
        }
    }

    var rebootWarning: Text {
        switch self {
        case .enter: Text("Recovery mode is not in effect yet. Reboot the instance to start the recovery system; then it can be reached only through the console. If the operating system does not respond, use a hard reboot.")
        case .exit: Text("Recovery mode is still in effect. Reboot the instance to start its own operating system again; until then it can be reached only through the console.")
        }
    }
}
