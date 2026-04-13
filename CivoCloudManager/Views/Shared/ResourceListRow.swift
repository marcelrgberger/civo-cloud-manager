import SwiftUI

struct ResourceListRow: View {
    let icon: String
    let name: String
    let subtitle: String?
    let status: String?
    var index: Int = 0

    init(icon: String, name: String, subtitle: String? = nil, status: String? = nil, index: Int = 0) {
        self.icon = icon
        self.name = name
        self.subtitle = subtitle
        self.status = status
        self.index = index
    }

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let status {
                StatusBadge(status: status)
            }
        }
        .padding(.vertical, 4)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25).delay(Double(index) * 0.03)) {
                appeared = true
            }
        }
    }
}
