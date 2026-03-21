import SwiftUI

struct DomainRecordsSection: View {
    @Bindable var vm: DomainViewModel
    let domain: CivoDomain
    @State private var records: [CivoDomainRecord] = []
    @State private var isLoadingRecords = false
    @State private var editingRecord: CivoDomainRecord?
    @State private var isCreatingRecord = false
    @State private var deleteRecordTarget: CivoDomainRecord?

    private let service = CivoDomainService()

    var body: some View {
        Group {
            if isLoadingRecords {
                ProgressView()
                    .controlSize(.small)
            } else if records.isEmpty {
                Text("No records")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(record.type ?? "?") \(record.name ?? "@")")
                                .font(.body.weight(.medium))
                            Text(record.value ?? "—")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("TTL \(record.ttl ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contextMenu {
                        Button("Edit") {
                            editingRecord = record
                            isCreatingRecord = true
                        }
                        Button("Delete", role: .destructive) {
                            deleteRecordTarget = record
                        }
                    }
                }
            }

            Button {
                editingRecord = nil
                isCreatingRecord = true
            } label: {
                Label("Add Record", systemImage: "plus")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .padding(.top, 4)
        }
        .task { await loadRecords() }
        .sheet(isPresented: $isCreatingRecord) {
            CreateDNSRecordView(
                vm: vm,
                domainId: domain.id,
                editingRecord: editingRecord
            )
            .frame(minWidth: 450, minHeight: 300)
        }
        .confirmationDialog("Delete Record", isPresented: Binding(
            get: { deleteRecordTarget != nil },
            set: { if !$0 { deleteRecordTarget = nil } }
        )) {
            if let target = deleteRecordTarget {
                Button("Delete Record", role: .destructive) {
                    Task {
                        do {
                            try await service.removeRecord(domain.id, recordId: target.id)
                            await loadRecords()
                        } catch {
                            vm.error = error.localizedDescription
                        }
                    }
                    deleteRecordTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the DNS record.")
        }
        .onChange(of: vm.showSuccess) { _, newValue in
            if newValue {
                Task { await loadRecords() }
            }
        }
    }

    private func loadRecords() async {
        isLoadingRecords = true
        defer { isLoadingRecords = false }
        do {
            records = try await service.listRecords(domain.id)
        } catch {
            vm.error = error.localizedDescription
        }
    }
}

struct DomainListView: View {
    @Bindable var vm: DomainViewModel
    @State private var deleteTarget: CivoDomain?

    var body: some View {
        List {
            if vm.domains.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "globe", title: "No Domains", message: "No domains found in your account.")
            } else {
                ForEach(Array(vm.domains.enumerated()), id: \.element.id) { index, domain in
                    DisclosureGroup {
                        DomainRecordsSection(vm: vm, domain: domain)
                    } label: {
                        ResourceListRow(icon: "globe", name: domain.name, index: index)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = domain
                        }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.domains.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Domains")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    vm.isCreatingDomain = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
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
            if vm.isLoading && vm.domains.isEmpty {
                ProgressView("Loading domains...")
            }
        }
        .overlay {
            SuccessOverlay(isPresented: $vm.showSuccess)
        }
        .sheet(isPresented: $vm.isCreatingDomain) {
            CreateDomainView(vm: vm)
                .frame(minWidth: 400, minHeight: 150)
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Domain", resourceName: target.name, onConfirm: {
                    Task { await vm.removeDomain(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }
}
