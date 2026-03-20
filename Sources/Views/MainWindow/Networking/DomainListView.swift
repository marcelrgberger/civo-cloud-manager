import SwiftUI

struct DomainListView: View {
    @Bindable var vm: DomainViewModel
    @State private var deleteTarget: CivoDomain?
    @State private var selectedDomain: CivoDomain?
    @State private var editingRecord: CivoDomainRecord?
    @State private var deleteRecordTarget: CivoDomainRecord?

    var body: some View {
        List {
            if vm.domains.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "globe", title: "No Domains", message: "No domains found in your account.")
            } else {
                ForEach(vm.domains) { domain in
                    DisclosureGroup {
                        if vm.selectedDomainId == domain.id {
                            if vm.records.isEmpty && !vm.isLoading {
                                Text("No records")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                ForEach(vm.records) { record in
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
                                            vm.isCreatingRecord = true
                                        }
                                        Button("Delete", role: .destructive) {
                                            deleteRecordTarget = record
                                        }
                                    }
                                }
                            }

                            Button {
                                editingRecord = nil
                                selectedDomain = domain
                                vm.isCreatingRecord = true
                            } label: {
                                Label("Add Record", systemImage: "plus")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .padding(.top, 4)
                        }
                    } label: {
                        ResourceListRow(icon: "globe", name: domain.name)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteTarget = domain
                        }
                    }
                    .onAppear {
                        if vm.selectedDomainId != domain.id {
                            Task { await vm.loadRecords(for: domain.id) }
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
        .sheet(isPresented: $vm.isCreatingRecord) {
            CreateDNSRecordView(
                vm: vm,
                domainId: selectedDomain?.id ?? vm.selectedDomainId ?? "",
                editingRecord: editingRecord
            )
            .frame(minWidth: 450, minHeight: 300)
        }
        .confirmationDialog("Delete Domain", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            if let target = deleteTarget {
                Button("Delete \(target.name)", role: .destructive) {
                    Task { await vm.removeDomain(target.id) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the domain and all its records. This action cannot be undone.")
        }
        .confirmationDialog("Delete Record", isPresented: Binding(
            get: { deleteRecordTarget != nil },
            set: { if !$0 { deleteRecordTarget = nil } }
        )) {
            if let target = deleteRecordTarget {
                Button("Delete Record", role: .destructive) {
                    if let domainId = vm.selectedDomainId {
                        Task { await vm.removeRecord(domainId, recordId: target.id) }
                    }
                    deleteRecordTarget = nil
                }
            }
        } message: {
            Text("This will permanently delete the DNS record.")
        }
    }
}
