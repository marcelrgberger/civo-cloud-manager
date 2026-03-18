import SwiftUI

struct StatusBadge: View {
    let status: String

    var body: some View {
        HStack(spacing: 4) {
            // Pulsing dot only for in-progress states
            if isPending {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .phaseAnimator([false, true]) { content, phase in
                        content.opacity(phase ? 0.4 : 1)
                    } animation: { _ in .easeInOut(duration: 0.8) }
            }

            Text(status)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var isPending: Bool {
        let lower = status.lowercased()
        return lower == "building" || lower == "pending" || lower == "creating"
    }

    private var color: Color {
        let lower = status.lowercased()
        if lower == "active" || lower == "ready" || lower == "available" || lower == "true" {
            return .green
        }
        if isPending { return .orange }
        if lower == "error" || lower == "failed" || lower == "false" {
            return .red
        }
        return .secondary
    }
}
