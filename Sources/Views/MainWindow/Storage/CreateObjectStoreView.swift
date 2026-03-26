import SwiftUI

struct CreateObjectStoreView: View {
    @Bindable var vm: VolumeViewModel
    @State private var name = ""
    @State private var maxSize = 500
    @State private var selectedCredentialId = ""

    var body: some View {
        Form {
            Section("Object Store Details") {
                TextField("Name", text: $name)
                Stepper("Max Size: \(maxSize) GB", value: $maxSize, in: 250...100000, step: 250)
            }

            Section("Credentials") {
                Picker("Assign Credential", selection: $selectedCredentialId) {
                    Text("Auto-create new").tag("")
                    ForEach(vm.credentials) { cred in
                        Text("\(cred.displayName) — \(cred.accessKeyId ?? "")").tag(cred.id)
                    }
                }
                .help("Assign existing credentials or create new ones automatically")
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Object Store")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingObjectStore = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = ["name": name, "size": maxSize]
                        if !selectedCredentialId.isEmpty,
                           let cred = vm.credentials.first(where: { $0.id == selectedCredentialId }) {
                            body["access_key_id"] = cred.accessKeyId ?? ""
                        }
                        _ = await vm.createObjectStore(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
