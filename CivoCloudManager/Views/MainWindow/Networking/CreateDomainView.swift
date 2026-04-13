import SwiftUI

struct CreateDomainView: View {
    @Bindable var vm: DomainViewModel
    @State private var name = ""

    var body: some View {
        Form {
            Section("Domain Details") {
                TextField("Domain Name", text: $name)
                    .help("e.g. example.com")
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Domain")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingDomain = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        _ = await vm.createDomain(["name": name])
                    }
                }
                .disabled(name.isEmpty || vm.isSaving)
            }
        }
    }
}
