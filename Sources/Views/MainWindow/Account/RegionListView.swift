import SwiftUI

struct RegionListView: View {
    @Bindable var vm: RegionViewModel

    private var currentRegionCode: String {
        CivoConfig.shared.region
    }

    var body: some View {
        List {
            if vm.regions.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "map", title: "No Regions", message: "No regions available.")
            } else {
                ForEach(vm.regions) { region in
                    let isCurrent = region.code == currentRegionCode
                    HStack(spacing: 12) {
                        Image(systemName: isCurrent ? "mappin.circle.fill" : "mappin.circle")
                            .font(.title3)
                            .foregroundStyle(isCurrent ? .blue : .secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(region.name)
                                    .font(.body.weight(.medium))
                                if isCurrent {
                                    Text("Current")
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("\(region.countryDisplay) — \(region.code)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !isCurrent {
                            Button("Use") {
                                vm.useRegion(region.code)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Regions")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await vm.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.regions.isEmpty {
                ProgressView("Loading regions...")
            }
        }
    }
}
