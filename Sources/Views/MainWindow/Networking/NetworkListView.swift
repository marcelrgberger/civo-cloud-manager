import SwiftUI

struct NetworkListView: View {
    @Bindable var vm: NetworkViewModel
    @State private var deleteTarget: CivoNetwork?

    var body: some View {
        List {
            if vm.networks.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "point.3.connected.trianglepath.dotted", title: "No Networks", message: "No networks found in your account.")
            } else {
                ForEach(vm.networks) { net in
                    ResourceListRow(
                        icon: "point.3.connected.trianglepath.dotted",
                        name: net.displayName,
                        subtitle: "Region: \(net.region ?? "—")\(net.isDefault == true ? " — Default" : "")",
                        status: net.status
                    )
                    .contextMenu {
                        if net.isDefault != true {
                            Button("Delete", role: .destructive) {
                                deleteTarget = net
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.networks.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Networks")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingNetwork = true } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading && vm.networks.isEmpty { ProgressView("Loading networks...") }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingNetwork) {
            CreateNetworkView(vm: vm)
                .frame(minWidth: 400, minHeight: 200)
        }
        .sheet(isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Network",
                    resourceName: target.displayName,
                    onConfirm: {
                        Task { await vm.removeNetwork(target.id) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil }
                )
            }
        }
    }
}
