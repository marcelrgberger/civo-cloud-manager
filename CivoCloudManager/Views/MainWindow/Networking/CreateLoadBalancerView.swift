import SwiftUI

/// Creates a load balancer in the network and region the form was opened with. Create is the confirmation;
/// Full Access, account and region are checked again when it is pressed.
struct CreateLoadBalancerView: View {
    @Bindable var creator: LoadBalancerCreateController
    let onFinished: (LoadBalancerCreateOutcome) -> Void

    @State private var draft = LoadBalancerDraft()

    private var problems: [LoadBalancerDraftProblem] { draft.problems() }

    var body: some View {
        Form {
            Section("Load Balancer Details") {
                TextField("Name", text: $draft.name)
                Picker("Network", selection: $draft.networkId) {
                    if creator.networks.isEmpty {
                        Text("No networks").tag("")
                    }
                    ForEach(creator.networks) { network in
                        Text(verbatim: network.displayName).tag(network.id)
                    }
                }
                .disabled(creator.phase == .loadingNetworks)
                Picker("Algorithm", selection: $draft.algorithm) {
                    ForEach(LoadBalancerAlgorithm.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                }
                Picker("Traffic Policy", selection: $draft.trafficPolicy) {
                    Text("Civo default").tag(LoadBalancerTrafficPolicy?.none)
                    ForEach(LoadBalancerTrafficPolicy.allCases, id: \.self) { Text(verbatim: $0.rawValue).tag(Optional($0)) }
                }
                if let region = creator.form?.context.region {
                    LabeledContent("Region") { Text(verbatim: region.uppercased()) }
                }
            }

            Section("Backends") {
                LoadBalancerBackendTable(existing: [], rows: $draft.backends)
            }

            Section {
                Label("A new load balancer creates ongoing charges on your Civo account.", systemImage: "creditcard")
                    .foregroundStyle(.orange)
            }

            if !problems.isEmpty {
                Section {
                    ForEach(problems, id: \.self) { Text($0.message).foregroundStyle(.red) }
                }
            }
            if let error = creator.error {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("New Load Balancer")
        .interactiveDismissDisabled(creator.isSubmitting)
        .onChange(of: creator.networks.map(\.id), initial: true) { _, ids in
            guard !ids.contains(draft.networkId) else { return }
            draft.networkId = creator.networks.first(where: { $0.isDefault == true })?.id ?? ids.first ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { creator.endForm() }
                    .disabled(creator.isSubmitting)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { onFinished(await creator.create(draft)) }
                }
                .disabled(!problems.isEmpty || creator.phase != .ready)
            }
        }
        .overlay {
            if creator.isSubmitting { ProgressView() }
        }
    }
}
