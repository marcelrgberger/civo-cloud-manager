import SwiftUI

/// The instance's tags as chips, edited inline like the reverse DNS. Saving never clears the tags:
/// that is only done by "Remove All Tags...", which asks first.
struct InstanceTagsEditor: View {
    let instance: CivoInstance
    let vm: InstanceViewModel
    /// Set while the tags are edited, captured when editing starts.
    @State private var editTarget: ConsoleTarget?
    @State private var input = ""
    @State private var isSaving = false

    private var tags: [String] { instance.tags ?? [] }

    /// The change Save would send, or why it cannot be sent.
    private var parsedInput: Result<InstanceTagChange, InstanceTagInputError> {
        Result { () throws(InstanceTagInputError) in try InstanceTagChange.replacing(with: input) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tags")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let target = editTarget {
                editor(target)
            } else {
                display
            }
        }
        .onChange(of: instance.id) { editTarget = nil }
        .alert(
            Text("Remove all tags from \(vm.pendingAction?.target.instanceName ?? instance.name)?"),
            isPresented: Binding(
                get: { vm.pendingAction?.kind == .removeAllTags && vm.pendingAction?.target.instanceId == instance.id },
                set: { if !$0 { vm.cancelConfirmation() } }
            )
        ) {
            Button("Remove All Tags", role: .destructive) {
                guard let target = vm.confirmPendingAction() else { return }
                Task { await vm.removeAllTags(of: target) }
            }
            Button("Cancel", role: .cancel) { vm.cancelConfirmation() }
        } message: {
            Text("Civo removes every tag from this instance.")
        }
    }

    private var display: some View {
        HStack(spacing: 6) {
            if tags.isEmpty {
                Text("No tags")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text(verbatim: tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            if let target = vm.consoleTarget(for: instance) {
                Button {
                    input = tags.joined(separator: ", ")
                    editTarget = target
                } label: {
                    Label("Edit tags", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Edit tags")
                if !tags.isEmpty {
                    Button {
                        vm.beginConfirmation(.removeAllTags, for: instance)
                    } label: {
                        Label("Remove All Tags...", systemImage: "trash")
                            .labelStyle(.iconOnly)
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove All Tags...")
                }
            }
        }
    }

    private func editor(_ target: ConsoleTarget) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("e.g. web, production", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                    .onSubmit { save(target) }
                Button("Save") { save(target) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!canSave)
                Button("Cancel") { editTarget = nil }
                    .controlSize(.small)
            }
            // The answer closes the editor, so nothing may be changed while it is awaited.
            .disabled(isSaving)
            if case .failure(let problem) = parsedInput {
                Text(verbatim: problem.message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Separate tags with commas.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// Valid input that differs from the current tags.
    private var canSave: Bool {
        guard !isSaving, case .success(let change) = parsedInput else { return false }
        return change.tags != tags
    }

    private func save(_ target: ConsoleTarget) {
        guard canSave else { return }
        isSaving = true
        let input = input
        Task {
            if await vm.setTags(input, of: target) { editTarget = nil }
            isSaving = false
        }
    }
}
