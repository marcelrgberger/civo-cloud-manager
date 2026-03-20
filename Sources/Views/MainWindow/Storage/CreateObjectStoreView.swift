import SwiftUI

struct CreateObjectStoreView: View {
    @Bindable var vm: VolumeViewModel
    @State private var name = ""
    @State private var maxSize = 500

    var body: some View {
        Form {
            Section("Object Store Details") {
                TextField("Name", text: $name)
                Stepper("Max Size: \(maxSize) GB", value: $maxSize, in: 250...100000, step: 250)
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
                        _ = await vm.createObjectStore([
                            "name": name,
                            "size": maxSize,
                        ])
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
