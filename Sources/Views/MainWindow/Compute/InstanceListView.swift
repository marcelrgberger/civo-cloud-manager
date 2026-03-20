import SwiftUI

struct InstanceListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoInstance?

    var body: some View {
        List {
            if vm.instances.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "desktopcomputer", title: "No Instances", message: "No compute instances found in your account.")
            } else {
                ForEach(vm.instances) { inst in
                    ResourceListRow(
                        icon: "desktopcomputer",
                        name: inst.name,
                        subtitle: [inst.size, inst.publicIp].compactMap { $0 }.joined(separator: " — "),
                        status: inst.status
                    )
                    .contextMenu {
                        Button("Delete", role: .destructive) { deleteTarget = inst }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.instances.map(\.id))
        .safeAreaInset(edge: .top) {
            if let error = vm.error { ErrorBanner(message: error) }
        }
        .navigationTitle("Instances")
        .task { await vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingInstance = true } label: { Label("Add", systemImage: "plus") }
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(vm.isLoading)
            }
        }
        .overlay { if vm.isLoading && vm.instances.isEmpty { ProgressView("Loading instances...") } }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingInstance) {
            CreateInstanceView(vm: vm).frame(minWidth: 500, minHeight: 400)
        }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(resourceType: "Instance", resourceName: target.name, onConfirm: {
                    Task { await vm.removeInstance(target.id) }
                    deleteTarget = nil
                }, onCancel: { deleteTarget = nil })
            }
        }
    }
}
