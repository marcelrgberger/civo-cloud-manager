import AppKit
import SwiftUI

struct CreateInstanceView: View {
    @Bindable var vm: InstanceViewModel
    @State private var form = InstanceCreationForm()
    @State private var showsAdvanced = false
    /// The form as it was when the bulk confirmation opened; exactly this is sent when it is confirmed.
    @State private var confirmingForm: InstanceCreationForm?

    private var maximumCount: Int { vm.maximumCreationCount(for: form) }

    var body: some View {
        Form {
            Section("Instance Details") {
                TextField("Hostname", text: $form.hostname)
                Picker("Disk Image", selection: $form.diskImage) {
                    Text("Select an image").tag("")
                    ForEach(vm.availableDiskImages) { img in
                        Text(img.displayName).tag(img.id)
                    }
                }
            }

            Section("Select Size") {
                SizePickerGrid(sizes: vm.availableSizes, selectedSize: $form.size, filterPrefix: "Instance")
            }

            Section("Networking") {
                Picker("Network", selection: $form.networkId) {
                    Text("Select a network").tag("")
                    ForEach(vm.availableNetworks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
                Picker("Firewall", selection: $form.firewallId) {
                    Text("Default").tag("")
                    ForEach(InstanceCreationForm.firewalls(vm.availableFirewalls, in: form.networkId)) { fw in
                        Text(fw.name).tag(fw.id)
                    }
                }
            }

            Section("Authentication") {
                Picker("SSH Key", selection: $form.sshKeyId) {
                    Text("None").tag("")
                    ForEach(vm.sshKeys) { key in
                        Text(key.name).tag(key.id)
                    }
                }
            }

            Section("Tags") {
                TextField("Tags (comma-separated)", text: $form.tags)
                if let problem = form.tagsProblem {
                    Text(problem).foregroundStyle(.red)
                }
            }

            Section {
                DisclosureGroup("Advanced", isExpanded: $showsAdvanced) {
                    advancedOptions
                }
            }

            if !form.isComplete {
                Section {
                    Text("Hostname, size, disk image and network are required.")
                        .foregroundStyle(.secondary)
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Instance")
        .task {
            await vm.loadFormData()
            form.selectDefaultNetwork(from: vm.availableNetworks)
        }
        .onChange(of: maximumCount) { _, maximum in
            form.count = min(form.count, maximum)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingInstance = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    if form.count > 1 {
                        confirmingForm = form
                    } else {
                        create(form)
                    }
                }
                .disabled(form.requestBody() == nil || vm.isSaving)
            }
        }
        .confirmationDialog(
            bulkConfirmation?.title ?? "",
            isPresented: Binding(get: { bulkConfirmation != nil }, set: { if !$0 { confirmingForm = nil } }),
            presenting: bulkConfirmation
        ) { confirmation in
            Button("Create \(confirmation.count) Instances") {
                if let confirmingForm { create(confirmingForm) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { confirmation in
            Text(confirmation.message)
        }
    }

    @ViewBuilder
    private var advancedOptions: some View {
        Stepper(value: $form.count, in: 1...maximumCount) {
            Text("Number of instances: \(form.count)")
        }
        Group {
            switch vm.creationCapacity(for: form) {
            case nil:
                Text("The quota could not be loaded, so only one instance can be created at a time.")
            case let capacity? where capacity < 1:
                Text("The remaining quota is used up for this size. Civo refuses instances beyond the quota.")
            default:
                Text("The remaining quota allows up to \(maximumCount) instances of this size.")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        Toggle("Public IP address", isOn: $form.createsPublicIp)
        if !form.createsPublicIp {
            Text("Without a public IP address, the instance is reachable only inside its network, and the detail view shows no SSH command.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        TextField("Initial User", text: $form.initialUser, prompt: Text("Default user of the disk image"))
        TextField("Reverse DNS", text: $form.reverseDns)

        VStack(alignment: .leading, spacing: 4) {
            Text("Startup Script")
            ScriptEditor(text: $form.script)
                .frame(minHeight: 120)
            Text("Civo runs the script as root at the end of the first boot.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var bulkConfirmation: BulkCreationConfirmation? {
        confirmingForm.flatMap { BulkCreationConfirmation(count: $0.count, size: $0.size, rates: CivoCharge.hourlyRates) }
    }

    private func create(_ form: InstanceCreationForm) {
        Task { _ = await vm.createInstance(form) }
    }
}

/// A monospaced plain-text editor without smart quotes, dashes or other substitutions,
/// which would change a shell script.
private struct ScriptEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.setAccessibilityLabel(String(localized: "Startup Script"))
        textView.delegate = context.coordinator
        textView.string = text
        scrollView.borderType = .bezelBorder
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else { return }
        textView.string = text
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
