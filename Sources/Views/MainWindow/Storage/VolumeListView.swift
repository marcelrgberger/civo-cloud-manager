import SwiftUI

struct VolumeListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoVolume?
    @State private var showCleanupWarning = false

    var body: some View {
        Group {
            if let vol = vm.selectedVolume {
                VolumeDetailView(volume: vol, instances: []) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedVolume = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                volumeList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedVolume?.id)
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingVolume = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { showCleanupWarning = true } label: {
                    Label("Cleanup Available", systemImage: "trash.slash")
                }
                .disabled(vm.unusedVolumes.isEmpty || vm.isLoading)
                .help("Delete all volumes with status 'available'")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingVolume) {
            CreateVolumeView(vm: vm).frame(minWidth: 450, minHeight: 250)
        }
        .sheet(isPresented: $showCleanupWarning) {
            CleanupAvailableVolumesSheet(vm: vm) { showCleanupWarning = false }
        }
    }

    private var volumeList: some View {
        List {
            if vm.volumes.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "cylinder", title: "No Volumes", message: "No volumes found in your account.")
            } else {
                ForEach(Array(vm.volumes.enumerated()), id: \.element.id) { index, vol in
                    Button {
                        vm.selectedVolume = vol
                    } label: {
                        ResourceListRow(
                            icon: "cylinder",
                            name: vol.name,
                            subtitle: "\(vol.sizeDisplay) — \(attachmentLabel(vol))",
                            status: vol.status,
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
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
        .overlay { if vm.isLoading && vm.volumes.isEmpty { ProgressView("Loading volumes...") } }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Volume", resourceName: target.name, onConfirm: {
                    Task { await vm.removeVolume(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }

    private func attachmentLabel(_ vol: CivoVolume) -> String {
        if vol.instanceId != nil { return "attached to instance" }
        if vol.clusterId != nil { return "attached to cluster" }
        if let mp = vol.mountpoint, !mp.isEmpty { return mp }
        return "available"
    }
}

struct CleanupAvailableVolumesSheet: View {
    @Bindable var vm: VolumeViewModel
    let onDismiss: () -> Void
    @State private var confirmText = ""

    private let confirmPhrase = "DELETE ALL DATA"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("Cleanup Available Volumes")
                .font(.title2.bold())

            VStack(spacing: 8) {
                Text("This will permanently delete \(vm.unusedVolumes.count) volume\(vm.unusedVolumes.count == 1 ? "" : "s") with status \"available\":")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(vm.unusedVolumes) { vol in
                        HStack(spacing: 6) {
                            Image(systemName: "cylinder")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(vol.name)
                                .font(.callout.monospaced())
                            Text(vol.sizeDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("All data on these volumes will be permanently lost. This action cannot be undone.")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Type \(confirmPhrase) to confirm:")
                    .font(.callout.weight(.medium))
                TextField(confirmPhrase, text: $confirmText)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Delete All Available Volumes", role: .destructive) {
                    Task {
                        await vm.cleanupUnusedVolumes()
                        onDismiss()
                    }
                }
                .disabled(confirmText != confirmPhrase)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 480)
    }
}
