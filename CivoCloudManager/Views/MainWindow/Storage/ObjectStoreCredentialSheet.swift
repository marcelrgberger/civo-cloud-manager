import SwiftUI

struct ObjectStoreCredentialSheet: View {
    @Bindable var switcher: ObjectStoreCredentialSwitcher
    @State private var selectedCredentialId = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Change Credential").font(.title2)
            if let session = switcher.session {
                LabeledContent("Object Store", value: session.target.storeName)
                LabeledContent("Region", value: session.target.context.region)
                LabeledContent("Current credential", value: session.currentName)
                if switcher.isLoading {
                    ProgressView()
                } else if !switcher.candidates.isEmpty {
                    Picker("New credential", selection: $selectedCredentialId) {
                        Text("Select credential").tag("")
                        ForEach(switcher.candidates) { credential in
                            Text(credential.displayName).tag(credential.id)
                        }
                    }
                    .disabled(switcher.isSubmitting)
                } else if switcher.isComplete {
                    Text(switcher.hasOtherCredentials
                         ? String(localized: "Other credentials exist, but none can be used (suspended or not ready).")
                         : String(localized: "No other credential is available in this region."))
                        .foregroundStyle(.secondary)
                }
            }
            Text("Other S3 clients that use the old credential must be updated to the new one. The old credential is not deleted.")
                .foregroundStyle(.orange)
            if let message = switcher.message {
                Text(message).foregroundStyle(.red)
            }
            HStack {
                Button("Cancel") { switcher.cancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if switcher.isSubmitting { ProgressView().controlSize(.small) }
                Button("Change Credential") {
                    Task { _ = await switcher.confirm(credentialId: selectedCredentialId) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedCredentialId.isEmpty || !switcher.isComplete || switcher.isLoading || switcher.isSubmitting)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
