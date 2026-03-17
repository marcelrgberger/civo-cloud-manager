import SwiftUI

@main
struct CivoCloudManagerApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(state: appState)
                .onChange(of: appState.showOnboarding) { _, newValue in
                    if newValue {
                        openWindow(id: "onboarding")
                        appState.showOnboarding = false
                    }
                }
        } label: {
            Image(systemName: appState.menuBarIcon)
                .renderingMode(.template)
                .symbolRenderingMode(.palette)
                .foregroundStyle(appState.menuBarColor)
        }
        .menuBarExtraStyle(.window)

        Window("Civo Cloud Manager Setup", id: "onboarding") {
            OnboardingView(state: appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

/// Forces the app to run as a menu-bar-only agent (no Dock icon).
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
