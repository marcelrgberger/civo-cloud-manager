import SwiftUI
import LocalAuthentication

struct DatabaseDetailView: View {
    let db: CivoDatabase
    let onBack: () -> Void
    @State private var appeared = false
    @State private var passwordRevealed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                credentialsSection
                connectionSection
                configSection
                networkSection
            }
            .padding(24)
        }
        .navigationTitle(db.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
                    .help("Return to list")
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(db.name)
                    .font(.largeTitle.bold())
                HStack(spacing: 8) {
                    Text(db.software ?? "—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let v = db.softwareVersion {
                        Text("v\(v)")
                            .font(.caption.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            StatusBadge(status: db.status)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var connectionSection: some View {
        GroupBox("Connection") {
            VStack(alignment: .leading, spacing: 10) {
                if let host = db.publicIpv4 {
                    infoRow("Host", host)
                }
                if let priv = db.privateIpv4 {
                    infoRow("Private IP", priv)
                }
                if let port = db.port {
                    infoRow("Port", "\(port)")
                }
                if let dns = db.dnsEntry {
                    infoRow("DNS", dns)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Configuration") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Size", db.size ?? "—")
                infoRow("Nodes", db.nodes.map(String.init) ?? "—")
                infoRow("Region", db.region ?? CivoConfig.shared.region)
                infoRow("Created", db.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private var networkSection: some View {
        GroupBox("Network & Security") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow("Network ID", db.networkId ?? "Default")
                infoRow("Firewall ID", db.firewallId ?? "Default")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private var credentialsSection: some View {
        GroupBox("Credentials") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow("Username", db.username ?? "—")
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Password").font(.caption).foregroundStyle(.secondary)
                        if passwordRevealed {
                            Text(db.password ?? "—")
                                .font(.subheadline.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Text(String(repeating: "*", count: 20))
                                .font(.subheadline.monospaced())
                        }
                    }
                    Spacer()
                    Button {
                        if passwordRevealed {
                            passwordRevealed = false
                        } else {
                            Task { await authenticateAndReveal() }
                        }
                    } label: {
                        Image(systemName: passwordRevealed ? "eye.slash" : "eye")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.08), value: appeared)
    }

    private func authenticateAndReveal() async {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Reveal database password")
            passwordRevealed = success
        } catch {
            // User cancelled or auth failed
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}
