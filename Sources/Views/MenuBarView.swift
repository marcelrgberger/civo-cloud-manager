import SwiftUI

struct MenuBarView: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // IP display
            ipSection

            Divider()

            // Firewall rows
            firewallSection

            Divider()

            // Bulk actions
            bulkActionsSection

            Divider()

            // Status footer
            statusSection

            Divider()

            // Bottom bar
            bottomBar
        }
        .frame(width: 320)
        .task {
            state.initialLoad()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "shield.fill")
                .foregroundStyle(state.menuBarColor)
                .font(.title3)
            Text("Civo Access Manager")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
        VStack(spacing: 4) {
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
        .padding(.vertical, 4)
    }

    private func firewallRow(_ fw: FirewallStatus) -> some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(fw.isOpen ? Color.yellow : Color.green)
                .frame(width: 8, height: 8)

            // Firewall info
            VStack(alignment: .leading, spacing: 1) {
                Text(fw.config.displayName)
                    .font(.subheadline.weight(.medium))
                Text("Port \(fw.config.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
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
                    Task { await state.openFirewall(fw.config) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
            .disabled(state.isLoading)

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
        .padding(.vertical, 8)
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

            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                Text("Last check: \(state.lastRefreshText)")
                    .font(.caption)
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
                state.stopAutoRefresh()
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
