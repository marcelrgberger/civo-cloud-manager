import SwiftUI

extension View {
    /// Asks before a power action opened with `beginConfirmation(.power(_:), for:)` is sent.
    /// The view model checks the captured target and Full Access again when the user confirms.
    func instancePowerConfirmation(_ vm: InstanceViewModel) -> some View {
        modifier(InstancePowerConfirmation(vm: vm))
    }
}

private struct InstancePowerConfirmation: ViewModifier {
    let vm: InstanceViewModel

    private var pending: (action: InstancePowerAction, instanceName: String)? {
        guard let pending = vm.pendingAction, case .power(let action) = pending.kind else { return nil }
        return (action, pending.target.instanceName)
    }

    func body(content: Content) -> some View {
        content.alert(
            pending.map { $0.action.title($0.instanceName) } ?? Text(verbatim: ""),
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { vm.cancelConfirmation() } }),
            presenting: pending?.action
        ) { action in
            Button(role: action == .hardReboot ? .destructive : nil) {
                guard let target = vm.confirmPendingAction() else { return }
                Task { await vm.changePower(action, of: target) }
            } label: {
                Text(action.confirmLabel)
            }
            Button("Cancel", role: .cancel) { vm.cancelConfirmation() }
        } message: { action in
            action.message
        }
    }
}

private extension InstancePowerAction {
    func title(_ instanceName: String) -> Text {
        switch self {
        case .start: Text("Start \(instanceName)?")
        case .stop: Text("Stop \(instanceName)?")
        case .softReboot: Text("Soft reboot \(instanceName)?")
        case .hardReboot: Text("Hard reboot \(instanceName)?")
        }
    }

    var message: Text {
        switch self {
        case .start: Text("The instance will be powered on.")
        case .stop: Text("The instance will be shut down until you start it again.")
        case .softReboot: Text("The instance will be restarted through its operating system.")
        case .hardReboot: Text("The instance will be reset immediately, without shutting down its operating system. Unsaved work and data not yet written to disk may be lost.")
        }
    }

    var confirmLabel: LocalizedStringKey {
        switch self {
        case .start: "Start"
        case .stop: "Stop"
        case .softReboot: "Soft Reboot"
        case .hardReboot: "Hard Reboot"
        }
    }
}
