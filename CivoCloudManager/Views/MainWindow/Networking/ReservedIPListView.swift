import SwiftUI

struct ReservedIPListView: View {
    @Bindable var vm: ReservedIPViewModel
    @State private var showSuccess = false

    private var controller: ReservedIPController { vm.controller }

    var body: some View {
        Group {
            if vm.selectedID != nil {
                ReservedIPDetailView(vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) { vm.select(nil) }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                list
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedID)
        .task { await vm.refresh() }
        .safeAreaInset(edge: .top) { banners }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.begin(.reserve) } label: { Label("Reserve IP...", systemImage: "plus") }
                    .help("Reserve IP...")
                    .disabled(vm.context == nil || controller.request != nil || controller.isSending)
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload data from API")
                    .disabled(vm.isLoading || controller.isSending)
            }
        }
        .overlay { SuccessOverlay(isPresented: $showSuccess) }
        .sheet(item: Binding(get: { controller.request }, set: { if $0 == nil { controller.cancel() } })) { request in
            sheet(for: request)
        }
    }

    private var banners: some View {
        VStack(spacing: 0) {
            if let error = vm.error { ErrorBanner(message: error) }
            if vm.completeness.mayBeMissingItems { IncompleteListBanner() }
            if let notice = controller.notice {
                NoticeBanner(message: notice.message) { controller.dismissNotice() }
                if notice.offersReload {
                    Button("Reload") { Task { await vm.refresh() } }
                        .padding(.top, 4)
                }
            }
        }
    }

    private var list: some View {
        List {
            if vm.reservedIPs.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "network", title: "No Reserved IPs", message: "No reserved IPs found in this region.")
            } else {
                ForEach(Array(vm.reservedIPs.enumerated()), id: \.element.id) { index, ip in
                    Button {
                        vm.select(ip.id)
                        Task { await vm.loadDetail() }
                    } label: {
                        ResourceListRow(
                            icon: "network",
                            name: ip.name,
                            subtitle: [ip.ip, ip.assignment.summary].compactMap { $0 }.joined(separator: " - "),
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.reservedIPRow(ip.name))
                }
            }
        }
        .navigationTitle("Reserved IPs")
        .overlay { if vm.isLoading && vm.reservedIPs.isEmpty { ProgressView("Loading reserved IPs...") } }
    }

    @ViewBuilder
    private func sheet(for request: ReservedIPController.Request) -> some View {
        switch request.operation {
        case .reserve, .rename:
            ReserveIPView(controller: controller, request: request, onConfirm: confirm)
        case .assign:
            AssignReservedIPView(controller: controller, request: request, onConfirm: confirm)
        case .unassign, .release:
            ReservedIPConfirmationView(controller: controller, request: request, onConfirm: confirm)
        }
    }

    private func confirm(_ action: ReservedIPAction) {
        Task {
            let outcome = await controller.confirm(action)
            if outcome == .done { showSuccess = true }
        }
    }
}
