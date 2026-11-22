import SwiftUI

struct CreateClusterView: View {
    @Bindable var vm: KubernetesViewModel
    @State private var name = ""
    @State private var networkId = ""
    @State private var cniPlugin = "flannel"
    /// Empty for Civo's default version, which sends no `kubernetes_version`.
    @State private var kubernetesVersion = ""
    @State private var nodeSize = ""
    @State private var nodeCount = 3
    @State private var isChoosingApplications = false

    private let cniOptions = ["flannel", "cilium"]

    var body: some View {
        Form {
            Section("Cluster Details") {
                TextField("Name", text: $name)
                Picker("CNI Plugin", selection: $cniPlugin) {
                    ForEach(cniOptions, id: \.self) { Text($0) }
                }
                .help("Network plugin for pod communication")
            }

            Section {
                Picker("Kubernetes Version", selection: $kubernetesVersion) {
                    Text("Civo default").tag("")
                    ForEach(vm.availableVersions) { version in
                        Text(version.label ?? version.version).tag(version.version)
                    }
                }
            } footer: {
                Text(versionFootnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Node Pool") {
                Stepper("Nodes: \(nodeCount)", value: $nodeCount, in: 1...10)
                    .help("Number of worker nodes")
            }

            Section("Select Node Size") {
                SizePickerGrid(sizes: vm.availableSizes, selectedSize: $nodeSize, filterPrefix: "Kubernetes")
            }

            Section("Networking") {
                Picker("Network", selection: $networkId) {
                    Text("Default").tag("")
                    ForEach(vm.availableNetworks) { net in
                        Text(net.displayName).tag(net.id)
                    }
                }
            }

            marketplaceSection

            if !vm.marketplace.state.selection.isEmpty {
                MarketplaceReviewSection(vm: vm)
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Create Kubernetes Cluster")
        .task { await vm.loadFormData() }
        .onReceive(NotificationCenter.default.publisher(for: .civoAPIKeyDidChange)) { _ in
            Task { await vm.marketplace.reload() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .civoRegionDidChange)) { _ in
            Task { await vm.marketplace.reload() }
        }
        .sheet(isPresented: $isChoosingApplications) {
            MarketplacePickerView(vm: vm)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreating = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        var body: [String: Any] = [
                            "name": name,
                            "cni_plugin": cniPlugin,
                            "num_target_nodes": nodeCount,
                        ]
                        if !kubernetesVersion.isEmpty { body["kubernetes_version"] = kubernetesVersion }
                        if !nodeSize.isEmpty { body["target_nodes_size"] = nodeSize }
                        if !networkId.isEmpty { body["network_id"] = networkId }
                        _ = await vm.createCluster(body)
                    }
                }
                .disabled(name.isEmpty || vm.isSaving || !vm.marketplace.state.canSubmit)
            }
        }
    }

    private var marketplaceSection: some View {
        Section {
            if vm.marketplace.state.catalog != nil {
                Button("Choose Applications...") { isChoosingApplications = true }
            }
            if vm.marketplace.state.selection.isEmpty, !vm.marketplace.isLoading {
                Text("No additional applications selected. Civo may still install its default applications.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Marketplace Apps")
        } footer: {
            MarketplaceCatalogStatus(vm: vm)
        }
    }

    private var versionFootnote: String {
        if vm.versionListError != nil {
            return String(localized: "The list of versions could not be loaded, so Civo installs its default version.")
        }
        if let civoDefault = vm.availableVersions.first(where: { $0.isDefault == true }) {
            return String(localized: "Civo default sends no version, so Civo installs the version it marks as default, currently \(civoDefault.label ?? civoDefault.version).")
        }
        return String(localized: "Civo default sends no version, so Civo installs its default version.")
    }
}

/// The chosen applications as they will be sent, directly above Create, with what changed since they were chosen.
private struct MarketplaceReviewSection: View {
    @Bindable var vm: KubernetesViewModel

    var body: some View {
        let issues = vm.marketplace.state.issues
        Section {
            ForEach(vm.marketplace.state.selection.choices, id: \.id) { choice in
                MarketplaceReviewRow(vm: vm, choice: choice, issue: issues[choice.id])
            }
        } header: {
            Text("Applications to install: \(vm.marketplace.state.selection.choices.count)")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Applications may create resources that incur additional Civo charges; this app does not calculate those charges.")
                if !issues.isEmpty {
                    Text(MarketplaceSelectionError.needsReview.message)
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct MarketplaceReviewRow: View {
    @Bindable var vm: KubernetesViewModel
    let choice: MarketplaceChoice
    let issue: MarketplaceSelectionIssue?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: choice.name)
                        .font(.subheadline.weight(.medium))
                    if let plan = choice.plan {
                        Text("Plan: \(plan)")
                            .font(.caption)
                    }
                    if let version = choice.version {
                        Text("Version: \(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer()
                if let issue {
                    Label(issue.label, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    if issue == .detailsChanged || issue == .contextChanged, vm.marketplace.state.isCatalogCurrent {
                        Button("Use Current Details") { vm.marketplace.acceptAgain(choice.id) }
                    }
                }
                Button("Remove") { vm.marketplace.remove(choice.id) }
            }
            if let description = choice.description {
                Text("Description from Civo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: description)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            if !choice.dependencies.isEmpty {
                Text("Civo lists these dependencies: \(choice.dependencies.joined(separator: ", ")). This app does not know whether Civo installs them for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}
