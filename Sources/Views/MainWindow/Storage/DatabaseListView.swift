import SwiftUI

struct DatabaseListView: View {
    @Bindable var vm: DatabaseViewModel
    @State private var deleteTarget: CivoDatabase?

    var body: some View {
        List {
            if vm.databases.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "cylinder.split.1x2", title: "No Databases", message: "No databases found in your account.")
            } else {
                ForEach(vm.databases) { db in
                    databaseRow(db)
                        .contextMenu {
                            Button("Delete", role: .destructive) { deleteTarget = db }
                        }
                }
            }
        }
        .animation(.easeOut, value: vm.databases.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Databases")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreating = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { if vm.isLoading && vm.databases.isEmpty { ProgressView("Loading databases...") } }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreating) {
            CreateDatabaseView(vm: vm).frame(minWidth: 500, minHeight: 400)
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Database", resourceName: target.name, onConfirm: {
                    Task { await vm.removeDatabase(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }

    private func databaseRow(_ db: CivoDatabase) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cylinder.split.1x2")
                .font(.title3).foregroundStyle(.purple).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(db.name).font(.body.weight(.medium))
                HStack(spacing: 8) {
                    Label(db.software ?? "—", systemImage: "cpu")
                    Label("v\(db.softwareVersion ?? "?")", systemImage: "tag")
                    Label(db.size ?? "—", systemImage: "memorychip")
                    Label("Port \(db.port ?? 0)", systemImage: "network")
                }
                .font(.caption).foregroundStyle(.secondary)
                if let host = db.publicIpv4 {
                    Text(host).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }
            Spacer()
            StatusBadge(status: db.status)
        }
        .padding(.vertical, 4)
    }
}
