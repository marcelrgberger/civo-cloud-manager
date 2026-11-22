import SwiftUI

/// Changes name, algorithm and traffic policy of one load balancer and adds backends. Existing backends stay as
/// they are; a comparison shows the values before and after.
struct EditLoadBalancerView: View {
    @Bindable var editor: LoadBalancerEditor
    let session: LoadBalancerEditor.Session
    let onSave: (LoadBalancerDraft) -> Void

    @State private var draft: LoadBalancerDraft

    init(editor: LoadBalancerEditor, session: LoadBalancerEditor.Session, onSave: @escaping (LoadBalancerDraft) -> Void) {
        self.editor = editor
        self.session = session
        self.onSave = onSave
        _draft = State(initialValue: LoadBalancerDraft(editing: session.original))
    }

    private var original: CivoLoadBalancer { editor.session?.original ?? session.original }
    private var changes: [LoadBalancerChange] { draft.changes(from: original) }
    private var problems: [LoadBalancerDraftProblem] { draft.problems(editing: original) }

    /// The known algorithms, plus the load balancer's own value when Civo reports another one.
    private var algorithms: [String] {
        let known = LoadBalancerAlgorithm.allCases.map(\.rawValue)
        let current = original.algorithm ?? ""
        return known.contains(current) ? known : [current] + known
    }

    var body: some View {
        Form {
            Section("Load Balancer Details") {
                TextField("Name", text: $draft.name)
                Picker("Algorithm", selection: $draft.algorithm) {
                    ForEach(algorithms, id: \.self) { Text(LoadBalancerAlgorithm.title(of: $0)).tag($0) }
                }
                if draft.trafficPolicy == nil {
                    LabeledContent("Traffic Policy") {
                        Text("Not reported by Civo").foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Traffic Policy", selection: $draft.trafficPolicy) {
                        ForEach(LoadBalancerTrafficPolicy.allCases, id: \.self) { Text(verbatim: $0.rawValue).tag(Optional($0)) }
                    }
                }
            }

            Section {
                LoadBalancerBackendTable(existing: original.backendEntries ?? [], rows: $draft.backends)
            } header: {
                Text("Backends")
            } footer: {
                Text("Existing backends cannot be removed or changed in the app yet. Use the Civo dashboard for that.")
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
                        ForEach(changes) { change in
                            GridRow {
                                Text(Self.title(of: change.field))
                                comparisonValue(change.before)
                                comparisonValue(change.after)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }

            if !draft.backends.isEmpty {
                Section {
                    Label("Changing the backends can interrupt traffic through this load balancer.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if !changes.isEmpty, !problems.isEmpty {
                Section {
                    ForEach(problems, id: \.self) { Text($0.message).foregroundStyle(.red) }
                }
            }
            if let error = editor.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Load Balancer")
        .interactiveDismissDisabled(editor.isSaving)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { editor.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave(draft) }
                    .disabled(changes.isEmpty || !problems.isEmpty || editor.isSaving)
            }
        }
    }

    private func comparisonValue(_ value: String) -> some View {
        Group {
            if value.isEmpty {
                Text("none").foregroundStyle(.secondary)
            } else {
                Text(verbatim: value)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .textSelection(.enabled)
    }

    private static func title(of field: LoadBalancerChange.Field) -> LocalizedStringKey {
        switch field {
        case .name: "Name"
        case .algorithm: "Algorithm"
        case .trafficPolicy: "Traffic Policy"
        case .addedBackend: "Added Backend"
        }
    }
}
