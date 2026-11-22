import SwiftUI
import LocalAuthentication

struct ObjectStoreDetailView: View {
    let store: CivoObjectStore
    @Bindable var vm: VolumeViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var newSize: Int
    @State private var isResizing = false
    @State private var reveal = SecretRevealState()

    private var revealIdentity: String {
        "\(vm.credentialStateID)-\(store.id)-\(store.credentialId ?? "")-\(store.accessKeyId ?? "")"
    }

    private var secretRevealed: Bool {
        vm.canUseCredentials(for: store) && reveal.isRevealed(for: revealIdentity)
    }

    private var credential: CivoObjectStoreCredential? {
        vm.credentialForStore(store)
    }

    init(store: CivoObjectStore, vm: VolumeViewModel, onBack: @escaping () -> Void) {
        self.store = store
        self.vm = vm
        self.onBack = onBack
        _newSize = State(initialValue: store.maxSize ?? 500)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                browseFilesButton
                credentialsSection
                configSection
                resizeSection
            }
            .padding(24)
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.backward") { onBack() }
                    .help("Return to list")
            }
        }
        .sheet(isPresented: Binding(get: { vm.credentialSwitcher.session != nil }, set: { if !$0 { vm.credentialSwitcher.cancel() } })) {
            ObjectStoreCredentialSheet(switcher: vm.credentialSwitcher)
        }
        .onChange(of: revealIdentity) { reveal.reset() }
        .onChange(of: vm.canUseCredentials(for: store)) { reveal.reset() }
        .onChange(of: vm.isCredentialAccessAllowed) {
            if !vm.isCredentialAccessAllowed { vm.credentialSwitcher.cancel() }
        }
        .onDisappear { reveal.reset() }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name).font(.largeTitle.bold())
                Text(store.maxSizeDisplay).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: store.status ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var browseFilesButton: some View {
        Button {
            if vm.canUseCredentials(for: store) { vm.browsingObjectStore = store }
        } label: {
            HStack {
                Image(systemName: "folder.fill").foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse Files").font(.headline)
                    Text("Navigate folders, view and download files").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.forward").foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(credential == nil || !vm.canUseCredentials(for: store))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.05), value: appeared)
    }

    private var credentialsSection: some View {
        GroupBox("Credentials") {
            VStack(alignment: .leading, spacing: 12) {
                if let cred = credential {
                    VStack(alignment: .leading, spacing: 10) {
                        infoRow("Credential Name", cred.displayName)
                        infoRow("Access Key ID", cred.accessKeyId ?? "—")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Secret Access Key").font(.caption).foregroundStyle(.secondary)
                                if secretRevealed {
                                    Text(cred.secretAccessKeyId ?? "—").font(.subheadline.monospaced()).textSelection(.enabled)
                                } else {
                                    Text(String(repeating: "*", count: 20)).font(.subheadline.monospaced())
                                }
                            }
                            Spacer()
                            Button {
                                authenticateToRevealSecret()
                            } label: {
                                Image(systemName: secretRevealed ? "eye.slash" : "eye")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .disabled(!vm.canUseCredentials(for: store))
                        }
                        infoRow("Endpoint", store.objectstoreEndpoint ?? "—")
                    }
                    .padding(8)
                } else if !vm.isAssignmentUnconfirmed(store.id) {
                    VStack(spacing: 8) {
                        Text("No credentials assigned").font(.caption).foregroundStyle(.secondary)
                        Text("Assign credentials when creating the object store.").font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(8)
                }
                if vm.isAssignmentUnconfirmed(store.id) {
                    Text(ObjectStoreCredentialChangeError.unconfirmed.message).foregroundStyle(.orange)
                    Button("Check again") {
                        Task { await vm.credentialSwitcher.checkAgain(storeId: store.id) }
                    }
                    .disabled(vm.operationGate.isBusy || !vm.isCredentialAccessAllowed)
                }
                if store.name != ObjectStorePauseService.vaultName {
                    Button("Change Credential...") {
                        Task { await vm.credentialSwitcher.begin(for: store) }
                    }
                    .disabled(vm.credentialChangeProblem(for: store) != nil)
                    .help(vm.credentialChangeProblem(for: store)?.message ?? String(localized: "Change Credential..."))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Details") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Max Size", store.maxSizeDisplay)
                infoRow("Region", vm.selectedObjectStoreContext?.region ?? "")
                infoRow("Status", store.status ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private var resizeSection: some View {
        GroupBox("Resize") {
            VStack(alignment: .leading, spacing: 12) {
                Stepper("New Size: \(newSize) GB", value: $newSize, in: 250...100000, step: 250)
                if newSize != (store.maxSize ?? 500) {
                    Button {
                        isResizing = true
                        Task {
                            let success = await vm.updateObjectStoreSize(store.id, newSize: newSize)
                            isResizing = false
                            if success { onBack() }
                        }
                    } label: {
                        HStack {
                            if isResizing { ProgressView().controlSize(.small) }
                            Text("Apply: \(store.maxSize ?? 0) GB → \(newSize) GB")
                        }
                    }
                    .disabled(isResizing || vm.operationGate.isBusy || vm.isAssignmentUnconfirmed(store.id))
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private func authenticateToRevealSecret() {
        guard vm.canUseCredentials(for: store) else { return }
        if secretRevealed {
            reveal.reset()
            return
        }
        let identity = revealIdentity
        let ticket = reveal.begin(for: identity)
        Task {
            let context = LAContext()
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "Reveal secret access key"))
                guard identity == revealIdentity, vm.canUseCredentials(for: store) else { return }
                reveal.complete(ticket, success: success)
            } catch {
                reveal.complete(ticket, success: false)
            }
        }
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.monospaced()).textSelection(.enabled)
        }
    }
}
