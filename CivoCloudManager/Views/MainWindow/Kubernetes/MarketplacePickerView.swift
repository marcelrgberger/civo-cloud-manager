import SwiftUI

/// Searches Civo's marketplace list and chooses applications for a new cluster. Names, descriptions, categories
/// and plans are shown as Civo lists them, untranslated.
struct MarketplacePickerView: View {
    @Bindable var vm: KubernetesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        Form {
            Section {
                TextField("Search applications", text: $query)
                    .textFieldStyle(.roundedBorder)
            } footer: {
                MarketplaceCatalogStatus(vm: vm)
            }

            if let catalog = vm.marketplace.state.catalog {
                let matches = catalog.search(query)
                Section {
                    if matches.isEmpty {
                        Text("No applications match your search.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(matches) { application in
                        MarketplacePickerRow(vm: vm, application: application)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, minHeight: 520)
        .navigationTitle("Choose Applications")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct MarketplacePickerRow: View {
    @Bindable var vm: KubernetesViewModel
    let application: CivoMarketplaceApplication

    private var choice: MarketplaceChoice? { vm.marketplace.state.selection.choice(for: application.id) }
    private var isSelectable: Bool { application.availability == .selectable }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                if application.plans.isEmpty {
                    Toggle(isOn: isChosen) { title }
                        .toggleStyle(.checkbox)
                } else {
                    title
                    Spacer()
                    Picker("Plan", selection: chosenPlan) {
                        Text("Not selected").tag(String?.none)
                        ForEach(application.plans, id: \.self) { plan in
                            Text(verbatim: plan).tag(Optional(plan))
                        }
                    }
                    .fixedSize()
                }
            }
            if let description = application.description {
                Text(verbatim: description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(description)
            }
            if application.isDefault {
                Text("Civo marks this as default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !application.dependencies.isEmpty {
                Text("Dependencies listed by Civo: \(application.dependencies.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            switch application.availability {
            case .selectable:
                EmptyView()
            case .unsupported:
                Label("Cannot be selected here", systemImage: "nosign")
                    .font(.caption)
                    .foregroundStyle(.orange)
            case .listedMoreThanOnce:
                Label("Civo lists this application more than once with different details", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .disabled(!isSelectable || !vm.marketplace.state.isCatalogCurrent)
        .accessibilityElement(children: .combine)
    }

    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: application.displayName)
                .font(.subheadline.weight(.medium))
            if let version = application.version {
                Text(verbatim: version)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            if let category = application.category {
                Text(verbatim: category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isChosen: Binding<Bool> {
        Binding(
            get: { choice != nil },
            set: { chosen in
                if chosen {
                    vm.marketplace.choose(application, plan: nil)
                } else {
                    vm.marketplace.remove(application.id)
                }
            }
        )
    }

    private var chosenPlan: Binding<String?> {
        Binding(
            get: { choice?.plan },
            set: { plan in
                if let plan {
                    vm.marketplace.choose(application, plan: plan)
                } else {
                    vm.marketplace.remove(application.id)
                }
            }
        )
    }
}

/// Whether Civo's marketplace list loaded completely, partly or not at all, with Reload whenever no load is running.
struct MarketplaceCatalogStatus: View {
    @Bindable var vm: KubernetesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if vm.marketplace.isLoading {
                ProgressView("Loading marketplace applications...")
                    .controlSize(.small)
            } else if let catalog = vm.marketplace.state.catalog {
                if let error = vm.marketplace.state.loadError, let loadedAt = vm.marketplace.state.loadedAt {
                    Label("The list could not be refreshed; details shown are from \(loadedAt.formatted(date: .omitted, time: .shortened)). \(error)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if !catalog.isComplete {
                    Label("Entries from Civo that could not be used or are incomplete: \(catalog.unusableEntryCount)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            } else if let error = vm.marketplace.state.loadError {
                Label("The list of marketplace applications could not be loaded. \(error)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            if !vm.marketplace.isLoading {
                Button("Reload") { Task { await vm.marketplace.reload() } }
            }
        }
        .font(.caption)
    }
}
