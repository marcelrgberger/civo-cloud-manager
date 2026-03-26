import SwiftUI

struct ObjectStorePauseView: View {
    let storeName: String
    let mode: Mode
    let progress: PauseProgress?
    let credentialName: String?
    let onCancel: () -> Void

    enum Mode {
        case pause
        case resume
    }

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            // Header with animated icon
            ZStack {
                Circle()
                    .fill(headerColor.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.3 : 0.6)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: headerIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(headerColor)
                    .symbolEffect(.pulse, isActive: isActive)
            }

            VStack(spacing: 4) {
                Text(headerTitle)
                    .font(.headline)

                Text(storeName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(headerColor)
            }

            if let progress, progress.phase != .completed {
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: progress.fraction)
                        .tint(headerColor)

                    HStack {
                        Text(progress.phase.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)

                        Spacer()

                        if progress.totalFiles > 0 {
                            Text("\(progress.currentFile) / \(progress.totalFiles) files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !progress.currentFileName.isEmpty {
                        Text(progress.currentFileName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if progress.bytesTotal > 0 {
                        HStack {
                            Text("\(formatBytes(progress.bytesCopied)) / \(formatBytes(progress.bytesTotal))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            if let eta = progress.estimatedTimeRemaining {
                                Spacer()
                                Text(eta)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Info section
            if let credentialName {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.horizontal")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("Credentials: \(credentialName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "tray.2")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                            Text("Vault: \(ObjectStorePauseService.vaultName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Cancel button
            if isActive {
                Button("Cancel", role: .destructive) {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 360)
        .onAppear { pulse = true }
    }

    // MARK: - Helpers

    private var isActive: Bool {
        guard let progress else { return true }
        return progress.phase != .completed
    }

    private var headerColor: Color {
        mode == .pause ? .orange : .green
    }

    private var headerIcon: String {
        mode == .pause ? "pause.circle.fill" : "play.circle.fill"
    }

    private var headerTitle: String {
        switch mode {
        case .pause:
            guard let progress else { return "Pausing Object Store" }
            switch progress.phase {
            case .preparing: return "Preparing..."
            case .copying: return "Copying Files to Vault"
            case .verifying: return "Verifying Copy"
            case .deleting: return "Removing Original Store"
            case .resizing: return "Optimizing Vault"
            case .completed: return "Paused"
            }
        case .resume:
            guard let progress else { return "Resuming Object Store" }
            switch progress.phase {
            case .preparing: return "Preparing..."
            case .copying: return "Restoring Files"
            case .verifying: return "Verifying Restore"
            case .deleting: return "Cleaning Up Vault"
            case .resizing: return "Optimizing Vault"
            case .completed: return "Restored"
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        if bytes < 1024 * 1024 * 1024 { return String(format: "%.1f MB", Double(bytes) / (1024 * 1024)) }
        return String(format: "%.2f GB", Double(bytes) / (1024 * 1024 * 1024))
    }
}
