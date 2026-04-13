import SwiftUI

struct SearchResult: Identifiable, Sendable {
    let id: String
    let name: String
    let type: String
    let icon: String
    let iconColor: Color
    let section: SidebarSection
}

struct QuickSearchView: View {
    @Binding var isPresented: Bool
    @Binding var selection: SidebarSection

    let instanceVM: InstanceViewModel
    let kubernetesVM: KubernetesViewModel
    let databaseVM: DatabaseViewModel
    let networkVM: NetworkViewModel
    let volumeVM: VolumeViewModel
    let domainVM: DomainViewModel

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFieldFocused: Bool

    private var results: [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }

        var matches: [SearchResult] = []

        for cluster in kubernetesVM.clusters where cluster.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: cluster.id,
                name: cluster.name,
                type: "Kubernetes",
                icon: SidebarSection.clusters.icon,
                iconColor: SidebarSection.clusters.iconColor,
                section: .clusters
            ))
        }

        for instance in instanceVM.instances where instance.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: instance.id,
                name: instance.name,
                type: "Instance",
                icon: SidebarSection.instances.icon,
                iconColor: SidebarSection.instances.iconColor,
                section: .instances
            ))
        }

        for database in databaseVM.databases where database.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: database.id,
                name: database.name,
                type: "Database",
                icon: SidebarSection.databases.icon,
                iconColor: SidebarSection.databases.iconColor,
                section: .databases
            ))
        }

        for firewall in networkVM.firewalls where firewall.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: firewall.id,
                name: firewall.name,
                type: "Firewall",
                icon: SidebarSection.firewalls.icon,
                iconColor: SidebarSection.firewalls.iconColor,
                section: .firewalls
            ))
        }

        for network in networkVM.networks where (network.name ?? "").lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: network.id,
                name: network.name ?? network.id,
                type: "Network",
                icon: SidebarSection.networks.icon,
                iconColor: SidebarSection.networks.iconColor,
                section: .networks
            ))
        }

        for lb in networkVM.loadBalancers where lb.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: lb.id,
                name: lb.name,
                type: "Load Balancer",
                icon: SidebarSection.loadBalancers.icon,
                iconColor: SidebarSection.loadBalancers.iconColor,
                section: .loadBalancers
            ))
        }

        for volume in volumeVM.volumes where volume.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: volume.id,
                name: volume.name,
                type: "Volume",
                icon: SidebarSection.volumes.icon,
                iconColor: SidebarSection.volumes.iconColor,
                section: .volumes
            ))
        }

        for store in volumeVM.objectStores where store.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: store.id,
                name: store.name,
                type: "Object Store",
                icon: SidebarSection.objectStores.icon,
                iconColor: SidebarSection.objectStores.iconColor,
                section: .objectStores
            ))
        }

        for domain in domainVM.domains where domain.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: domain.id,
                name: domain.name,
                type: "Domain",
                icon: SidebarSection.domains.icon,
                iconColor: SidebarSection.domains.iconColor,
                section: .domains
            ))
        }

        for key in instanceVM.sshKeys where key.name.lowercased().contains(trimmed) {
            matches.append(SearchResult(
                id: key.id,
                name: key.name,
                type: "SSH Key",
                icon: SidebarSection.sshKeys.icon,
                iconColor: SidebarSection.sshKeys.iconColor,
                section: .sshKeys
            ))
        }

        return matches
    }

    private var groupedResults: [(String, [SearchResult])] {
        let grouped = Dictionary(grouping: results) { $0.type }
        return grouped.sorted { $0.key < $1.key }
    }

    private var flatResults: [SearchResult] {
        groupedResults.flatMap { $0.1 }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()

            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                emptyHint
            } else if results.isEmpty {
                noResults
            } else {
                resultsList
            }
        }
        .frame(width: 500, height: 400)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .onAppear {
            isSearchFieldFocused = true
        }
        .onChange(of: query) {
            selectedIndex = 0
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title3)

            TextField("Search resources...", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isSearchFieldFocused)
                .onKeyPress(.upArrow) {
                    moveSelection(by: -1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(by: 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    confirmSelection()
                    return .handled
                }
                .onKeyPress(.escape) {
                    isPresented = false
                    return .handled
                }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    var runningIndex = 0

                    ForEach(groupedResults, id: \.0) { type, items in
                        Text(type)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(Array(items.enumerated()), id: \.element.id) { offset, result in
                            let currentIndex = runningIndex + offset
                            let isSelected = currentIndex == selectedIndex

                            resultRow(result: result, isSelected: isSelected)
                                .id(result.id)
                                .modifier(StaggeredAppear(index: currentIndex))
                                .onTapGesture {
                                    navigate(to: result)
                                }
                                .onHover { hovering in
                                    if hovering {
                                        selectedIndex = currentIndex
                                    }
                                }
                        }

                        let _ = (runningIndex += items.count)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { _, newValue in
                let flat = flatResults
                if newValue >= 0, newValue < flat.count {
                    proxy.scrollTo(flat[newValue].id, anchor: .center)
                }
            }
        }
    }

    private func resultRow(result: SearchResult, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: result.icon)
                .foregroundStyle(result.iconColor)
                .frame(width: 24)

            Text(result.name)
                .lineLimit(1)

            Spacer()

            Text(result.type)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                .padding(.horizontal, 8)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Empty States

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.quaternary)
            Text("Type to search across all resources")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.quaternary)
            Text("No results for \"\(query)\"")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation

    private func moveSelection(by delta: Int) {
        let count = flatResults.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    private func confirmSelection() {
        let flat = flatResults
        guard selectedIndex >= 0, selectedIndex < flat.count else { return }
        navigate(to: flat[selectedIndex])
    }

    private func navigate(to result: SearchResult) {
        selection = result.section
        isPresented = false
    }
}
