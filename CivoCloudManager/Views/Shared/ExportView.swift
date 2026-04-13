import SwiftUI

struct ExportView: View {
    let instanceVM: InstanceViewModel
    let kubernetesVM: KubernetesViewModel
    let databaseVM: DatabaseViewModel
    let networkVM: NetworkViewModel
    let volumeVM: VolumeViewModel
    let domainVM: DomainViewModel

    @State private var selectAll = true
    @State private var selectedTypes: Set<String> = []
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportDone = false
    @Environment(\.dismiss) private var dismiss

    private let resourceTypes = [
        ("instances", "Instances"),
        ("sshKeys", "SSH Keys"),
        ("clusters", "Kubernetes Clusters"),
        ("databases", "Databases"),
        ("networks", "Networks"),
        ("firewalls", "Firewalls"),
        ("loadBalancers", "Load Balancers"),
        ("domains", "Domains"),
        ("volumes", "Volumes"),
        ("objectStores", "Object Stores"),
    ]

    private var effectiveSelection: Set<String> {
        selectAll ? Set(resourceTypes.map(\.0)) : selectedTypes
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Resources")
                .font(.title2.bold())

            Text("Export your Civo resources as a JSON backup file.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GroupBox("Select Resources") {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("All Resources", isOn: $selectAll)
                        .toggleStyle(.checkbox)
                        .fontWeight(.medium)
                    Divider()
                    ForEach(resourceTypes, id: \.0) { key, label in
                        Toggle(label, isOn: Binding(
                            get: { selectAll || selectedTypes.contains(key) },
                            set: { on in
                                selectAll = false
                                if on { selectedTypes.insert(key) }
                                else { selectedTypes.remove(key) }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .disabled(selectAll)
                    }
                }
                .padding(4)
            }

            if let exportError {
                Text(exportError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    Task { await exportResources() }
                } label: {
                    if isExporting {
                        ProgressView().controlSize(.small)
                    } else if exportDone {
                        Label("Exported", systemImage: "checkmark.circle.fill")
                    } else {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(effectiveSelection.isEmpty || isExporting)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    private func exportResources() async {
        isExporting = true
        exportError = nil
        defer { isExporting = false }

        let sel = effectiveSelection
        let now = Date()
        var export: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: now),
            "region": CivoConfig.shared.region,
            "note": "Credentials and secrets are redacted for security.",
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        func encode<T: Encodable>(_ value: T) -> Any? {
            guard let data = try? encoder.encode(value),
                  let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
            return json
        }

        if sel.contains("instances") { export["instances"] = encode(instanceVM.instances) }
        if sel.contains("sshKeys") { export["sshKeys"] = encode(instanceVM.sshKeys) }
        if sel.contains("clusters") { export["clusters"] = encode(kubernetesVM.clusters) }
        if sel.contains("databases") { export["databases"] = encode(databaseVM.databases) }
        if sel.contains("networks") { export["networks"] = encode(networkVM.networks) }
        if sel.contains("firewalls") { export["firewalls"] = encode(networkVM.firewalls) }
        if sel.contains("loadBalancers") { export["loadBalancers"] = encode(networkVM.loadBalancers) }
        if sel.contains("domains") { export["domains"] = encode(domainVM.domains) }
        if sel.contains("volumes") { export["volumes"] = encode(volumeVM.volumes) }
        if sel.contains("objectStores") { export["objectStores"] = encode(volumeVM.objectStores) }

        // Redact sensitive fields
        redactSecrets(&export)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys]) else {
            exportError = "Failed to serialize export data"
            return
        }

        let dateStr = ISO8601DateFormatter().string(from: now).prefix(10)
        let fileName = "civo-export-\(CivoConfig.shared.region)-\(dateStr).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: tempURL)
            NSWorkspace.shared.activateFileViewerSelecting([tempURL])
            exportDone = true
        } catch {
            exportError = "Failed to write file: \(error.localizedDescription)"
        }
    }

    private func redactSecrets(_ export: inout [String: Any]) {
        let sensitiveKeys: Set<String> = [
            "password", "initial_password", "initialPassword",
            "secret_access_key_id", "secretAccessKeyId",
            "kubeconfig", "client_certificate", "client_key",
        ]

        func redact(_ obj: Any) -> Any {
            if var dict = obj as? [String: Any] {
                for (key, value) in dict {
                    if sensitiveKeys.contains(key) {
                        dict[key] = "[REDACTED]"
                    } else {
                        dict[key] = redact(value)
                    }
                }
                return dict
            } else if let arr = obj as? [Any] {
                return arr.map { redact($0) }
            }
            return obj
        }

        for (key, value) in export {
            export[key] = redact(value)
        }
    }
}
