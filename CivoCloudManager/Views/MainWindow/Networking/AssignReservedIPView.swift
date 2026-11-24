import SwiftUI

/// Picks the instance a reserved IP is assigned to, from the instances of the region the action was opened with.
struct AssignReservedIPView: View {
    let controller: ReservedIPController
    let request: ReservedIPController.Request
    let onConfirm: (ReservedIPAction) -> Void

    @State private var instanceId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assign Reserved IP").font(.title2.bold())
            if let ip = request.ip { Text(ip.name).font(.headline) }
            picker
            Text("The address of the instance may change, and open connections may drop.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if let error = controller.sheetError { ErrorBanner(message: error) }
            HStack {
                if controller.isSending { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", role: .cancel) { controller.cancel() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(controller.isSending)
                Button("Assign") {
                    if let instanceId { onConfirm(.assign(instanceId: instanceId)) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(instanceId == nil || controller.isSending)
            }
        }
        .padding(24)
        .frame(minWidth: 460)
        .interactiveDismissDisabled(controller.isSending)
        .task(id: request.id) { await controller.loadInstances() }
    }

    @ViewBuilder
    private var picker: some View {
        switch controller.instanceChoices {
        case .loading:
            ProgressView("Loading instances...")
        case .failed(let message):
            ErrorBanner(message: message)
            Button("Retry") { Task { await controller.loadInstances() } }
        case .loaded(let instances) where instances.isEmpty:
            Text("No instances found in this region.").foregroundStyle(.secondary)
        case .loaded(let instances):
            Picker("Instance", selection: $instanceId) {
                Text("Select an instance").tag(String?.none)
                ForEach(instances) { instance in
                    Text("\(instance.name) (\(instance.publicIp ?? "-"))").tag(String?.some(instance.id))
                }
            }
            .accessibilityIdentifier(AccessibilityID.reservedIPInstancePicker)
        }
    }
}
