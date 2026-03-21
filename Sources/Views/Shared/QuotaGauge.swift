import SwiftUI

struct QuotaGauge: View {
    let item: QuotaItem
    @State private var animatedPercentage: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: animatedPercentage)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(animatedPercentage * 100))%")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .contentTransition(.numericText())
                    Text("\(item.usage)/\(item.limit)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 56, height: 56)
            .help("\(item.usage) of \(item.limit) used")

            HStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(item.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedPercentage = item.percentage
            }
        }
        .onChange(of: item.percentage) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }

    private var gaugeColor: Color {
        if animatedPercentage > 0.9 { return .red }
        if animatedPercentage > 0.7 { return .orange }
        return .blue
    }
}
