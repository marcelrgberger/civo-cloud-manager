import SwiftUI

struct SSHKeyListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoSSHKey?

    var body: some View {
        List {
            if vm.sshKeys.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "key", title: "No SSH Keys", message: "No SSH keys found in your account.")
            } else {
                ForEach(Array(vm.sshKeys.enumerated()), id: \.element.id) { index, key in
                    ResourceListRow(icon: "key", name: key.name, subtitle: key.fingerprint, index: index)
                        .contextMenu {
                            Button("Delete", role: .destructive) { deleteTarget = key }
                        }
                }
            }
        }
        .animation(.easeOut, value: vm.sshKeys.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("SSH Keys")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingSSHKey = true } label: { Label("Add", systemImage: "plus") }
                    .help("Create new SSH key")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload data from API")
                    .disabled(vm.isLoading)
            }
        }
        .overlay { if vm.isLoading && vm.sshKeys.isEmpty { ProgressView("Loading SSH keys...") } }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingSSHKey) {
            CreateSSHKeyView(vm: vm).frame(minWidth: 500, minHeight: 250)
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "SSH Key", resourceName: target.name, onConfirm: {
                    Task { await vm.removeSSHKey(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }
}
