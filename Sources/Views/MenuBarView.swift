import SwiftUI

struct MenuBarView: View {
    @Bindable var state: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var hasLoaded = false
    @State private var store = StoreManager.shared
    @State private var showSavePreset = false
    @State private var presetName = ""
    @State private var selectedDuration: FirewallDuration = .unlimited

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if state.setupState != .ready {
                setupRequiredSection
            } else {
                ipSection
                Divider()
                presetsSection
                Divider()
                firewallSection
                Divider()
                durationPickerSection
                Divider()
                bulkActionsSection
                Divider()
                statusSection
            }

            if !store.isFullAccessUnlocked {
                Divider()
                FreeModeBanner()
            }

            Divider()
            bottomBar
        }
        .frame(width: 340)
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await state.initialLoad()
            if state.setupState != .ready {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onChange(of: state.showOnboarding) { _, show in
            if show {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
                state.showOnboarding = false
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "shield.fill")
                .foregroundStyle(state.menuBarColor)
                .font(.title3)
            Text("Civo Cloud Manager")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Setup Required

    private var setupRequiredSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gear.badge.xmark")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(setupMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open Setup...") {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var setupMessage: String {
        switch state.setupState {
        case .checking: return "Checking setup..."
        case .needsAPIKey: return "API key not configured.\nOpen setup to add your Civo API key."
        case .needsRegion: return "No region selected.\nOpen setup to choose a region."
        case .needsFirewallSelection: return "No firewalls configured.\nOpen setup to select firewalls."
        case .ready: return ""
        }
    }

    // MARK: - IP Section

    private var ipSection: some View {
        HStack {
            Label {
                if state.currentIP == "..." {
                    Text("Detecting IP...")
                        .foregroundStyle(.secondary)
                } else {
                    Text(state.currentIP)
                        .font(.system(.body, design: .monospaced))
                }
            } icon: {
                Image(systemName: "network")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Firewall Section

    private var firewallSection: some View {
        VStack(spacing: 2) {
            if state.firewalls.isEmpty && !state.isLoading {
                HStack {
                    Text("No firewalls loaded")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else if state.firewalls.isEmpty && state.isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading firewalls...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                ForEach(state.firewalls) { fw in
                    firewallRow(fw)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func firewallRow(_ fw: FirewallStatus) -> some View {
        HStack(spacing: 10) {
            Image(systemName: fw.isOpen ? "lock.open.fill" : "lock.fill")
                .foregroundStyle(fw.isOpen ? .yellow : .primary)
                .font(.body)
                .frame(width: 20)
                .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 1) {
                Text(fw.managed.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text("Port \(fw.managed.port)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let remaining = state.remainingMinutes(for: fw) {
                        Text("\(remaining) min left")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            if state.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if fw.isOpen {
                Button("Close") {
                    Task { await state.closeFirewall(fw) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            } else {
                Button("Open") {
                    if selectedDuration == .unlimited {
                        Task { await state.openFirewall(fw.managed) }
                    } else {
                        Task { await state.openFirewallWithTimer(fw.managed, minutes: selectedDuration.minutes) }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }

    // MARK: - Bulk Actions

    private var bulkActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                Task { await state.openAll() }
            } label: {
                Label("Open All", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(state.isLoading || state.enabledFirewalls.isEmpty)

            Button {
                Task { await state.closeAll() }
            } label: {
                Label("Close All", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
            .disabled(state.isLoading || state.allClosed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.caption)
                Text(state.error ?? state.statusText)
                    .font(.caption)
                    .foregroundStyle(state.error != nil ? .red : .secondary)
                    .lineLimit(2)
                Spacer()
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
                Text("Last check: \(state.lastRefreshText)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var statusIcon: String {
        if state.error != nil { return "exclamationmark.circle.fill" }
        if state.anyOpen { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if state.error != nil { return .red }
        if state.anyOpen { return .yellow }
        return .green
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("IP Presets")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if state.currentIP != "..." {
                    Button {
                        showSavePreset.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Save current IP as preset")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            if showSavePreset {
                HStack(spacing: 6) {
                    TextField("Name (e.g. Home)", text: $presetName)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                    Button("Save") {
                        guard !presetName.isEmpty else { return }
                        state.addPreset(name: presetName, ip: state.currentIP)
                        presetName = ""
                        showSavePreset = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(presetName.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            if state.ipPresets.isEmpty {
                HStack {
                    Text("No saved IPs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            } else {
                ForEach(state.ipPresets) { preset in
                    presetRow(preset)
                }
                .padding(.bottom, 4)
            }
        }
    }

    private func presetRow(_ preset: IPPreset) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.blue)
                .font(.caption)

            VStack(alignment: .leading, spacing: 0) {
                Text(preset.name)
                    .font(.caption.weight(.medium))
                Text(preset.ip)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !state.enabledFirewalls.isEmpty {
                Menu {
                    ForEach(state.enabledFirewalls) { fw in
                        Button("Open \(fw.name)") {
                            Task { await state.openFirewallWithPreset(preset, firewall: fw) }
                        }
                    }
                } label: {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
                .help("Open firewall with this IP")
            }

            Button {
                state.removePreset(id: preset.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete preset")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    // MARK: - Duration Picker

    private var durationPickerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text("Auto-close:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("", selection: $selectedDuration) {
                ForEach(FirewallDuration.allCases, id: \.self) { duration in
                    Text(duration.label).tag(duration)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .labelsHidden()
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button {
                Task { await state.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(state.isLoading)
            .help("Refresh")

            Spacer()

            Button {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "square.grid.2x2")
            }
            .buttonStyle(.borderless)
            .help("Dashboard")

            Spacer()

            Button {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Spacer()

            Button {
                if let url = URL(string: "https://berger-rosenstock.de/privacy") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "hand.raised")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Privacy Policy")

            Spacer()

            Button {
                state.stopAutoRefresh()
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Quit")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Firewall Duration

enum FirewallDuration: CaseIterable, Hashable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case unlimited

    var label: String {
        switch self {
        case .fifteenMinutes: return "15 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .unlimited: return "Unlimited"
        }
    }

    var minutes: Int {
        switch self {
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 60
        case .twoHours: return 120
        case .unlimited: return 0
        }
    }
}
