import SwiftUI

/// Unassigning and releasing cut connections, so both ask for the name of the reserved IP.
struct ReservedIPConfirmationView: View {
    let controller: ReservedIPController
    let request: ReservedIPController.Request
    let onConfirm: (ReservedIPAction) -> Void

    @State private var typedName = ""

    private var ip: CivoReservedIP? { request.ip }
    private var isRelease: Bool { request.operation == .release }

    private var isConfirmed: Bool {
        guard let ip else { return false }
        return ReservedIPRules.typedNameMatches(typedName, name: ip.name) && !controller.isSending
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            Text(isRelease ? LocalizedStringKey("Release Reserved IP") : LocalizedStringKey("Unassign Reserved IP")).font(.title2.bold())
            if let ip {
                VStack(spacing: 8) {
                    Text(ip.name).font(.headline)
                    Text(warning(for: ip))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    ForEach(extraWarnings(for: ip), id: \.self) { line in
                        Text(line).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Type the name to confirm:").font(.callout.weight(.medium))
                    TextField(ip.name, text: $typedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body.monospaced())
                }
                .padding(.horizontal, 20)
            }
            if let error = controller.sheetError { ErrorBanner(message: error) }
            HStack(spacing: 12) {
                if controller.isSending { ProgressView().controlSize(.small) }
                Button("Cancel", role: .cancel) { controller.cancel() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(controller.isSending)
                Button(isRelease ? LocalizedStringKey("Release") : LocalizedStringKey("Unassign"), role: .destructive) {
                    onConfirm(isRelease ? .release(typedName: typedName) : .unassign(typedName: typedName))
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isConfirmed)
            }
        }
        .padding(30)
        .frame(minWidth: 460)
        .interactiveDismissDisabled(controller.isSending)
    }

    private func warning(for ip: CivoReservedIP) -> String {
        isRelease
            ? String(localized: "This deletes the reserved IP \"\(ip.name)\". Its address may be lost for good, and DNS records, firewall rules or allow-lists elsewhere that point to it stop working.")
            : String(localized: "Traffic through the reserved IP \"\(ip.name)\" stops until it is assigned again, and open connections through it drop.")
    }

    private func extraWarnings(for ip: CivoReservedIP) -> [String] {
        guard isRelease else { return [] }
        switch ip.assignment {
        case .assigned: return [String(localized: "It is still assigned, so its target loses connectivity through it.")]
        case .unrecognized: return [String(localized: "Its target could not be identified, so the effect on the target is unknown.")]
        case .unknown, .unassigned: return []
        }
    }
}
