import SwiftUI

@main
struct CivoCloudManagerApp: App {
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    init() {
        StoreManager.shared.startListening()
        NotificationService.shared.requestPermission()
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
