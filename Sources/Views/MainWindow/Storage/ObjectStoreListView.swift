import SwiftUI

struct ObjectStoreListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoObjectStore?
    @State private var showCredentials = false
    @State private var credential: CivoObjectStoreCredential?
    @State private var credentialError: String?

    private let credentialService = CivoObjectStoreService()

    var body: some View {
        List {
            if vm.objectStores.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "tray.2", title: "No Object Stores", message: "No object stores found in your account.")
            } else {
                ForEach(vm.objectStores) { store in
                    ResourceListRow(
                        icon: "tray.2",
                        name: store.name,
                        subtitle: "\(store.maxSizeDisplay) max — \(store.objectstoreEndpoint ?? "")",
                        status: store.status
                    )
                    .contextMenu {
                        Button("Show Credentials") {
                            Task {
                                do {
                                    credential = try await credentialService.getCredentials()
                                    showCredentials = true
                                } catch {
                                    credentialError = error.localizedDescription
                                }
                            }
                        }
                        Divider()
                        Button("Delete", role: .destructive) { deleteTarget = store }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.objectStores.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error ?? credentialError { ErrorBanner(message: error) }
        }
        .navigationTitle("Object Stores")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingObjectStore = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { if vm.isLoading && vm.objectStores.isEmpty { ProgressView("Loading object stores...") } }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingObjectStore) {
            CreateObjectStoreView(vm: vm).frame(minWidth: 400, minHeight: 200)
        }
        .sheet(isPresented: $showCredentials) {
            if let cred = credential {
                ObjectStoreCredentialView(credential: cred) { showCredentials = false }
                    .frame(minWidth: 450, minHeight: 200)
            }
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Object Store", resourceName: target.name, onConfirm: {
                    Task { await vm.removeObjectStore(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }
}

struct ObjectStoreCredentialView: View {
    let credential: CivoObjectStoreCredential
    let onDismiss: () -> Void

    var body: some View {
        Form {
            Section("Object Store Credentials") {
                LabeledContent("Access Key ID") {
                    Text(credential.accessKeyId ?? "—").textSelection(.enabled).font(.body.monospaced())
                }
                LabeledContent("Secret Access Key") {
                    Text(credential.secretAccessKey ?? "—").textSelection(.enabled).font(.body.monospaced())
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { onDismiss() } }
        }
    }
}
