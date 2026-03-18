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
                            Button("Delete", role: .destructive) {
                                deleteTarget = db
                            }
                        }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Databases")
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
            if vm.isLoading && vm.databases.isEmpty {
                ProgressView("Loading databases...")
            }
        }
        .confirmationDialog("Delete Database", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeDatabase(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the database. This action cannot be undone.")
        }
    }

    private func databaseRow(_ db: CivoDatabase) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cylinder.split.1x2")
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(db.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 8) {
                    Label(db.software ?? "—", systemImage: "cpu")
                    Label("v\(db.softwareVersion ?? "?")", systemImage: "tag")
                    Label(db.size ?? "—", systemImage: "memorychip")
                    Label("Port \(db.port ?? "?")", systemImage: "network")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let host = db.host {
                    Text(host)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Spacer()

            StatusBadge(status: db.status)
        }
        .padding(.vertical, 4)
    }
}
