import SwiftUI

struct SSHKeyListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoSSHKey?

    var body: some View {
        List {
            if vm.sshKeys.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "key", title: "No SSH Keys", message: "No SSH keys found in your account.")
            } else {
                ForEach(vm.sshKeys) { key in
                    ResourceListRow(
                        icon: "key",
                        name: key.name,
                        subtitle: key.fingerprint
                    )
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = key
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("SSH Keys")
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
            if vm.isLoading && vm.sshKeys.isEmpty {
                ProgressView("Loading SSH keys...")
            }
        }
        .confirmationDialog("Delete SSH Key", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeSSHKey(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the SSH key. This action cannot be undone.")
        }
    }
}
