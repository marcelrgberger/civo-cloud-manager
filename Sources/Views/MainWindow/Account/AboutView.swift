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
                    Link("Privacy Policy", destination: URL(string: "https://marcelrgberger.com/privacy")!)
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                .font(.caption)
                .foregroundStyle(.blue)

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About")
    }
}
