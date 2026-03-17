import SwiftUI

struct MenuBarView: View {
    @Bindable var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if state.setupState != .ready {
                setupRequiredSection
            } else {
                ipSection
                Divider()
                firewallSection
                Divider()
                bulkActionsSection
                Divider()
                statusSection
            }

            Divider()
            bottomBar
        }
        .frame(width: 340)
        .task {
            await state.initialLoad()
            // Auto-open onboarding if setup not complete
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
        case .cliMissing: return "civo CLI is not installed.\nInstall with: brew install civo"
        case .unauthenticated: return "civo CLI is not authenticated.\nRun: civo apikey save YOUR_KEY --name default"
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

            VStack(alignment: .leading, spacing: 1) {
                Text(fw.managed.name)
                    .font(.subheadline.weight(.medium))
                Text("Port \(fw.managed.port)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                    Task { await state.openFirewall(fw.managed) }
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
                Text(state.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let error = state.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                Task { await state.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(state.isLoading)

            Spacer()

            Button {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings...", systemImage: "gear")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                state.stopAutoRefresh()
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
