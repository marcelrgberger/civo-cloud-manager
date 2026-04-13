import SwiftUI

struct RateEditorView: View {
    @State private var rates: [String: Double] = CivoCharge.hourlyRates
    @Environment(\.dismiss) private var dismiss

    private var sortedKeys: [String] {
        rates.keys.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Hourly Rates")
                    .font(.title2.bold())
                Spacer()
                Button("Reset to Defaults") {
                    rates = CivoCharge.defaultHourlyRates
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            List {
                ForEach(sortedKeys, id: \.self) { key in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.system(.callout, design: .monospaced))
                            Text(friendlyName(for: key))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Rate", value: Binding(
                            get: { rates[key] ?? 0 },
                            set: { rates[key] = $0 }
                        ), format: .number.precision(.fractionLength(6)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .font(.system(.callout, design: .monospaced))
                        Text("/hr")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    CivoCharge.saveHourlyRates(rates)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private func friendlyName(for code: String) -> String {
        if code.contains("database") { return "Database" }
        if code.contains("kube") && code.contains("perf") { return "K8s Performance" }
        if code.contains("kube") && code.contains("cpu") { return "K8s CPU Optimized" }
        if code.contains("kube") && code.contains("ram") { return "K8s RAM Optimized" }
        if code.contains("kube") { return "K8s Standard" }
        if code.contains("instance") { return "Compute" }
        if code.contains("loadbalancer") { return "Load Balancer" }
        return ""
    }
}
