import SwiftUI

struct ReservedIPDetailView: View {
    @Bindable var vm: ReservedIPViewModel
    let onBack: () -> Void

    private var controller: ReservedIPController { vm.controller }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let ip = vm.selectedIP {
                    header(ip)
                    assignmentSection
                    Text("A reserved IP address can incur running costs, also while it is not assigned.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    actions
                }
            }
            .padding(24)
        }
        .navigationTitle(vm.selectedIP?.name ?? "")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.backward") { onBack() }
                    .help("Return to list")
            }
        }
    }

    private func header(_ ip: CivoReservedIP) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ip.name).font(.largeTitle.bold())
            Text(ip.ip ?? "-").font(.subheadline.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
        }
    }

    private var assignmentSection: some View {
        GroupBox("Assignment") {
            VStack(alignment: .leading, spacing: 8) {
                switch vm.detail {
                case .notLoaded, .loading:
                    ProgressView("Loading assignment...")
                case .loaded(let ip):
                    Text(ip.assignment.summary).textSelection(.enabled)
                case .failed(let message):
                    ErrorBanner(message: message)
                    Button("Retry") { Task { await vm.loadDetail() } }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
    }

    private var actions: some View {
        HStack {
            actionButton("Rename...", .rename)
            actionButton("Assign...", .assign)
            actionButton("Unassign...", .unassign)
            actionButton("Release...", .release, role: .destructive)
        }
    }

    private func actionButton(_ title: LocalizedStringKey, _ operation: ReservedIPOperation, role: ButtonRole? = nil) -> some View {
        Button(title, role: role) { vm.begin(operation) }
            .disabled(!isOffered(operation))
    }

    /// Offered only for a loaded detail whose assignment allows it, and while no other action is open.
    private func isOffered(_ operation: ReservedIPOperation) -> Bool {
        guard case .loaded(let ip) = vm.detail, controller.request == nil, !controller.isSending else { return false }
        return ReservedIPRules.eligibilityError(for: operation, assignment: ip.assignment) == nil
    }
}
