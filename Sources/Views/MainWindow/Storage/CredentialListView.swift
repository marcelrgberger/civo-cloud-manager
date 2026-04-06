import SwiftUI
import LocalAuthentication

struct CredentialListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoObjectStoreCredential?
    @State private var newCredName = ""
    @State private var revealedSecrets: Set<String> = []
    @State private var listAppeared = false

    var body: some View {
        List {
            if vm.credentials.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "key.horizontal", title: "No Credentials", message: "Create credentials to access your object stores.")
            } else {
                ForEach(Array(vm.credentials.enumerated()), id: \.element.id) { index, cred in
                    credentialRow(cred)
                        .opacity(listAppeared ? 1 : 0)
                        .offset(x: listAppeared ? 0 : -12)
                        .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.06), value: listAppeared)
                        .contextMenu {
                            Button("Delete", role: .destructive) { deleteTarget = cred }
                        }
                }
            }

            Section("Create New Credential") {
                HStack {
                    TextField("Credential Name", text: $newCredName)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        Task {
                            _ = await vm.createCredential(newCredName)
                            newCredName = ""
                        }
                    }
                    .disabled(newCredName.isEmpty || vm.isSaving)
                }
            }
        }
        .animation(.easeOut, value: vm.credentials.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Object Store Credentials")
        .task {
            listAppeared = false
            await vm.refresh()
            withAnimation { listAppeared = true }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Reload data from API")
                .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Credential",
                    resourceName: target.displayName,
                    onConfirm: {
                        Task { await vm.removeCredential(target.id) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil }
                )
            }
        }
    }

    @State private var hoveredCredId: String?

    private func credentialRow(_ cred: CivoObjectStoreCredential) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "key.horizontal")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                    .rotationEffect(.degrees(hoveredCredId == cred.id ? -15 : 0))
                    .animation(.spring(duration: 0.3, bounce: 0.4), value: hoveredCredId)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cred.displayName)
                        .font(.body.weight(.medium))
                    Text(cred.accessKeyId ?? "—")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer()
                StatusBadge(status: cred.status ?? "ready")
            }

            HStack {
                Text("Secret:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if revealedSecrets.contains(cred.id) {
                    Text(cred.secretAccessKeyId ?? "—")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                } else {
                    Text(String(repeating: "*", count: 16))
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    toggleSecret(cred.id)
                } label: {
                    Image(systemName: revealedSecrets.contains(cred.id) ? "eye.slash" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Reveal secret (requires authentication)")
            }
            .padding(.leading, 38)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hoveredCredId == cred.id ? Color.orange.opacity(0.05) : Color.clear)
        )
        .onHover { isHovered in
            withAnimation(.easeOut(duration: 0.15)) {
                hoveredCredId = isHovered ? cred.id : nil
            }
        }
        .animation(.easeOut(duration: 0.2), value: revealedSecrets.contains(cred.id))
    }

    private func toggleSecret(_ id: String) {
        if revealedSecrets.contains(id) {
            revealedSecrets.remove(id)
            return
        }
        Task {
            let context = LAContext()
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Reveal secret access key")
                if success { revealedSecrets.insert(id) }
            } catch {
                // User cancelled or auth failed
            }
        }
    }
}
