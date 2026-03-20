import SwiftUI

struct VolumeListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoVolume?
    @State private var showCleanupConfirm = false

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
                        Button("Delete", role: .destructive) { deleteTarget = vol }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.volumes.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Volumes")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingVolume = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { showCleanupConfirm = true } label: { Label("Cleanup Unused", systemImage: "trash.slash") }
                    .disabled(vm.unusedVolumes.isEmpty || vm.isLoading)
                    .help("Delete all volumes not attached to any instance or cluster")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { if vm.isLoading && vm.volumes.isEmpty { ProgressView("Loading volumes...") } }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingVolume) {
            CreateVolumeView(vm: vm).frame(minWidth: 450, minHeight: 250)
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Volume", resourceName: target.name, onConfirm: {
                    Task { await vm.removeVolume(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
        .confirmationDialog("Cleanup Unused Volumes", isPresented: $showCleanupConfirm) {
            Button("Delete \(vm.unusedVolumes.count) unused volume\(vm.unusedVolumes.count == 1 ? "" : "s")", role: .destructive) {
                Task { await vm.cleanupUnusedVolumes() }
            }
        } message: {
            Text("This will permanently delete all volumes not attached to any instance or cluster. This action cannot be undone.")
        }
    }
}
