import SwiftUI

struct VolumeListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoVolume?

    var body: some View {
        List {
            if vm.volumes.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "cylinder", title: "No Volumes", message: "No volumes found in your account.")
            } else {
                ForEach(vm.volumes) { vol in
                    ResourceListRow(
                        icon: "cylinder",
                        name: vol.name,
                        subtitle: "\(vol.sizeDisplay) — \(vol.mountpoint ?? "unmounted")",
                        status: vol.status
                    )
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = vol
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Volumes")
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
            if vm.isLoading && vm.volumes.isEmpty {
                ProgressView("Loading volumes...")
            }
        }
        .confirmationDialog("Delete Volume", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeVolume(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the volume. This action cannot be undone.")
        }
    }
}
