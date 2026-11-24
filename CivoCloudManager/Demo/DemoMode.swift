import Foundation

/// Demo data mode for the store screenshots: the real views run on fictional data from `DemoURLProtocol`.
/// The mode exists in Debug builds only; in Release builds `isActive` is a constant false and no demo code is compiled.
enum DemoMode {
    #if DEBUG
    static let launchArgument = "-CCMDemoData"

    /// Read from the process arguments only, never from stored defaults, so no persisted value can switch it on.
    static let isActive = ProcessInfo.processInfo.arguments.contains(launchArgument)

    /// Stand-in key and region: the Keychain and the stored region are never read in demo mode.
    static let apiKey = DemoFixtures.placeholderAPIKey
    static let region = DemoFixtures.region
    #else
    static let isActive = false
    static let apiKey = ""
    static let region = ""
    #endif
}

/// Where the app keeps its state. Real locations normally; in demo mode a throwaway sandbox, so a demo run
/// never reads or changes the defaults, caches or queued jobs of the installed app.
enum AppEnvironment {
    static var defaults: UserDefaults {
        #if DEBUG
        if DemoMode.isActive { return DemoSandbox.shared.defaults }
        #endif
        return .standard
    }

    static var supportDirectory: URL {
        #if DEBUG
        if DemoMode.isActive { return DemoSandbox.shared.directory }
        #endif
        return .applicationSupportDirectory
    }
}

/// Network access of the app's own sessions. Outside demo mode every call passes through unchanged.
enum DemoNetwork {
    /// The session configuration to use: in demo mode it answers locally instead of reaching any server.
    static func configuration(_ base: URLSessionConfiguration) -> URLSessionConfiguration {
        #if DEBUG
        if DemoMode.isActive { DemoURLProtocol.isolate(base) }
        #endif
        return base
    }

    /// Replaces `URLSession.shared`, which only global protocol registration could intercept.
    static let sharedSession: URLSession = {
        #if DEBUG
        if DemoMode.isActive { return URLSession(configuration: configuration(.ephemeral)) }
        #endif
        return .shared
    }()
}
