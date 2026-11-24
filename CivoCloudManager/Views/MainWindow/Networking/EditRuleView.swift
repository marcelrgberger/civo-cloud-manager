import SwiftUI

/// Edits protocol, ports, CIDR, direction and label of one rule. The action stays as it is,
/// since Civo's rule update does not take it.
struct EditRuleView: View {
    @Bindable var editor: FirewallRuleEditor
    let session: FirewallRuleEditor.Session
    let onSave: (FirewallRuleDraft) -> Void

    @State private var draft: FirewallRuleDraft
    @State private var confirmWarnings = false

    init(editor: FirewallRuleEditor, session: FirewallRuleEditor.Session, onSave: @escaping (FirewallRuleDraft) -> Void) {
        self.editor = editor
        self.session = session
        self.onSave = onSave
        _draft = State(initialValue: FirewallRuleDraft(rule: session.original))
    }

    private var original: CivoRule { editor.session?.original ?? session.original }
    private var changes: [FirewallRuleChange] { draft.changes(from: original) }
    private var warnings: [FirewallRuleWarning] { draft.warnings(editing: original, currentIP: editor.currentIP) }

    /// The known protocols, plus the rule's own value when Civo reports another one.
    private var protocols: [String] {
        let current = original.proto ?? ""
        return FirewallRuleDraft.protocols.contains(current) || current.isEmpty
            ? FirewallRuleDraft.protocols : [current] + FirewallRuleDraft.protocols
    }

    var body: some View {
        Form {
            Section("Rule Details") {
                Picker("Protocol", selection: $draft.proto) {
                    ForEach(protocols, id: \.self) { Text(verbatim: $0) }
                }
                TextField("Start Port", text: $draft.startPort)
                    .accessibilityIdentifier(AccessibilityID.ruleStartPort)
                    .help("e.g. 80, 443, 6443")
                TextField("End Port (optional)", text: $draft.endPort)
                    .help("Leave empty for single port")
                TextField("CIDR", text: $draft.cidr)
                    .help("e.g. 0.0.0.0/0 for all, or 10.0.0.1/32 for single IP")
                Picker("Direction", selection: $draft.direction) {
                    ForEach(FirewallRuleDraft.directions, id: \.self) { Text(verbatim: $0) }
                }
                TextField("Label (optional)", text: $draft.label)
                LabeledContent("Action") {
                    Text(verbatim: original.action ?? "-")
                }
                .help("Civo does not allow changing the action of an existing rule.")
            }

            Section("Before and After") {
                if changes.isEmpty {
                    Text("No changes yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        GridRow {
                            Text("Field")
                            Text("Before")
                            Text("After")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        ForEach(changes, id: \.field) { change in
                            GridRow {
                                Text(Self.title(of: change.field))
                                comparisonValue(change.before)
                                comparisonValue(change.after)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(AccessibilityID.ruleChanges)
                }
            }

            if !warnings.isEmpty {
                Section {
                    ForEach(warnings, id: \.self) { warning in
                        Label(warning.message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            if !changes.isEmpty, let problem = draft.problem {
                Section {
                    Text(problem.message).foregroundStyle(.red)
                }
            }
            if let error = editor.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Rule")
        .task { await editor.detectCurrentIP() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { editor.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if warnings.isEmpty { onSave(draft) } else { confirmWarnings = true }
                }
                .disabled(changes.isEmpty || draft.problem != nil || editor.isSaving)
            }
        }
        .confirmationDialog("Save this rule change?", isPresented: $confirmWarnings) {
            Button("Save Anyway", role: .destructive) { onSave(draft) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(warnings.map(\.message).joined(separator: "\n\n"))
        }
    }

    private func comparisonValue(_ value: String) -> some View {
        Group {
            if value.isEmpty {
                Text("none").foregroundStyle(.secondary)
            } else {
                Text(verbatim: value)
            }
        }
        .textSelection(.enabled)
    }

    private static func title(of field: FirewallRuleChange.Field) -> LocalizedStringKey {
        switch field {
        case .protocol: "Protocol"
        case .ports: "Ports"
        case .cidr: "CIDR"
        case .direction: "Direction"
        case .label: "Label"
        }
    }
}
