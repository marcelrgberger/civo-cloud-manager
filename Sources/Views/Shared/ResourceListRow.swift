import SwiftUI

struct ResourceListRow: View {
    let icon: String
    let name: String
    let subtitle: String?
    let status: String?

    init(icon: String, name: String, subtitle: String? = nil, status: String? = nil) {
        self.icon = icon
        self.name = name
        self.subtitle = subtitle
        self.status = status
    }

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
    }
}
