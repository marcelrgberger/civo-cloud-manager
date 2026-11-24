import SwiftUI

/// Picks a newer version for a cluster and asks once more, naming both versions, before the upgrade is sent.
/// The controller checks the captured target, the cluster and the version list again when the user confirms.
struct UpgradeClusterView: View {
    let controller: KubernetesUpgradeController
    let session: KubernetesUpgradeController.Session
    let onConfirm: (CivoKubernetesVersion) -> Void
    @State private var selectedVersion: String?
    @State private var isConfirming = false

    private var selected: CivoKubernetesVersion? {
        session.targets?.first { $0.version == selectedVersion }
    }

    var body: some View {
        Form {
            Section("Current Version") {
                Text(session.target.fromVersion)
                    .font(.body.monospaced())
            }

            Section {
                if let targets = session.targets {
                    Picker("Target Version", selection: $selectedVersion) {
                        Text("Choose a version").tag(String?.none)
                        ForEach(targets) { version in
                            Text(title(of: version)).tag(Optional(version.version))
                        }
                    }
                    .accessibilityIdentifier(AccessibilityID.upgradeVersionPicker)
                } else if controller.isLoadingVersions {
                    ProgressView("Loading versions...")
                } else {
                    Button("Retry") { Task { await controller.loadVersions() } }
                }
            } footer: {
                Text("Only versions newer than the current one are offered. Civo does not support downgrades and decides itself whether an upgrade path is allowed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Label("Workloads can be interrupted while Civo upgrades the cluster.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if let error = controller.sheetError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Upgrade \(session.target.clusterName)")
        .onAppear(perform: preselectRecommendation)
        .onChange(of: session.targets) { preselectRecommendation() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { controller.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Upgrade...") { isConfirming = true }
                    .disabled(selected == nil || controller.isSending || controller.isLoadingVersions)
            }
        }
        .confirmationDialog(
            Text("Upgrade \(session.target.clusterName) from \(session.target.fromVersion) to \(selected?.version ?? "")?"),
            isPresented: $isConfirming,
            titleVisibility: .visible,
            presenting: selected
        ) { version in
            Button("Upgrade to \(version.version)") { onConfirm(version) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Workloads can be interrupted while Civo upgrades the cluster. The cluster cannot be downgraded afterwards.")
        }
    }

    private func title(of version: CivoKubernetesVersion) -> String {
        let name = version.label ?? version.version
        guard isRecommended(version) else { return name }
        return String(localized: "\(name) (recommended by Civo)")
    }

    private func isRecommended(_ version: CivoKubernetesVersion) -> Bool {
        guard let hint = session.recommendedVersion.flatMap(KubernetesVersionNumber.init) else { return false }
        return version.number == hint
    }

    /// Civo's own upgrade hint is preselected; without one the user chooses.
    private func preselectRecommendation() {
        guard selectedVersion == nil else { return }
        selectedVersion = session.targets?.first(where: isRecommended)?.version
    }
}
