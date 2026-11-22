import SwiftUI

/// The backends of a load balancer: the existing ones read only, new ones with IP, protocol and ports to type in.
/// Addresses, protocols and ports read left to right in every language.
struct LoadBalancerBackendTable: View {
    let existing: [LoadBalancerBackend]
    @Binding var rows: [LoadBalancerBackendRow]
    var allowsAdding = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                GridRow {
                    Text("IP Address")
                    Text("Protocol")
                    Text("Source Port")
                    Text("Target Port")
                    if allowsAdding { Text(verbatim: "") }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                ForEach(Array(existing.enumerated()), id: \.offset) { _, backend in
                    GridRow {
                        technical(backend.ip)
                        technical(backend.protocol ?? "-")
                        technical(backend.sourcePort.map(String.init) ?? "-")
                        technical(backend.targetPort.map(String.init) ?? "-")
                        if allowsAdding { Text(verbatim: "") }
                    }
                }

                ForEach($rows) { $row in
                    GridRow {
                        TextField("IP Address", text: $row.ip)
                            .frame(minWidth: 140)
                            .leftToRight()
                        Picker("Protocol", selection: $row.proto) {
                            ForEach(LoadBalancerDraft.protocols, id: \.self) { Text(verbatim: $0) }
                        }
                        .fixedSize()
                        TextField("Source Port", text: $row.sourcePort)
                            .frame(width: 80)
                            .leftToRight()
                        TextField("Target Port", text: $row.targetPort)
                            .frame(width: 80)
                            .leftToRight()
                        Button {
                            rows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove Backend")
                        .accessibilityLabel("Remove Backend")
                    }
                    .labelsHidden()
                }
            }

            if allowsAdding {
                Button("Add Backend", systemImage: "plus") {
                    rows.append(LoadBalancerBackendRow())
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func technical(_ value: String) -> some View {
        Text(verbatim: value)
            .font(.subheadline.monospaced())
            .textSelection(.enabled)
            .leftToRight()
    }
}

private extension View {
    /// `Text(verbatim:)` alone keeps the layout direction of the language, which would mirror addresses in Arabic.
    func leftToRight() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }
}
