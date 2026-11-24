import SwiftUI

struct CostDashboardView: View {
    let instanceVM: InstanceViewModel
    let kubernetesVM: KubernetesViewModel
    let databaseVM: DatabaseViewModel
    let volumeVM: VolumeViewModel

    @State private var model = CostChargesViewModel()
    @State private var period: ChargePeriod = .currentMonth
    @State private var showRateEditor = false
    /// A running manual Refresh. A newer load cancels it, so a superseded refresh cannot
    /// write its completed months to the cache after the newer load did.
    @State private var refreshTask: Task<Void, Never>?

    /// Restarts the load, cancelling the running one, when the period or the account changes.
    private struct LoadKey: Hashable {
        let period: ChargePeriod
        let accountGeneration: Int
    }

    private var charges: [CivoCharge] { model.charges }
    private var isLoading: Bool { model.isLoading }
    private var error: String? { model.error }

    // MARK: - Computed

    private var totalCost: Double {
        charges.reduce(0) { $0 + $1.totalCost }
    }

    /// Avoids extreme extrapolation right after the month starts.
    private static let minimumProjectionBasis: TimeInterval = 60 * 60

    private var projectedMonthlyCost: Double {
        let now = model.currentDate
        let monthStart = ChargeCalendar.startOfMonth(now)
        let monthEnd = ChargeCalendar.utc.date(byAdding: .month, value: 1, to: monthStart)!
        let elapsed = max(now.timeIntervalSince(monthStart), Self.minimumProjectionBasis)
        return totalCost / elapsed * monthEnd.timeIntervalSince(monthStart)
    }

    private var costByType: [(type: String, cost: Double, icon: String, color: Color)] {
        let grouped = Dictionary(grouping: charges, by: \.resourceType)
        return grouped.map { type, items in
            let cost = items.reduce(0) { $0 + $1.totalCost }
            let icon = items.first?.icon ?? "dollarsign.circle"
            let color = items.first?.iconColor ?? .secondary
            return (type: type, cost: cost, icon: icon, color: color)
        }
        .sorted { $0.cost > $1.cost }
    }

    private var costByResource: [(label: String, type: String, cost: Double, icon: String, color: Color, hours: Double)] {
        let grouped = Dictionary(grouping: charges, by: \.label)
        return grouped.map { label, items in
            let cost = items.reduce(0) { $0 + $1.totalCost }
            let hours = items.reduce(0) { $0 + $1.numHours }
            let icon = items.first?.icon ?? "dollarsign.circle"
            let color = items.first?.iconColor ?? .secondary
            let type = items.first?.resourceType ?? "Other"
            return (label: label, type: type, cost: cost, icon: icon, color: color, hours: hours)
        }
        .sorted { $0.cost > $1.cost }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                periodPicker

                if isLoading {
                    ProgressView("Loading charges...")
                        .frame(maxWidth: .infinity)
                        .padding(40)
                } else if let error {
                    GroupBox {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                refreshTask = Task { await loadCharges(trigger: .manualRefresh) }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else if charges.isEmpty {
                    GroupBox {
                        VStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("No charges for this period")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else {
                    totalCard
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AccessibilityID.costsTotal)
                    typeBreakdown
                    resourceBreakdown
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AccessibilityID.costsBreakdown)
                }

                HStack {
                    Text("Costs estimated from hourly rates × usage hours.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button("Edit Rates") { showRateEditor = true }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                }
            }
            .padding(20)
        }
        .navigationTitle("Costs")
        .task(id: LoadKey(period: period, accountGeneration: model.accountGeneration)) {
            refreshTask?.cancel()
            await loadCharges()
        }
        .onReceive(NotificationCenter.default.publisher(for: .civoAPIKeyDidChange)) { _ in
            refreshTask?.cancel()
            model.apiKeyDidChange()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    refreshTask = Task { await loadCharges(trigger: .manualRefresh) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showRateEditor) {
            RateEditorView()
        }
    }

    // MARK: - Subviews

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(ChargePeriod.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    private var totalCard: some View {
        GroupBox {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Actual (\(period.rawValue))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("$\(totalCost, specifier: "%.2f")")
                        .font(.system(.title, design: .rounded).bold())
                }
                if period == .currentMonth {
                    Divider().frame(height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projected (full month)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("~$\(projectedMonthlyCost, specifier: "%.2f")")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
        }
    }

    private var typeBreakdown: some View {
        GroupBox("By Resource Type") {
            VStack(spacing: 8) {
                ForEach(costByType, id: \.type) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.color)
                            .frame(width: 20)
                        Text(item.type)
                            .font(.callout)
                        Spacer()

                        // Percentage bar
                        if totalCost > 0 {
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(item.color.opacity(0.3))
                                    .frame(width: geo.size.width * item.cost / totalCost)
                            }
                            .frame(width: 60, height: 8)
                        }

                        Text("$\(item.cost, specifier: "%.2f")")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding(4)
        }
    }

    private var resourceBreakdown: some View {
        GroupBox("By Resource") {
            VStack(spacing: 2) {
                ForEach(costByResource, id: \.label) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.color)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.label)
                                .font(.callout)
                                .lineLimit(1)
                            Text("\(item.type) — \(Int(item.hours))h")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("$\(item.cost, specifier: "%.2f")")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .padding(4)
        }
    }



    // MARK: - Data

    private func loadCharges(trigger: ChargeLoadTrigger = .automatic) async {
        await model.load(period, trigger: trigger)
    }
}
