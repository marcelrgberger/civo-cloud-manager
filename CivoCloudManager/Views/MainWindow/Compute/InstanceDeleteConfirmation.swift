import SwiftUI

extension View {
    /// Asks for the instance name before a deletion opened with `beginConfirmation(.delete, for:)` is sent.
    /// The view model checks the captured target and Full Access again when the user confirms.
    func instanceDeleteConfirmation(_ vm: InstanceViewModel) -> some View {
        modifier(InstanceDeleteConfirmation(vm: vm))
    }
}

private struct InstanceDeleteConfirmation: ViewModifier {
    let vm: InstanceViewModel

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(get: { vm.pendingAction?.kind == .delete }, set: { if !$0 { vm.cancelConfirmation() } })) {
            if let target = vm.pendingAction?.target {
                DeleteConfirmationSheet(
                    resourceType: "Instance",
                    resourceName: target.instanceName,
                    onConfirm: {
                        guard let target = vm.confirmPendingAction() else { return }
                        Task { await vm.removeInstance(target) }
                    },
                    onCancel: { vm.cancelConfirmation() },
                    note: vm.mayHaveSavedCredentials(target) ? "Saved credentials for this instance will be deleted as well." : nil
                )
            }
        }
    }
}
