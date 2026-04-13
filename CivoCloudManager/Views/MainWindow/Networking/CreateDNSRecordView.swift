import SwiftUI

struct CreateDNSRecordView: View {
    @Bindable var vm: DomainViewModel
    let domainId: String
    var editingRecord: CivoDomainRecord?

    @State private var recordType = "A"
    @State private var name = ""
    @State private var value = ""
    @State private var ttl = "600"
    @State private var priority = ""

    private let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "SRV", "NS"]

    var body: some View {
        Form {
            Section("Record Details") {
                Picker("Type", selection: $recordType) {
                    ForEach(recordTypes, id: \.self) { Text($0) }
                }
                TextField("Name", text: $name)
                    .help("e.g. www, mail, @")
                TextField("Value", text: $value)
                TextField("TTL", text: $ttl)
                if recordType == "MX" || recordType == "SRV" {
                    TextField("Priority", text: $priority)
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editingRecord != nil ? "Edit Record" : "Create Record")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingRecord = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(editingRecord != nil ? "Save" : "Create") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || value.isEmpty || vm.isSaving)
            }
        }
        .onAppear {
            if let r = editingRecord {
                recordType = r.type ?? "A"
                name = r.name ?? ""
                value = r.value ?? ""
                ttl = r.ttl.map(String.init) ?? "600"
                priority = r.priority.map(String.init) ?? ""
            }
        }
    }

    private func save() async {
        var body: [String: Any] = [
            "type": recordType,
            "name": name,
            "value": value,
            "ttl": Int(ttl) ?? 600,
        ]
        if let p = Int(priority) { body["priority"] = p }

        if let r = editingRecord {
            _ = await vm.updateRecord(domainId, recordId: r.id, body: body)
        } else {
            _ = await vm.createRecord(domainId, body: body)
        }
    }
}
