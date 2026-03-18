import SwiftUI

struct ObjectStoreListView: View {
    @Bindable var vm: VolumeViewModel
    @State private var deleteTarget: CivoObjectStore?

    var body: some View {
        List {
            if vm.objectStores.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "tray.2", title: "No Object Stores", message: "No object stores found in your account.")
            } else {
                ForEach(vm.objectStores) { store in
                    ResourceListRow(
                        icon: "tray.2",
                        name: store.name,
                        subtitle: "\(store.maxSize ?? "?") GB max — \(store.objectstoreEndpoint ?? "")",
                        status: store.status
                    )
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = store
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Object Stores")
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
            if vm.isLoading && vm.objectStores.isEmpty {
                ProgressView("Loading object stores...")
            }
        }
        .confirmationDialog("Delete Object Store", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeObjectStore(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the object store and all its contents. This action cannot be undone.")
        }
    }
}
