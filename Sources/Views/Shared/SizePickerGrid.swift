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

            let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 10)]

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredSizes) { size in
                    SizeCard(size: size, isSelected: selectedSize == size.name)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text(size.name)
                    .font(.caption.bold())
                if let type = size.type {
                    Text(type)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Specs
            HStack(spacing: 0) {
                specItem("CPU Cores", "\(size.effectiveCpu ?? 0)")
                Spacer()
                specItem("RAM", ramDisplay)
            }

            HStack(spacing: 0) {
                specItem("NVMe", "\(size.effectiveDisk ?? 0) GB")
                Spacer()
                specItem("Transfer", "FREE")
            }

            Divider()

            // Price
            if let rate = CivoCharge.hourlyRates[size.name] ?? CivoCharge.hourlyRates.first(where: { size.name.contains($0.key.components(separatedBy: "-").last ?? "") })?.value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$\(rate, specifier: "%.6f")")
                        .font(.system(.callout, design: .rounded).bold())
                    Text("per hr")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var ramDisplay: String {
        guard let ram = size.effectiveRam else { return "0" }
        return ram >= 1024 ? "\(ram / 1024) GB" : "\(ram) MB"
    }

    private func specItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.bold())
        }
        .frame(minWidth: 50, alignment: .leading)
    }
}
