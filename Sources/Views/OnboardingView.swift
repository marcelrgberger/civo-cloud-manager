import SwiftUI

struct OnboardingView: View {
    @Bindable var state: AppState
    @State private var step: OnboardingStep = .welcome
    @State private var cliInstalled: Bool = false
    @State private var authenticated: Bool = false
    @State private var isChecking: Bool = false

    // Temporary editing state for firewall selection
    @State private var firewallSelections: [String: Bool] = [:]
    @State private var firewallPorts: [String: Int] = [:]

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case cliCheck
        case authCheck
        case region
        case firewallDiscovery
        case launchAtLogin
        case done
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 20)

            Spacer()

            // Step content
            Group {
                switch step {
                case .welcome:
                    welcomeStep
                case .cliCheck:
                    cliCheckStep
                case .authCheck:
                    authCheckStep
                case .region:
                    regionStep
                case .firewallDiscovery:
                    firewallDiscoveryStep
                case .launchAtLogin:
                    launchAtLoginStep
                case .done:
                    doneStep
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Navigation
            navigationBar
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
        }
        .frame(width: 520, height: 480)
    }

    // MARK: - Progress

    private var progressBar: some View {
        let total = OnboardingStep.allCases.count
        let current = step.rawValue + 1

        return HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= step.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 3)
            }
        }
        .overlay(alignment: .trailing) {
            Text("\(current)/\(total)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .offset(y: -12)
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Civo Cloud Manager")
                .font(.title.bold())

            Text(
                "Manages firewall rules for your Civo Cloud infrastructure.\n\nAutomatically opens and closes firewall ports based on your current IP address."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 360)
        }
    }

    // MARK: - CLI Check

    private var cliCheckStep: some View {
        VStack(spacing: 16) {
            stepIcon(ok: cliInstalled)

            Text("Civo CLI")
                .font(.title2.bold())

            if isChecking {
                ProgressView("Checking...")
            } else if cliInstalled {
                Label("civo CLI is installed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("civo CLI not found", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)

                Text("Install it with:")
                    .foregroundStyle(.secondary)

                codeBlock("brew install civo")

                Button("Re-check") {
                    Task { await checkCLI() }
                }
                .buttonStyle(.bordered)
            }
        }
        .task { await checkCLI() }
    }

    // MARK: - Auth Check

    private var authCheckStep: some View {
        VStack(spacing: 16) {
            stepIcon(ok: authenticated)

            Text("Authentication")
                .font(.title2.bold())

            if isChecking {
                ProgressView("Checking...")
            } else if authenticated {
                Label("Authenticated", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Not authenticated", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)

                Text("Save your API key:")
                    .foregroundStyle(.secondary)

                codeBlock("civo apikey save YOUR_KEY --name default")

                Button("Re-check") {
                    Task { await checkAuth() }
                }
                .buttonStyle(.bordered)
            }
        }
        .task { await checkAuth() }
    }

    // MARK: - Region

    private var regionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("Region")
                .font(.title2.bold())

            if isChecking {
                ProgressView("Detecting region...")
            } else if !state.currentRegion.isEmpty {
                Label(state.currentRegion, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Label("No region detected", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Set a region:")
                    .foregroundStyle(.secondary)
                codeBlock("civo region use REGION")
            }
        }
        .task { await loadRegion() }
    }

    // MARK: - Firewall Discovery

    private var firewallDiscoveryStep: some View {
        VStack(spacing: 12) {
            Text("Select Firewalls")
                .font(.title2.bold())

            Text("Choose which firewalls to manage and set the port for each.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .font(.subheadline)

            if isChecking {
                ProgressView("Discovering firewalls...")
                    .padding()
            } else if state.discoveredFirewalls.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("No firewalls found in your account.")
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        Task { await loadFirewalls() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(state.discoveredFirewalls) { fw in
                            firewallSelectionRow(fw)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
            }
        }
        .task { await loadFirewalls() }
    }

    private func firewallSelectionRow(_ fw: CivoFirewall) -> some View {
        let isSelected = Binding<Bool>(
            get: { firewallSelections[fw.id] ?? false },
            set: { firewallSelections[fw.id] = $0 }
        )

        let portValue = Binding<Int>(
            get: { firewallPorts[fw.id] ?? 6443 },
            set: { firewallPorts[fw.id] = max(1, min(65535, $0)) }
        )

        let portIsValid = isPortValid(for: fw.id)

        return HStack(spacing: 12) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(fw.name)
                    .font(.subheadline.weight(.medium))
                Text("\(fw.rulesCount) rules")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected.wrappedValue {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Port:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Port", value: portValue, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .font(.caption.monospaced())
                    }
                    if !portIsValid {
                        Text("Port must be 1-65535")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected.wrappedValue ? Color.accentColor.opacity(0.08) : Color.clear)
        )
    }

    private func isPortValid(for firewallId: String) -> Bool {
        let port = firewallPorts[firewallId] ?? 6443
        return port >= 1 && port <= 65535
    }

    /// Check if all enabled firewalls have valid ports
    private var allPortsValid: Bool {
        for (fwId, selected) in firewallSelections where selected {
            if !isPortValid(for: fwId) { return false }
        }
        return true
    }

    // MARK: - Launch at Login

    private var launchAtLoginStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("Launch at Login")
                .font(.title2.bold())

            Text("Start Civo Cloud Manager automatically when you log in.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Toggle("Launch at Login", isOn: Binding(
                get: { state.launchAtLogin },
                set: { state.launchAtLogin = $0 }
            ))
            .toggleStyle(.switch)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Done

    private var doneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("All Set!")
                .font(.title.bold())

            let selectedCount = firewallSelections.values.filter { $0 }.count
            Text(
                "Managing \(selectedCount) firewall\(selectedCount == 1 ? "" : "s"). You can change settings anytime from the menu bar."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 360)
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            if step != .welcome {
                Button("Back") {
                    withAnimation {
                        if let prev = OnboardingStep(rawValue: step.rawValue - 1) {
                            step = prev
                        }
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if step == .done {
                Button("Finish") {
                    applyFirewallSelections()
                    state.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Next") {
                    withAnimation {
                        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
                            step = next
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance)
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome: return true
        case .cliCheck: return cliInstalled
        case .authCheck: return authenticated
        case .region: return true
        case .firewallDiscovery: return firewallSelections.values.contains(true) && allPortsValid
        case .launchAtLogin: return true
        case .done: return true
        }
    }

    // MARK: - Helpers

    private func stepIcon(ok: Bool) -> some View {
        Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
            .font(.system(size: 36))
            .foregroundStyle(ok ? .green : .red)
    }

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .textSelection(.enabled)
    }

    // MARK: - Async checks

    private func checkCLI() async {
        isChecking = true
        defer { isChecking = false }
        cliInstalled = CivoAdapter().isCLIInstalled()
    }

    private func checkAuth() async {
        isChecking = true
        defer { isChecking = false }
        authenticated = await CivoAdapter().isAuthenticated()
    }

    private func loadRegion() async {
        isChecking = true
        defer { isChecking = false }
        do {
            state.currentRegion = try await CivoAdapter().getCurrentRegion()
        } catch {
            Log.error("Region check failed: \(error.localizedDescription)")
        }
    }

    private func loadFirewalls() async {
        isChecking = true
        defer { isChecking = false }
        await state.discoverFirewalls()

        // Pre-populate selections from already-managed firewalls
        for managed in state.managedFirewalls {
            firewallSelections[managed.id] = managed.enabled
            firewallPorts[managed.id] = managed.port
        }
    }

    private func applyFirewallSelections() {
        var managed: [ManagedFirewall] = []
        for fw in state.discoveredFirewalls {
            let selected = firewallSelections[fw.id] ?? false
            let port = firewallPorts[fw.id] ?? 6443
            managed.append(
                ManagedFirewall(
                    id: fw.id,
                    name: fw.name,
                    port: port,
                    enabled: selected
                ))
        }
        state.managedFirewalls = managed
    }
}
