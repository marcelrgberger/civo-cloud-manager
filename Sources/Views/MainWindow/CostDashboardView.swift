import SwiftUI

struct CostDashboardView: View {
    let instanceVM: InstanceViewModel
    let kubernetesVM: KubernetesViewModel
    let databaseVM: DatabaseViewModel
    let volumeVM: VolumeViewModel

    @State private var charges: [CivoCharge] = []
    @State private var invoices: [CivoInvoice] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var period: ChargePeriod = .currentMonth

    private let service = CivoChargesService()

    enum ChargePeriod: String, CaseIterable {
        case currentMonth = "This Month"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case thisYear = "This Year"

        /// Returns monthly date ranges (max 31 days each) for the period
        var monthlyRanges: [(from: Date, to: Date)] {
            let now = Date()
            let cal = Calendar.current

            switch self {
            case .currentMonth:
                let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
                return [(start, now)]
            case .lastMonth:
                let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
                let startOfLastMonth = cal.date(byAdding: .month, value: -1, to: startOfThisMonth)!
                return [(startOfLastMonth, startOfThisMonth)]
            case .lastQuarter:
                return (0..<3).reversed().compactMap { offset in
                    let monthStart = cal.date(byAdding: .month, value: -offset, to: cal.date(from: cal.dateComponents([.year, .month], from: now))!)!
                    let monthEnd: Date
                    if offset == 0 {
                        monthEnd = now
                    } else {
                        monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
                    }
                    return (monthStart, monthEnd)
                }
            case .thisYear:
                let startOfYear = cal.date(from: cal.dateComponents([.year], from: now))!
                let currentMonth = cal.component(.month, from: now)
                return (0..<currentMonth).map { offset in
                    let monthStart = cal.date(byAdding: .month, value: offset, to: startOfYear)!
                    let monthEnd: Date
                    if offset == currentMonth - 1 {
                        monthEnd = now
                    } else {
                        monthEnd = cal.date(byAdding: .month, value: offset + 1, to: startOfYear)!
                    }
                    return (monthStart, monthEnd)
                }
            }
        }
    }

    // MARK: - Computed

    private var totalCost: Double {
        charges.reduce(0) { $0 + $1.totalCost }
    }

    private var projectedMonthlyCost: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let daysElapsed = max(calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 1, 1)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        return totalCost / Double(daysElapsed) * Double(daysInMonth)
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
                                Task { await loadCharges() }
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
                    typeBreakdown
                    resourceBreakdown
                }

                if !invoices.isEmpty {
                    invoiceSection
                }
            }
            .padding(20)
        }
        .navigationTitle("Costs")
        .task { await loadCharges() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await loadCharges() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
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
        .onChange(of: period) { _, _ in
            Task { await loadCharges() }
        }
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

    // MARK: - Invoices

    private var invoiceSection: some View {
        GroupBox("Past Invoices") {
            VStack(spacing: 2) {
                ForEach(invoices.prefix(12)) { invoice in
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(invoice.invoiceNumber ?? invoice.id)
                                .font(.callout)
                            Text(invoice.periodDisplay)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(invoice.statusDisplay)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(invoice.status == "paid" ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundStyle(invoice.status == "paid" ? .green : .orange)
                            .clipShape(Capsule())
                        if let total = invoice.total {
                            Text("$\(total, specifier: "%.2f")")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }

                Link(destination: URL(string: "https://dashboard.civo.com/invoices")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("View & Download PDFs in Civo Dashboard")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .padding(.top, 8)
            }
            .padding(4)
        }
    }

    // MARK: - Data

    private func loadCharges() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let ranges = period.monthlyRanges
        do {
            async let invoicesTask = service.getInvoices()

            var allCharges: [CivoCharge] = []
            for range in ranges {
                let monthCharges = try await service.getCharges(from: range.from, to: range.to)
                allCharges.append(contentsOf: monthCharges)
            }
            charges = allCharges
            invoices = (try? await invoicesTask) ?? []
        } catch {
            self.error = error.localizedDescription
        }
    }
}
