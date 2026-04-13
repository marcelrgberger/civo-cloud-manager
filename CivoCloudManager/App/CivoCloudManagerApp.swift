import SwiftUI

@main
struct CivoCloudManagerApp: App {
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    init() {
        // Start as menu-bar-only (no Dock icon) — windows promote to .regular when opened
        // NSApp may be nil during init, so defer activation policy to first run loop cycle
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
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
                .onDisappear { hideFromDockIfNoWindows() }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Civo Cloud Manager", id: "main") {
            MainWindowView()
                .onDisappear { hideFromDockIfNoWindows() }
        }
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Civo Cloud Manager Help") {
                    NSApp.activate()
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Window("Civo Cloud Manager Help", id: "help") {
            HelpView()
                .onDisappear { hideFromDockIfNoWindows() }
        }
        .defaultSize(width: 650, height: 700)
        .defaultPosition(.center)
    }

    private func hideFromDockIfNoWindows() {
        // Delay slightly to let SwiftUI finish closing the window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let hasVisibleWindow = NSApp.windows.contains { window in
                window.isVisible && !window.className.contains("StatusBar")
                    && !window.className.contains("MenuBarExtra")
            }
            if !hasVisibleWindow {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
