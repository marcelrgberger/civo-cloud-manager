import SwiftUI

struct SSHKeyListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoSSHKey?
    @State private var showBackup = false
    @State private var backedUpKeys: [String] = []
    @State private var recoveredMessage: String?

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
                Button {
                    backedUpKeys = SSHKeychain.listKeys()
                    showBackup = true
                } label: {
                    Label("Backup", systemImage: "key.viewfinder")
                }
                .help("Recover backed up private keys")
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
        .sheet(isPresented: $showBackup) {
            backupSheet
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

    private var backupSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("SSH Key Backup")
                    .font(.title2.bold())
            }

            Text("Private keys are encrypted and stored securely in the app.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if backedUpKeys.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "key.slash")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No backed up SSH keys")
                        .foregroundStyle(.secondary)
                    Text("Keys generated in the app are automatically backed up here.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            } else {
                List {
                    ForEach(backedUpKeys, id: \.self) { keyName in
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.orange)
                            Text(keyName)
                                .font(.body.monospaced())
                            Spacer()
                            Button("Export...") {
                                recoverKey(name: keyName)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .frame(height: 200)
            }

            if let msg = recoveredMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(msg)
                        .font(.caption)
                }
            }

            Button("Done") { showBackup = false }
                .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 450)
    }

    private func recoverKey(name: String) {
        guard let keyData = SSHKeychain.load(name: name) else {
            recoveredMessage = "Could not read key from backup"
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export SSH Private Key"
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        do {
            try keyData.write(to: saveURL)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: saveURL.path)
            NSWorkspace.shared.activateFileViewerSelecting([saveURL])
            recoveredMessage = "Private key '\(name)' exported to \(saveURL.path)"
        } catch {
            recoveredMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
