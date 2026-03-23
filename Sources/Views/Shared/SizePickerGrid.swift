import SwiftUI

struct SizePickerGrid: View {
    let sizes: [CivoSize]
    @Binding var selectedSize: String
    var filterPrefix: String? = nil // e.g. "Kubernetes", "Instance", "Database"

    private var applicableSizes: [CivoSize] {
        guard let prefix = filterPrefix else { return sizes }
        return sizes.filter { ($0.type ?? "").localizedCaseInsensitiveContains(prefix) || ($0.name).contains(prefix.lowercased()) }
    }

    private var sizeTypes: [String] {
        let types = Set(applicableSizes.compactMap(\.type))
        let order = ["Standard", "Performance", "CPU-Optimized", "CPU Optimized", "RAM-Optimized", "RAM Optimized", "GPU", "Instance", "Kubernetes", "Database"]
        return types.sorted { a, b in
            let ai = order.firstIndex(where: { a.localizedCaseInsensitiveContains($0) }) ?? 99
            let bi = order.firstIndex(where: { b.localizedCaseInsensitiveContains($0) }) ?? 99
            return ai < bi
        }
    }

    @State private var selectedType: String?

    private var activeType: String {
        selectedType ?? sizeTypes.first ?? ""
    }

    private var filteredSizes: [CivoSize] {
        applicableSizes.filter { $0.type == activeType }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sizeTypes.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(sizeTypes, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Text(type)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(activeType == type ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(activeType == type ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 10)]

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredSizes) { size in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(size.niceName ?? size.displayName)
                            .font(.caption.bold())
                            .lineLimit(1)
                        SizeCard(size: size, isSelected: selectedSize == size.name)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedSize = size.name
                    }
                }
            }
        }
    }
}

private struct SizeCard: View {
    let size: CivoSize
    let isSelected: Bool

    private var hourlyRate: Double? {
        // Try exact match, then partial match on size name
        let rates = CivoCharge.hourlyRates
        if let rate = rates[size.name] { return rate }
        // Match by looking for the size code in charge keys
        for (key, rate) in rates {
            if key.hasSuffix(size.name) || key.contains(size.name) { return rate }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Specs row
            HStack(spacing: 12) {
                specChip("\(size.effectiveCpu ?? 0) vCPU")
                specChip(ramDisplay)
                specChip("\(size.effectiveDisk ?? 0) GB NVMe")
            }

            // Price
            if let rate = hourlyRate {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$\(rate, specifier: "%.2f")")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                    Text("per hr")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("~$\(rate * 730, specifier: "%.0f")/mo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }

    private var ramDisplay: String {
        guard let ram = size.effectiveRam else { return "0" }
        return ram >= 1024 ? "\(ram / 1024) GB RAM" : "\(ram) MB RAM"
    }

    private func specChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
    }
}
