import SwiftUI

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "shield.checkered")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Civo Cloud Manager")
                    .font(.largeTitle.bold())

                Text("Version \(version) (\(build))")
                    .font(.title3.monospaced())
                    .foregroundStyle(.secondary)

                Divider()
                    .frame(width: 200)

                VStack(spacing: 6) {
                    Text("Marcel R. G. Berger")
                        .font(.headline)
                    Text("Berger & Rosenstock GbR")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Copyright \u{00A9} 2026 Marcel R. G. Berger.\nAll rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Divider()
                    .frame(width: 200)

                VStack(spacing: 8) {
                    Link("Privacy Policy", destination: URL(string: "https://berger-rosenstock.de/data-protection")!)
                    Link("Terms of Use", destination: URL(string: "https://civo-cloud-manager.app/terms")!)
                    Link("Imprint", destination: URL(string: "https://berger-rosenstock.de/imprint")!)
                    Link("Website", destination: URL(string: "https://civo-cloud-manager.app")!)
                }
                .font(.caption)
                .foregroundStyle(.blue)

                Divider()
                    .frame(width: 200)

                systemToolsSection

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About")
    }

    // MARK: - System Tools

    private var systemToolsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Tools")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text("This app uses the following tools pre-installed on macOS. No additional software is required.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 6) {
                toolRow(
                    name: "/usr/bin/openssl",
                    purpose: "Kubernetes client certificate authentication (PKCS#12)",
                    available: FileManager.default.fileExists(atPath: "/usr/bin/openssl")
                )
                toolRow(
                    name: "/usr/bin/ssh-keygen",
                    purpose: "SSH key pair generation (Ed25519)",
                    available: FileManager.default.fileExists(atPath: "/usr/bin/ssh-keygen")
                )
            }
        }
        .padding(.horizontal, 40)
    }

    private func toolRow(name: String, purpose: String, available: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .red)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption.monospaced().bold())
                Text(purpose)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
