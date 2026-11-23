import SwiftUI

/// The name form for reserving a new IP and for renaming one.
struct ReserveIPView: View {
    let controller: ReservedIPController
    let request: ReservedIPController.Request
    let onConfirm: (ReservedIPAction) -> Void

    @State private var name: String

    init(controller: ReservedIPController, request: ReservedIPController.Request, onConfirm: @escaping (ReservedIPAction) -> Void) {
        self.controller = controller
        self.request = request
        self.onConfirm = onConfirm
        _name = State(initialValue: request.ip?.name ?? "")
    }

    private var isRename: Bool { request.operation == .rename }

    private var action: ReservedIPAction {
        isRename ? .rename(name: name) : .reserve(name: name)
    }

    private var canSubmit: Bool {
        guard let trimmed = ReservedIPRules.normalizedName(name) else { return false }
        return !controller.isSending && trimmed != request.ip?.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isRename ? LocalizedStringKey("Rename Reserved IP") : LocalizedStringKey("Reserve IP")).font(.title2.bold())
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if canSubmit { onConfirm(action) } }
            if !isRename {
                Text("A reserved IP address can incur running costs, also while it is not assigned.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let error = controller.sheetError { ErrorBanner(message: error) }
            HStack {
                if controller.isSending { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", role: .cancel) { controller.cancel() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(controller.isSending)
                Button(isRename ? LocalizedStringKey("Rename") : LocalizedStringKey("Reserve")) { onConfirm(action) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSubmit)
            }
        }
        .padding(24)
        .frame(minWidth: 420)
        .interactiveDismissDisabled(controller.isSending)
    }
}
