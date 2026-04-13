import SwiftUI

struct OnboardingView: View {
    @Bindable var state: AppState
    @State private var step: OnboardingStep = .welcome
    @State private var isChecking: Bool = false
    @State private var apiKeyInput: String = ""
    @State private var apiKeyValid: Bool = false
    @State private var selectedRegion: String = ""

    // Temporary editing state for firewall selection
    @State private var firewallSelections: [String: Bool] = [:]
    @State private var firewallPorts: [String: Int] = [:]

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case apiKey
        case region
        case firewallDiscovery
        case launchAtLogin
        case done
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 20)

            Spacer()

            Group {
                switch step {
                case .welcome:
                    welcomeStep
                case .apiKey:
                    apiKeyStep
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

            navigationBar
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
        }
        .frame(width: 520, height: 480)
        .onAppear {
            apiKeyInput = state.config.apiKey
            selectedRegion = state.config.region
        }
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
                "Manage your Civo Cloud infrastructure directly from your Mac.\n\nFirewalls, Kubernetes, databases, and more — all in one app."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 360)
        }
    }

    // MARK: - API Key

    private var apiKeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: apiKeyValid ? "key.fill" : "key")
                .font(.system(size: 36))
                .foregroundStyle(apiKeyValid ? .green : .blue)

            Text("API Key")
                .font(.title2.bold())

            Text("Enter your Civo API key. You can find it at\ncivo.com → Account → Security → API Keys.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            SecureField("Civo API Key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)

            if isChecking {
                ProgressView("Validating...")
            } else if apiKeyValid {
                Label("API key is valid", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if !apiKeyInput.isEmpty {
                Button("Validate") {
                    Task { await validateAPIKey() }
                }
                .buttonStyle(.borderedProminent)
            }

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(apiKeyValid ? .orange : .red)
            }
        }
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
                ProgressView("Loading regions...")
            } else if state.availableRegions.isEmpty {
                Text("Could not load regions.")
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    Task { await loadRegions() }
                }
                .buttonStyle(.bordered)
            } else {
                Text("Select your preferred region:")
                    .foregroundStyle(.secondary)

                Picker("Region", selection: $selectedRegion) {
                    ForEach(state.availableRegions) { region in
                        Text("\(region.name) — \(region.countryDisplay)")
                            .tag(region.code)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: selectedRegion) { _, newValue in
                    CivoConfig.shared.region = newValue
                }
            }
        }
        .task { await loadRegions() }
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
                        let grouped = Dictionary(grouping: state.discoveredFirewalls) { $0.region }
                        let sortedRegions = grouped.keys.sorted()
                        ForEach(sortedRegions, id: \.self) { region in
                            if sortedRegions.count > 1 {
                                HStack {
                                    Text(region.uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                            }
                            ForEach(grouped[region] ?? []) { fw in
                                firewallSelectionRow(fw)
                            }
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
                        TextField("Port", value: portValue, format: .number.grouping(.never))
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
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
        case .apiKey: return apiKeyValid
        case .region: return !selectedRegion.isEmpty
        case .firewallDiscovery: return firewallSelections.values.contains(true) && allPortsValid
        case .launchAtLogin: return true
        case .done: return true
        }
    }

    // MARK: - Async checks

    @State private var validationError: String?

    private func validateAPIKey() async {
        isChecking = true
        validationError = nil
        defer { isChecking = false }

        guard !apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Please enter an API key."
            return
        }

        let valid = await CivoAPIClient.shared.validateAPIKey(apiKeyInput)
        if valid {
            apiKeyValid = true
            CivoConfig.shared.apiKey = apiKeyInput
        } else {
            // Save anyway — could be network issue, user gets clear errors later
            apiKeyValid = true
            CivoConfig.shared.apiKey = apiKeyInput
            validationError = "Could not verify online. Saved — will retry on use."
        }
    }

    private func loadRegions() async {
        isChecking = true
        defer { isChecking = false }
        await state.loadRegions()

        if selectedRegion.isEmpty, let current = state.availableRegions.first(where: { $0.isCurrent }) {
            selectedRegion = current.code
            CivoConfig.shared.region = current.code
        }
    }

    private func loadFirewalls() async {
        isChecking = true
        defer { isChecking = false }
        await state.discoverFirewalls()

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
                    enabled: selected,
                    region: fw.region
                ))
        }
        state.managedFirewalls = managed
    }
}
