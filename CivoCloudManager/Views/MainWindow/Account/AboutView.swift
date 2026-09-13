import SwiftUI

struct AboutView: View {
    @Environment(\.openWindow) private var openWindow
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text("Civo Cloud Manager")
                    .font(.largeTitle.bold())

                Text("Version \(version) (\(build))")
                    .font(.title3.monospaced())
                    .foregroundStyle(.secondary)

                Divider()
                    .frame(width: 200)

                VStack(spacing: 6) {
                    Text("DigitalFreedom")
                        .font(.headline)
                    Text("A brand of DigitalFreedom Global LLC")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Link("digitalfreedom.co.za", destination: URL(string: "https://digitalfreedom.co.za")!)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Copyright \u{00A9} 2025\u{2013}2026 DigitalFreedom Global LLC.\nAll rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Divider()
                    .frame(width: 200)

                VStack(spacing: 8) {
                    Button("Legal Information") { openWindow(id: "legal") }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Divider()
                    .frame(width: 200)

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About")
    }

}
