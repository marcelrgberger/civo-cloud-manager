import LocalAuthentication
import SwiftUI
import WebKit

/// Content of the independent console window. Gated by Full Access on its own, because the
/// main window's paywall does not cover a window that is already open.
struct InstanceConsoleView: View {
    @State private var vm: ConsoleViewModel
    @State private var confirmEnd = false
    @State private var showPassword = false
    @State private var copiedPassword = false
    private let store = StoreManager.shared
    private let logins = ConsoleLoginStore.shared

    /// Same as the instance detail view: a revealed password hides itself again.
    private static let passwordVisibleDuration: Duration = .seconds(30)

    init(target: ConsoleTarget) {
        _vm = State(initialValue: ConsoleViewModel(target: target))
    }

    var body: some View {
        VStack(spacing: 0) {
            hintBar
            Divider()
            ZStack {
                if let connection = vm.connection {
                    ConsoleWebView(
                        url: connection.url,
                        target: vm.target,
                        onAttach: { vm.webViewDidAttach(connectionID: connection.id, teardown: $0) },
                        onFinish: { vm.pageDidLoad(connectionID: connection.id) },
                        onFailure: { vm.pageDidFail(connectionID: connection.id) }
                    )
                    .id(connection.id)
                }
                statusOverlay
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .navigationTitle(Text("Console: \(vm.target.instanceName)"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.connect() } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                }
                .help("Start or check the console session and reconnect")
                .disabled(vm.isBusy || !store.isFullAccessUnlocked)
            }
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) { confirmEnd = true } label: {
                    Label("End session", systemImage: "stop.circle")
                }
                .help("End the console session on Civo for everyone")
                .disabled(vm.isBusy || !store.isFullAccessUnlocked)
            }
        }
        .confirmationDialog("End the console session for everyone?", isPresented: $confirmEnd) {
            Button("End session", role: .destructive) { Task { await vm.endSession() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This ends the console session on Civo for this instance, including a console open in the Civo dashboard.")
        }
        .onAppear {
            if store.isFullAccessUnlocked {
                vm.connect()
            } else if store.hasLoadedPurchaseStatus {
                vm.revokeAccess()
            }
        }
        .onChange(of: store.isFullAccessUnlocked) { _, unlocked in
            if !unlocked {
                vm.revokeAccess()
            } else if vm.phase == .idle {
                vm.connect()
            }
        }
        .onChange(of: store.hasLoadedPurchaseStatus) { _, loaded in
            if loaded && !store.isFullAccessUnlocked { vm.revokeAccess() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .civoAPIKeyDidChange)) { _ in
            vm.apiKeyDidChange()
            // The login belongs to the account the window was opened with.
            showPassword = false
            logins.remove(for: vm.target)
        }
        .task(id: showPassword) {
            guard showPassword else { return }
            try? await Task.sleep(for: Self.passwordVisibleDuration)
            if !Task.isCancelled { showPassword = false }
        }
        .task(id: copiedPassword) {
            guard copiedPassword else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copiedPassword = false }
        }
        .onDisappear {
            vm.closeLocally()
            logins.remove(for: vm.target)
        }
    }

    private var hintBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Log in with a password of a user on the instance, for example the initial password. Copy and paste are not available in the console.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if store.isFullAccessUnlocked {
                initialLogin(logins.login(for: vm.target) ?? ConsoleLogin(user: nil, password: nil))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Initial login

    @ViewBuilder
    private func initialLogin(_ login: ConsoleLogin) -> some View {
        if login.isEmpty {
            Text("Civo reports no initial user or password for this instance.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 16) {
                loginField("Initial User") {
                    if let user = login.user {
                        Text(verbatim: user)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                    } else {
                        notProvided
                    }
                }
                loginField("Initial Password") {
                    if let password = login.password {
                        passwordField(password)
                    } else {
                        notProvided
                    }
                }
                Spacer()
            }
            Text("Shows the initial login reported by Civo. A password changed later on the instance is not shown here.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var notProvided: some View {
        Text("Not provided by Civo")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func loginField(_ title: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            value()
        }
    }

    private func passwordField(_ password: String) -> some View {
        HStack(spacing: 6) {
            // Not selectable: copying goes through `SecretPasteboard` only.
            if showPassword {
                Text(verbatim: password)
                    .font(.callout.monospaced())
            } else {
                Text(verbatim: String(repeating: "*", count: 12))
                    .font(.callout.monospaced())
            }
            Button {
                if showPassword {
                    showPassword = false
                } else {
                    Task { showPassword = await DeviceOwner.confirm(reason: String(localized: "View instance password")) }
                }
            } label: {
                Label(showPassword ? "Hide password" : "Show password", systemImage: showPassword ? "eye.slash" : "eye")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(showPassword ? "Hide password" : "Show password")
            Button {
                Task { await copyPassword(password) }
            } label: {
                Label("Copy password", systemImage: copiedPassword ? "checkmark" : "doc.on.doc")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help("Copy password")
        }
    }

    /// A hidden password is copied only after the same authentication that reveals it.
    private func copyPassword(_ password: String) async {
        if !showPassword {
            guard await DeviceOwner.confirm(reason: String(localized: "Copy instance password")) else { return }
        }
        SecretPasteboard.copy(password)
        copiedPassword = true
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch vm.phase {
        case .idle, .starting:
            progress(Text("Starting console session..."))
        case .preparing(let attempt, let total):
            progress(Text("Preparing console... (attempt \(attempt) of \(total))"))
        case .loading:
            progress(Text("Loading console..."))
        case .pageLoaded:
            VStack {
                Spacer()
                Text("Console page loaded. If the screen stays black or the connection drops, use Reconnect.")
                    .font(.caption)
                    .padding(6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        case .disconnected:
            message(
                icon: "bolt.horizontal.circle",
                Text("Disconnected. The console session on Civo stays active until it expires or is ended."),
                actions: reconnectButton
            )
        case .ending:
            progress(Text("Ending console session..."))
        case .ended(.ended):
            message(icon: "checkmark.circle", Text("Console session ended."), actions: reconnectButton)
        case .ended(.alreadyStopped):
            message(icon: "checkmark.circle", Text("No active console session. It had already ended."), actions: reconnectButton)
        case .endFailed(let error):
            message(
                icon: "exclamationmark.triangle",
                Text("The console was closed in this window, but Civo did not confirm that the session ended. It may stay active until it expires."),
                detail: error.userMessage,
                actions: Button("End session") { confirmEnd = true }.controlSize(.large)
            )
        case .failed(let error):
            message(
                icon: "exclamationmark.triangle",
                Text("The console is not available."),
                detail: error.userMessage,
                actions: failureActions(for: error)
            )
        }
    }

    private var reconnectButton: some View {
        Button("Reconnect") { vm.connect() }
            .controlSize(.large)
            .disabled(!store.isFullAccessUnlocked)
    }

    @ViewBuilder
    private func failureActions(for error: ConsoleError) -> some View {
        switch error {
        case .accessRevoked, .accountChanged:
            EmptyView()
        default:
            HStack {
                reconnectButton
                if let dashboard = ConsoleURL.dashboardURL(instanceId: vm.target.instanceId) {
                    Button("Open in Civo Dashboard") { NSWorkspace.shared.open(dashboard) }
                        .controlSize(.large)
                }
            }
        }
    }

    private func progress(_ text: Text) -> some View {
        VStack(spacing: 12) {
            ProgressView().controlSize(.large)
            text.foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func message(icon: String, _ text: Text, detail: String? = nil, actions: some View) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            text
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            if let detail {
                Text(verbatim: detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            actions
        }
        .frame(maxWidth: 460)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

/// Touch ID or system password, as in the instance detail view: a Mac without any owner
/// authentication shows the password directly.
@MainActor
private enum DeviceOwner {
    static func confirm(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return true }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
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

/// WKWebView for the Civo-hosted noVNC page: non-persistent data store, no inspector, no popups,
/// no back/forward gestures, and navigation limited to the console origin. Blocked navigations are
/// cancelled, never handed to the system browser, because they could carry the token.
/// Errors are reported without details: their failing URL contains the token.
private struct ConsoleWebView: NSViewRepresentable {
    let url: URL
    let target: ConsoleTarget
    /// Hands the view model a synchronous teardown, used before any End session request is sent.
    let onAttach: (@escaping @MainActor () -> Void) -> Void
    let onFinish: () -> Void
    let onFailure: () -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.isInspectable = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
        onAttach { [weak webView] in
            guard let webView else { return }
            Self.tearDown(webView)
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        tearDown(webView)
    }

    /// Detaches callbacks, stops loading and starts unloading the page (and its WebSocket) by navigating
    /// away. WebKit completes the unload asynchronously; there is no public API to await the socket close.
    @MainActor
    static func tearDown(_ webView: WKWebView) {
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        webView.isHidden = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        /// WebKit's "frame load interrupted by policy change" code, raised when the guard cancels a navigation.
        private static let frameLoadInterruptedByPolicyChange = 102

        var parent: ConsoleWebView
        private var hasFinishedLoading = false

        init(parent: ConsoleWebView) { self.parent = parent }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
            if url.absoluteString == "about:blank"
                || ConsoleURL.isAllowedNavigation(url, sessionURL: parent.url, target: parent.target) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasFinishedLoading = true
            parent.onFinish()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.onFailure()
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            nil
        }

        private func report(_ error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
            // A navigation cancelled by the guard after the page loaded must not end the console.
            let interruptedByPolicy = nsError.domain == WKErrorDomain && nsError.code == Self.frameLoadInterruptedByPolicyChange
            if interruptedByPolicy && hasFinishedLoading { return }
            parent.onFailure()
        }
    }
}
