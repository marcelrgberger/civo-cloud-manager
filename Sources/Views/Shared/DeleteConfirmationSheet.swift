import SwiftUI

struct DeleteConfirmationSheet: View {
    let resourceType: String
    let resourceName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var confirmationText = ""

    private var isConfirmed: Bool {
        confirmationText == resourceName
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("Delete \(resourceType)")
                .font(.title2.bold())

            VStack(spacing: 8) {
                Text("This will permanently delete")
                    .foregroundStyle(.secondary)
                Text(resourceName)
                    .font(.headline)
                Text("This action cannot be undone. All associated data will be lost.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Type the name to confirm:")
                    .font(.callout.weight(.medium))
                TextField(resourceName, text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { onCancel() }
                    .keyboardShortcut(.cancelAction)

                Button("Delete Permanently", role: .destructive) { onConfirm() }
                    .disabled(!isConfirmed)
                    .keyboardShortcut(.defaultAction)
                    .help("Permanently removes this resource and all its data")
            }
        }
        .padding(30)
        .frame(width: 420)
    }
}
