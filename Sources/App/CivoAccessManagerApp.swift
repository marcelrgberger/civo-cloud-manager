import SwiftUI

@main
struct CivoAccessManagerApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(state: appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
                .renderingMode(.template)
                .symbolRenderingMode(.palette)
                .foregroundStyle(appState.menuBarColor)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Forces the app to run as a menu-bar-only agent (no Dock icon).
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
