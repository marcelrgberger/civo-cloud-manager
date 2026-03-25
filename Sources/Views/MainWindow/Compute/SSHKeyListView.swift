import SwiftUI

struct SSHKeyListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoSSHKey?
    @State private var showKeychainKeys = false
    @State private var keychainKeys: [String] = []
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
                    keychainKeys = SSHKeychain.listKeys()
                    showKeychainKeys = true
                } label: {
                    Label("Keychain", systemImage: "key.icloud")
                }
                .help("Recover private keys from Keychain")
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
        .sheet(isPresented: $showKeychainKeys) {
            keychainSheet
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

    private var keychainSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "key.icloud")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("SSH Keys in Keychain")
                    .font(.title2.bold())
            }

            Text("Private keys backed up to your Keychain (synced via iCloud).")
                .font(.caption)
                .foregroundStyle(.secondary)

            if keychainKeys.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "key.slash")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No SSH keys in Keychain")
                        .foregroundStyle(.secondary)
                    Text("Keys generated in the app are automatically backed up here.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            } else {
                List {
                    ForEach(keychainKeys, id: \.self) { keyName in
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.orange)
                            Text(keyName)
                                .font(.body.monospaced())
                            Spacer()
                            Button("Export to Downloads") {
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

            Button("Done") { showKeychainKeys = false }
                .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 450)
    }

    private func recoverKey(name: String) {
        guard let keyData = SSHKeychain.load(name: name) else {
            recoveredMessage = "Could not read key from Keychain"
            return
        }
        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            recoveredMessage = "Could not access Downloads folder"
            return
        }
        let targetPath = downloadsDir.appendingPathComponent(name)
        do {
            try keyData.write(to: targetPath)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: targetPath.path)
            NSWorkspace.shared.activateFileViewerSelecting([targetPath])
            recoveredMessage = "Private key '\(name)' exported to ~/Downloads/"
        } catch {
            recoveredMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
