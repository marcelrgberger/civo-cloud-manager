import SwiftUI

struct ObjectStoreListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoObjectStore?

    private var navigationKey: String {
        if vm.browsingObjectStore != nil { return "browse" }
        if vm.selectedObjectStore != nil { return "detail" }
        return "list"
    }

    var body: some View {
        Group {
            if let store = vm.browsingObjectStore {
                ObjectStoreBrowserView(
                    store: store,
                    s3Client: S3Client(
                        endpoint: store.objectstoreEndpoint ?? "objectstore.\(CivoConfig.shared.region).civo.com",
                        accessKey: store.accessKeyId ?? "",
                        secretKey: store.secretAccessKey ?? "",
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
    }

    private var storeList: some View {
        List {
            if vm.objectStores.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "tray.2", title: "No Object Stores", message: "No object stores found in your account.")
            } else {
                ForEach(Array(vm.objectStores.enumerated()), id: \.element.id) { index, store in
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
                        Button("Delete", role: .destructive) { deleteTarget = store }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.objectStores.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
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
