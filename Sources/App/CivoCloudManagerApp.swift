import SwiftUI

@main
struct CivoCloudManagerApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

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
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
