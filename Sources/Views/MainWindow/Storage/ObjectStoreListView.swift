import SwiftUI

struct ObjectStoreListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoObjectStore?
    @State private var pauseTarget: CivoObjectStore?
    @State private var resumeTarget: PausedObjectStore?

    private var navigationKey: String {
        if vm.browsingObjectStore != nil { return "browse" }
        if vm.selectedObjectStore != nil { return "detail" }
        return "list"
    }

    var body: some View {
        Group {
            if let store = vm.browsingObjectStore, let cred = vm.credentialForStore(store) {
                ObjectStoreBrowserView(
                    store: store,
                    s3Client: S3Client(
                        endpoint: store.objectstoreEndpoint ?? "objectstore.\(CivoConfig.shared.region).civo.com",
                        accessKey: cred.accessKeyId ?? "",
                        secretKey: cred.secretAccessKeyId ?? "",
                        region: CivoConfig.shared.region
                    )
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.browsingObjectStore = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let store = vm.selectedObjectStore {
                ObjectStoreDetailView(store: store, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedObjectStore = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                storeList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: navigationKey)
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingObjectStore = true } label: { Label("Add", systemImage: "plus") }
                    .help("Create new object store")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload data from API")
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingObjectStore) {
            CreateObjectStoreView(vm: vm).frame(minWidth: 400, minHeight: 200)
        }
        .sheet(isPresented: Binding(get: { vm.isPausing || vm.isResuming }, set: { _ in })) {
            ObjectStorePauseView(
                storeName: pauseTarget?.name ?? resumeTarget?.originalName ?? "",
                mode: vm.isPausing ? .pause : .resume,
                progress: vm.pauseProgress,
                credentialName: pauseCredentialName,
                onCancel: {
                    vm.cancelPauseResume()
                    pauseTarget = nil
                    resumeTarget = nil
                }
            )
            .interactiveDismissDisabled()
        }
    }

    private var pauseCredentialName: String? {
        if let store = pauseTarget {
            return vm.credentialForStore(store)?.displayName
        }
        if let paused = resumeTarget, let credId = paused.credentialId {
            return vm.credentials.first(where: { $0.id == credId })?.displayName
        }
        return nil
    }

    private var storeList: some View {
        List {
            if vm.visibleObjectStores.isEmpty && vm.pausedStores.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "tray.2", title: "No Object Stores", message: "No object stores found in your account.")
            } else {
                // Active stores
                if !vm.visibleObjectStores.isEmpty {
                    Section {
                        ForEach(Array(vm.visibleObjectStores.enumerated()), id: \.element.id) { index, store in
                            Button {
                                Task { await vm.loadObjectStoreDetail(store.id) }
                            } label: {
                                ResourceListRow(
                                    icon: "tray.2",
                                    name: store.name,
                                    subtitle: "\(store.maxSizeDisplay) max — \(store.objectstoreEndpoint ?? "")",
                                    status: store.status,
                                    index: index
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if vm.vaultEnabled {
                                    Button {
                                        pauseTarget = store
                                        vm.pauseObjectStore(store)
                                    } label: {
                                        Label("Pause", systemImage: "pause.circle")
                                    }
                                    .disabled(vm.isPausing || vm.isResuming)
                                    Divider()
                                }
                                Button("Delete", role: .destructive) { deleteTarget = store }
                                    .disabled(vm.isPausing || vm.isResuming)
                            }
                        }
                    }
                }

                // Paused stores
                if !vm.pausedStores.isEmpty {
                    Section("Paused") {
                        ForEach(vm.pausedStores) { paused in
                            HStack(spacing: 12) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(paused.originalName)
                                        .fontWeight(.medium)
                                    Text("\(paused.fileCount) files, \(paused.totalSizeDisplay) — paused \(paused.pausedAtDisplay)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    resumeTarget = paused
                                    vm.resumeObjectStore(paused)
                                } label: {
                                    Label("Resume", systemImage: "play.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)
                                .help("Resume object store")
                            }
                            .padding(.vertical, 4)
                            .contextMenu {
                                Button {
                                    resumeTarget = paused
                                    vm.resumeObjectStore(paused)
                                } label: {
                                    Label("Resume", systemImage: "play.circle")
                                }
                            }
                        }
                    }
                }

                // Vault info
                if vm.vaultEnabled, let vault = vm.objectStores.first(where: { $0.name == ObjectStorePauseService.vaultName }) {
                    Section("Vault") {
                        HStack(spacing: 12) {
                            Image(systemName: "archivebox.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ObjectStorePauseService.vaultName)
                                    .fontWeight(.medium)
                                Text("\(vault.maxSizeDisplay) max — \(vm.pausedStores.count) paused store\(vm.pausedStores.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            StatusBadge(status: vault.status ?? "ready")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.visibleObjectStores.map(\.id))
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                if let error = vm.error { ErrorBanner(message: error) }
                if let pauseError = vm.pauseError { ErrorBanner(message: pauseError) }

                // Enable vault banner
                if !vm.vaultEnabled && !vm.isLoading && !vm.visibleObjectStores.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.circle")
                            .foregroundStyle(.orange)
                        Text("Enable Pause to save costs by archiving inactive stores")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Enable") {
                            Task { await vm.setupVault() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(.orange.opacity(0.05))
                }
            }
        }
        .navigationTitle("Object Stores")
        .overlay { if vm.isLoading && vm.objectStores.isEmpty { ProgressView("Loading object stores...") } }
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
