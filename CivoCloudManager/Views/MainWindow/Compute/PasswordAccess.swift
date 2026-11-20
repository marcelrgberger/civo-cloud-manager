import AppKit
import LocalAuthentication
import SwiftUI

/// Result of asking for Touch ID or the macOS system password.
enum DeviceOwnerAuthentication: Equatable, Sendable {
    case granted
    case denied
    /// The Mac offers neither Touch ID nor a system password, or LocalAuthentication is unavailable.
    case unavailable
}

/// Touch ID or system password (`.deviceOwnerAuthentication`). A fresh context per request, so no
/// earlier authentication is reused.
@MainActor
enum DeviceOwner {
    private static let cancellations: Set<LAError.Code> = [.userCancel, .systemCancel, .appCancel]

    static func authenticate(reason: String) async -> DeviceOwnerAuthentication {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return .unavailable }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) ? .granted : .denied
        } catch let error as LAError where cancellations.contains(error.code) {
            return .denied
        } catch {
            Log.error("Device owner authentication failed: \(error.localizedDescription)")
            return .denied
        }
    }
}

/// Reveals or copies a password only after owner authentication; without any owner authentication
/// it stays hidden. Authentication can take long; if the view goes away, the app deactivates, the
/// screen locks, the API key changes or Full Access ends meanwhile, `invalidate()` makes every
/// pending reveal or copy a no-op once authentication returns.
@Observable
@MainActor
final class PasswordAccess {
    struct LockEvent {
        let center: NotificationCenter
        let name: Notification.Name
    }

    /// A revealed password hides itself again after this time.
    static let visibleDuration: Duration = .seconds(30)

    /// Events after which nobody may be watching the screen anymore.
    static var systemLockEvents: [LockEvent] {
        let workspace = NSWorkspace.shared.notificationCenter
        return [
            LockEvent(center: .default, name: NSApplication.didResignActiveNotification),
            LockEvent(center: workspace, name: NSWorkspace.screensDidSleepNotification),
            LockEvent(center: workspace, name: NSWorkspace.willSleepNotification),
            LockEvent(center: workspace, name: NSWorkspace.sessionDidResignActiveNotification),
            // Posted by the system when the screen is locked; not declared in the SDK.
            LockEvent(center: DistributedNotificationCenter.default(), name: Notification.Name("com.apple.screenIsLocked")),
        ]
    }

    private(set) var isRevealed = false
    private(set) var isDeviceAuthenticationUnavailable = false
    private var generation = 0
    private let authenticate: @MainActor (String) async -> DeviceOwnerAuthentication
    private let writeToPasteboard: @MainActor (String) -> Void
    private let lockEvents: [LockEvent]?
    @ObservationIgnored private var lockObservers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    init(
        authenticate: (@MainActor (String) async -> DeviceOwnerAuthentication)? = nil,
        writeToPasteboard: (@MainActor (String) -> Void)? = nil,
        lockEvents: [LockEvent]? = nil
    ) {
        self.authenticate = authenticate ?? { await DeviceOwner.authenticate(reason: $0) }
        self.writeToPasteboard = writeToPasteboard ?? { SecretPasteboard.copy($0) }
        self.lockEvents = lockEvents
    }

    func reveal() async {
        guard await authorize(reason: String(localized: "View instance password")) else { return }
        isRevealed = true
    }

    func hide() {
        isRevealed = false
    }

    /// A hidden password is copied only after the same authentication that reveals it.
    /// Returns whether the password was written to the pasteboard.
    func copy(_ password: String) async -> Bool {
        if !isRevealed {
            guard await authorize(reason: String(localized: "Copy instance password")) else { return false }
        }
        writeToPasteboard(password)
        return true
    }

    /// Hides the password and discards every reveal or copy still waiting for authentication.
    func invalidate() {
        generation += 1
        isRevealed = false
    }

    /// Calls `invalidate()` on every lock event until `stopObservingLockEvents()`.
    func observeLockEvents() {
        stopObservingLockEvents()
        lockObservers = (lockEvents ?? Self.systemLockEvents).map { event in
            let token = event.center.addObserver(forName: event.name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.invalidate() }
            }
            return (event.center, token)
        }
    }

    func stopObservingLockEvents() {
        for observer in lockObservers {
            observer.center.removeObserver(observer.token)
        }
        lockObservers = []
    }

    /// True only if authentication succeeded and nothing invalidated access while it ran.
    private func authorize(reason: String) async -> Bool {
        let started = generation
        let outcome = await authenticate(reason)
        guard started == generation else { return false }
        isDeviceAuthenticationUnavailable = outcome == .unavailable
        return outcome == .granted
    }
}

extension View {
    /// Hides the password after `PasswordAccess.visibleDuration`, on lock events and when the view goes away.
    func relocksPassword(_ access: PasswordAccess) -> some View {
        modifier(PasswordRelocking(access: access))
    }
}

private struct PasswordRelocking: ViewModifier {
    let access: PasswordAccess

    func body(content: Content) -> some View {
        content
            .task(id: access.isRevealed) {
                guard access.isRevealed else { return }
                try? await Task.sleep(for: PasswordAccess.visibleDuration)
                if !Task.isCancelled { access.invalidate() }
            }
            .onAppear { access.observeLockEvents() }
            .onDisappear {
                access.invalidate()
                access.stopObservingLockEvents()
            }
    }
}

/// Shown when the Mac cannot confirm its owner, so the password stays hidden.
struct DeviceAuthenticationRequiredHint: View {
    var body: some View {
        Label("Touch ID or a system password is required to show or copy the password.", systemImage: "lock")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

/// Copies a secret for an explicit paste. It is marked as concealed (nspasteboard.org) so clipboard
/// managers do not record it, and cleared after `lifetime` or when the app quits, unless something
/// else was copied since.
@MainActor
enum SecretPasteboard {
    static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    static let lifetime: Duration = .seconds(90)

    private static var pending: (pasteboard: NSPasteboard, changeCount: Int)?
    private static var terminationObserver: NSObjectProtocol?

    static func copy(_ secret: String, to pasteboard: NSPasteboard = .general) {
        let changeCount = write(secret, to: pasteboard)
        pending = (pasteboard, changeCount)
        terminationObserver = terminationObserver ?? NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { clearPending() }
        }
        Task {
            try? await Task.sleep(for: lifetime)
            if pending?.changeCount == changeCount { clearPending() }
        }
    }

    private static func clearPending() {
        guard let pending else { return }
        clear(pending.pasteboard, ifUnchangedSince: pending.changeCount)
        self.pending = nil
    }

    /// Writes the secret with the concealed marker and returns the resulting change count.
    @discardableResult
    static func write(_ secret: String, to pasteboard: NSPasteboard) -> Int {
        pasteboard.clearContents()
        pasteboard.setString(secret, forType: .string)
        pasteboard.setString("", forType: concealedType)
        return pasteboard.changeCount
    }

    static func clear(_ pasteboard: NSPasteboard, ifUnchangedSince changeCount: Int) {
        guard pasteboard.changeCount == changeCount else { return }
        pasteboard.clearContents()
    }
}
