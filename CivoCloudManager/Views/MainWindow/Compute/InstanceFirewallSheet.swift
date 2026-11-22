import SwiftUI

/// Picks another firewall of the instance's network, opened with `beginConfirmation(.firewall, for:)`.
/// The change is sent only after a second confirmation; the view model checks the captured target,
/// Full Access and the firewall list again at that moment.
struct InstanceFirewallSheet: View {
    let instance: CivoInstance
    let vm: InstanceViewModel
    @State private var selectedId = ""
    @State private var isConfirming = false

    private var options: InstanceFirewallOptions? { vm.firewallOptions(for: instance) }
    private var offered: [CivoFirewall] { options?.offered(for: instance) ?? [] }
    private var selected: CivoFirewall? { offered.first { $0.id == selectedId } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Change Firewall")
                .font(.title2.bold())
            Text("Only firewalls in the network of this instance are listed.")
                .font(.caption)
                .foregroundStyle(.secondary)

            firewallList
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 260)

            Label(Self.warning, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)

            HStack {
                Button("Cancel") { vm.cancelConfirmation() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Change Firewall") { isConfirming = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.firewallOptionsError != nil || selected == nil || selectedId == instance.firewallId)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .task {
            await vm.loadFirewallOptions(for: instance)
            if selectedId.isEmpty { selectedId = instance.firewallId ?? "" }
        }
        .alert(
            selected.map { Text("Switch \(instance.name) to firewall \($0.name)?") } ?? Text(verbatim: ""),
            isPresented: $isConfirming,
            presenting: selected
        ) { firewall in
            Button("Change Firewall") {
                guard let target = vm.confirmPendingAction() else { return }
                Task { await vm.setFirewall(firewall.id, of: target) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text(Self.warning)
        }
    }

    @ViewBuilder
    private var firewallList: some View {
        if let message = vm.firewallOptionsError {
            VStack(spacing: 8) {
                Text(verbatim: message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Retry") { Task { await vm.loadFirewallOptions(for: instance) } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if options == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if offered.isEmpty {
            Text("No firewall was found in the network of this instance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(offered, selection: Binding(get: { selectedId }, set: { selectedId = $0 ?? selectedId })) { firewall in
                row(firewall)
            }
        }
    }

    private func row(_ firewall: CivoFirewall) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: firewall.name)
                Text("Rules: \(firewall.rulesCountInt)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if firewall.isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if firewall.id == instance.firewallId {
                Text("Current")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private static let warning: LocalizedStringKey = "The rules of the new firewall apply right away. If they do not allow SSH or other access you rely on, that access to the instance is blocked."
}
