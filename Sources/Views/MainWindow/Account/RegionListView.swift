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
                    let counts = vm.regionCounts[region.code]

                    HStack(spacing: 12) {
                        Image(systemName: isCurrent ? "mappin.circle.fill" : "mappin.circle")
                            .font(.title3)
                            .foregroundStyle(isCurrent ? .blue : .secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
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

                            HStack(spacing: 2) {
                                Text("\(region.countryDisplay) — \(region.code)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let counts {
                                if counts.isLoading {
                                    ProgressView()
                                        .controlSize(.mini)
                                } else {
                                    HStack(spacing: 8) {
                                        resourceBadge("desktopcomputer", counts.instances, .green)
                                        resourceBadge("helm", counts.clusters, .blue)
                                        resourceBadge("cylinder.split.1x2", counts.databases, .purple)
                                        resourceBadge("point.3.connected.trianglepath.dotted", counts.networks, .green)
                                        resourceBadge("cylinder", counts.volumes, .orange)
                                    }
                                }
                            }
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
        .task {
            await vm.refresh()
            await vm.loadCurrentRegionCounts()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await vm.refresh()
                        await vm.loadCurrentRegionCounts()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Reload data from API")
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.regions.isEmpty {
                ProgressView("Loading regions...")
            }
        }
    }

    private func resourceBadge(_ icon: String, _ count: Int?, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(count ?? 0)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
