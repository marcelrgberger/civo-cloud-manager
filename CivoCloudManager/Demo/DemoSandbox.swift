#if DEBUG
import AppKit
import Foundation

/// Throwaway state of one demo run: an ephemeral defaults suite and a temporary directory, both removed on exit.
final class DemoSandbox: @unchecked Sendable {
    static let shared = DemoSandbox()

    let defaults: UserDefaults
    let directory: URL
    private let suiteName = "CivoCloudManager.demo.\(UUID().uuidString)"

    private init() {
        directory = FileManager.default.temporaryDirectory.appending(path: suiteName, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults()
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: nil
        ) { [self] _ in remove() }
    }

    private func remove() {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }
}
#endif
