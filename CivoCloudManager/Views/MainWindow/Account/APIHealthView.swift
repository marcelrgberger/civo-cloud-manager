import SwiftUI

struct APIHealthView: View {
    @State private var results: [EndpointResult] = []
    @State private var isChecking = false
    @State private var lastCheck: Date?

    private static var chargesFrom: String {
        let formatter = ISO8601DateFormatter()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }
    private static var chargesTo: String {
        ISO8601DateFormatter().string(from: Date())
    }

    private let endpoints: [(name: String, path: String, icon: String)] = [
        ("Quota", "/quota", "gauge.with.dots.needle.33percent"),
        ("Regions", "/regions", "map"),
        ("Instances", "/instances", "desktopcomputer"),
        ("SSH Keys", "/sshkeys", "key"),
        ("Kubernetes", "/kubernetes/clusters", "helm"),
        ("Databases", "/databases", "cylinder.split.1x2"),
        ("Networks", "/networks", "point.3.connected.trianglepath.dotted"),
        ("Firewalls", "/firewalls", "shield"),
        ("Load Balancers", "/loadbalancers", "arrow.triangle.branch"),
        ("Domains", "/dns", "globe"),
        ("Volumes", "/volumes", "cylinder"),
        ("Object Stores", "/objectstores", "tray.2"),
        ("Credentials", "/objectstore/credentials", "key.horizontal"),
        ("Sizes", "/sizes", "square.grid.2x2"),
        ("Disk Images", "/disk_images", "opticaldisc"),
        ("Charges", "/charges?from=\(APIHealthView.chargesFrom)&to=\(APIHealthView.chargesTo)", "dollarsign.circle"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            resultsList
        }
        .navigationTitle("API Health")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await checkAll() }
                } label: {
                    Label("Check All", systemImage: "arrow.clockwise")
                }
                .disabled(isChecking)
            }
        }
        .task { await checkAll() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(overallColor)
                        .frame(width: 12, height: 12)
                    Text(overallStatus)
                        .font(.headline)
                }
                if let lastCheck {
                    Text("Last check: \(lastCheck.formatted(.dateTime.hour().minute().second()))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if isChecking {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("\(results.filter(\.isOk).count)/\(results.count) OK")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private var overallStatus: String {
        if isChecking { return "Checking..." }
        if results.isEmpty { return "Not checked" }
        let failed = results.filter { !$0.isOk }.count
        if failed == 0 { return "All Systems Operational" }
        return "\(failed) endpoint\(failed == 1 ? "" : "s") unavailable"
    }

    private var overallColor: Color {
        if isChecking || results.isEmpty { return .gray }
        let failed = results.filter { !$0.isOk }.count
        if failed == 0 { return .green }
        if failed <= 2 { return .orange }
        return .red
    }

    private var resultsList: some View {
        List {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                HStack(spacing: 12) {
                    Image(systemName: result.icon)
                        .foregroundStyle(result.checked ? (result.isOk ? Color.secondary : Color.red) : Color.secondary.opacity(0.3))
                        .frame(width: 20)
                    Text(result.name)
                        .font(.callout)
                    Spacer()
                    if !result.checked {
                        ProgressView()
                            .controlSize(.mini)
                    } else if result.isOk {
                        HStack(spacing: 4) {
                            Text("\(result.responseTime)ms")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(responseColor(result.responseTime))
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        HStack(spacing: 4) {
                            Text(result.statusCode == 0 ? "Timeout" : "\(result.statusCode)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.red)
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3).delay(Double(index) * 0.03), value: result.checked)
            }
        }
    }

    private func responseColor(_ ms: Int) -> Color {
        if ms < 200 { return .green }
        if ms < 500 { return .orange }
        return .red
    }

    private func checkAll() async {
        isChecking = true
        results = endpoints.map { EndpointResult(name: $0.name, icon: $0.icon) }

        for (index, endpoint) in endpoints.enumerated() {
            let start = Date()
            let (statusCode, hasData) = await checkEndpoint(path: endpoint.path)
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)

            results[index].statusCode = statusCode
            results[index].responseTime = elapsed
            results[index].hasData = hasData
            results[index].checked = true
        }

        lastCheck = Date()
        isChecking = false
    }

    private func checkEndpoint(path: String) async -> (status: Int, hasData: Bool) {
        let apiKey = CivoConfig.shared.apiKey
        guard !apiKey.isEmpty else { return (0, false) }

        let region = CivoConfig.shared.region
        var urlString = "https://api.civo.com/v2\(path)"
        if !path.contains("?") && !region.isEmpty {
            urlString += "?region=\(region)"
        } else if !region.isEmpty {
            urlString += "&region=\(region)"
        }
        guard let url = URL(string: urlString) else { return (0, false) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let hasData: Bool
            if let json = try? JSONSerialization.jsonObject(with: data) {
                if let array = json as? [Any] { hasData = !array.isEmpty }
                else if let dict = json as? [String: Any] {
                    if let items = dict["items"] as? [Any] { hasData = !items.isEmpty }
                    else { hasData = true }
                }
                else { hasData = false }
            } else { hasData = data.count > 2 }
            return (code, hasData)
        } catch {
            return (0, false)
        }
    }
}

private struct EndpointResult: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var statusCode: Int = 0
    var responseTime: Int = 0
    var hasData = false
    var checked = false

    var isOk: Bool { (200...299).contains(statusCode) }
}
