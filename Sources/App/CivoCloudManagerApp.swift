import SwiftUI

@main
struct CivoCloudManagerApp: App {
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    init() {
        StoreManager.shared.startListening()
        NotificationService.shared.requestPermission()
        Task { await Self.checkForNewInvoices() }
    }

    private static func checkForNewInvoices() async {
        guard CivoConfig.shared.hasAPIKey else { return }
        do {
            let invoices = try await CivoChargesService().getInvoices()
            let lastKnownId = UserDefaults.standard.string(forKey: "lastKnownInvoiceId")
            if let latest = invoices.first, latest.id != lastKnownId {
                if lastKnownId != nil {
                    let amount = latest.total.map { String(format: "$%.2f", $0) } ?? ""
                    NotificationService.shared.sendAlert(
                        title: "New Civo Invoice",
                        body: "Invoice \(latest.invoiceNumber ?? latest.id) \(amount) is available."
                    )
                }
                UserDefaults.standard.set(latest.id, forKey: "lastKnownInvoiceId")
            }
        } catch {
            // Silent — don't block app launch for invoice check
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(state: appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)

        Window("Civo Cloud Manager Setup", id: "onboarding") {
            OnboardingView(state: appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Civo Cloud Manager", id: "main") {
            MainWindowView()
        }
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Civo Cloud Manager Help") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Window("Civo Cloud Manager Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 650, height: 700)
        .defaultPosition(.center)
    }
}
