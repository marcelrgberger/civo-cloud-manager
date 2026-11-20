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

    /// Whether the Mac can confirm its owner at all; without it secrets are neither shown nor stored.
    static func canAuthenticate() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// Evaluates `context`, so a granted context can unlock one keychain read without a second prompt.
    static func authenticate(reason: String, context: LAContext = LAContext()) async -> DeviceOwnerAuthentication {
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
    /// Called on every `invalidate()`, so owners can drop secrets they loaded after authentication.
    @ObservationIgnored var onInvalidate: (@MainActor () -> Void)?
    private var generation = 0
    private let authenticate: @MainActor (String, LAContext) async -> DeviceOwnerAuthentication
    private let writeToPasteboard: @MainActor (String) -> Void
    private let lockEvents: [LockEvent]?
    @ObservationIgnored private var lockObservers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    init(
        authenticate: (@MainActor (String, LAContext) async -> DeviceOwnerAuthentication)? = nil,
        writeToPasteboard: (@MainActor (String) -> Void)? = nil,
        lockEvents: [LockEvent]? = nil
    ) {
        self.authenticate = authenticate ?? { await DeviceOwner.authenticate(reason: $0, context: $1) }
        self.writeToPasteboard = writeToPasteboard ?? { SecretPasteboard.copy($0) }
        self.lockEvents = lockEvents
    }

    func reveal() async {
        await reveal(reason: String(localized: "View instance password")) { _ in true }
    }

    /// Reveals once `load` succeeds with the authenticated context, e.g. a keychain read.
    func reveal(reason: String, load: (LAContext) -> Bool) async {
        guard let context = await authorize(reason: reason) else { return }
        defer { context.invalidate() }
        if load(context) { isRevealed = true }
    }

    func hide() {
        isRevealed = false
    }

    /// A hidden password is copied only after the same authentication that reveals it.
    /// Returns whether the password was written to the pasteboard.
    func copy(_ password: String) async -> Bool {
        await copy(reason: String(localized: "Copy instance password"), isVisible: isRevealed) { _ in password }
    }

    /// Copies what `secret` returns. A secret that is not visible is copied only after authentication;
    /// `secret` then receives the authenticated context, otherwise nil.
    func copy(reason: String, isVisible: Bool, secret: (LAContext?) -> String?) async -> Bool {
        var context: LAContext?
        if !isVisible {
            guard let authenticated = await authorize(reason: reason) else { return false }
            context = authenticated
        }
        defer { context?.invalidate() }
        guard let value = secret(context) else { return false }
        writeToPasteboard(value)
        return true
    }

    /// Hides the password and discards every reveal or copy still waiting for authentication.
    func invalidate() {
        generation += 1
        isRevealed = false
        onInvalidate?()
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

    /// The authenticated context, only if authentication succeeded and nothing invalidated access
    /// while it ran. The caller invalidates the context once its one action is done.
    func authorize(reason: String) async -> LAContext? {
        let started = generation
        let context = LAContext()
        let outcome = await authenticate(reason, context)
        guard started == generation, outcome == .granted else {
            if started == generation { isDeviceAuthenticationUnavailable = outcome == .unavailable }
            context.invalidate()
            return nil
        }
        isDeviceAuthenticationUnavailable = false
        return context
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

/// An editable text field for values that came out of the keychain. Copy and cut go through
/// `SecretPasteboard`; dragging, Services, sharing and Writing Tools get nothing.
struct ConcealedTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let field = ConcealedNSTextField(string: text)
        field.placeholderString = placeholder
        field.bezelStyle = .roundedBezel
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.cell?.isScrollable = true
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.text = $text
        if field.stringValue != text { field.stringValue = text }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }
    }
}

final class ConcealedNSTextField: NSTextField {
    override class var cellClass: AnyClass? {
        get { ConcealedTextFieldCell.self }
        set {}
    }
}

/// Edits with its own `ConcealedFieldEditor` instead of the window's shared field editor.
final class ConcealedTextFieldCell: NSTextFieldCell {
    private lazy var editor = ConcealedFieldEditor()

    override func fieldEditor(for controlView: NSView) -> NSTextView? {
        editor
    }
}

/// Field editor that hands copied text only to `copySecret`, by default `SecretPasteboard`.
final class ConcealedFieldEditor: NSTextView {
    private static let menuActions: Set<Selector> = [
        #selector(cut(_:)), #selector(copy(_:)), #selector(paste(_:)), #selector(selectAll(_:)),
    ]

    var copySecret: (String) -> Void = { SecretPasteboard.copy($0) }

    convenience init() {
        self.init(frame: .zero)
        isFieldEditor = true
        isRichText = false
        isContinuousSpellCheckingEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticTextCompletionEnabled = false
        writingToolsBehavior = .none
    }

    private var selectedString: String {
        let text = string as NSString
        return selectedRanges.map { text.substring(with: $0.rangeValue) }.joined()
    }

    override func copy(_ sender: Any?) {
        let selected = selectedString
        guard !selected.isEmpty else { return }
        copySecret(selected)
    }

    override func cut(_ sender: Any?) {
        guard !selectedString.isEmpty else { return }
        copy(sender)
        delete(sender)
    }

    // `delete(_:)` and the Emacs-style deletions (Control-K and friends) put the text into AppKit's
    // kill buffer, from which Control-Y inserts it anywhere. Deleting the selection backward does not.
    override func delete(_ sender: Any?) {
        guard selectedRange().length > 0 else { return }
        deleteBackward(sender)
    }

    override func deleteToEndOfLine(_ sender: Any?) {
        deleteSelection(orExtend: moveToEndOfLineAndModifySelection)
    }

    override func deleteToBeginningOfLine(_ sender: Any?) {
        deleteSelection(orExtend: moveToBeginningOfLineAndModifySelection)
    }

    override func deleteToEndOfParagraph(_ sender: Any?) {
        deleteSelection(orExtend: moveToEndOfParagraphAndModifySelection)
    }

    override func deleteToBeginningOfParagraph(_ sender: Any?) {
        deleteSelection(orExtend: moveToBeginningOfParagraphAndModifySelection)
    }

    override func deleteToMark(_ sender: Any?) {
        deleteSelection(orExtend: selectToMark)
    }

    private func deleteSelection(orExtend extend: (Any?) -> Void) {
        if selectedRange().length == 0 { extend(nil) }
        delete(nil)
    }

    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        false
    }

    override func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        false
    }

    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        sendType == nil ? super.validRequestor(forSendType: sendType, returnType: returnType) : nil
    }

    override func dragSelection(with event: NSEvent, offset mouseOffset: NSSize, slideBack: Bool) -> Bool {
        false
    }

    /// Only cut, copy, paste and select all; no Services, Share or Look Up.
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let menu = super.menu(for: event) else { return nil }
        for item in menu.items where !(item.action.map(Self.menuActions.contains) ?? false) {
            menu.removeItem(item)
        }
        return menu
    }
}
