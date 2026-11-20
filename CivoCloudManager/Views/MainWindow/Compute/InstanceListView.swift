import SwiftUI

struct InstanceListView: View {
    @Bindable var vm: InstanceViewModel
    @State private var deleteTarget: CivoInstance?
    @State private var credentialsTarget: ConsoleTarget?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if let inst = vm.selectedInstance {
                InstanceDetailView(instance: inst, vm: vm) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        vm.selectedInstance = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                instanceList
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.selectedInstance?.id)
        .task {
            await vm.refresh()
            while vm.selectedInstanceIsBuilding {
                try? await Task.sleep(for: .seconds(5))
                await vm.refresh()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { vm.isCreatingInstance = true } label: { Label("Add", systemImage: "plus") }
                    .help("Create new instance")
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await vm.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload data from API")
                    .disabled(vm.isLoading)
            }
        }
        .overlay { SuccessOverlay(isPresented: $vm.showSuccess) }
        .sheet(isPresented: $vm.isCreatingInstance) {
            CreateInstanceView(vm: vm).frame(minWidth: 500, minHeight: 400)
        }
    }

    private var instanceList: some View {
        List {
            if vm.instances.isEmpty && !vm.isLoading {
                EmptyStateView(icon: "desktopcomputer", title: "No Instances", message: "No compute instances found in your account.")
            } else {
                ForEach(Array(vm.instances.enumerated()), id: \.element.id) { index, inst in
                    Button {
                        vm.selectedInstance = inst
                    } label: {
                        ResourceListRow(
                            icon: "desktopcomputer",
                            name: inst.name,
                            subtitle: [inst.size, inst.publicIp].compactMap { $0 }.joined(separator: " — "),
                            status: inst.status,
                            index: index
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if inst.status?.lowercased() == "active" {
                            Button("Stop") { Task { await vm.stopInstance(inst.id) } }
                            Button("Reboot") { Task { await vm.rebootInstance(inst.id) } }
                            if let target = vm.consoleTarget(for: inst) {
                                Button("Open Console") {
                                    vm.handOverConsoleLogin(of: inst, to: target)
                                    openWindow(id: "console", value: target)
                                }
                            }
                        }
                        if let target = vm.consoleTarget(for: inst) {
                            Button("Credentials…") { credentialsTarget = target }
                        }
                        if inst.status?.lowercased() == "shutoff" {
                            Button("Start") { Task { await vm.startInstance(inst.id) } }
                        }
                        Divider()
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
        .overlay { if vm.isLoading && vm.instances.isEmpty { ProgressView("Loading instances...") } }
        .sheet(isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            if let target = deleteTarget {
                DeleteConfirmationSheet(
                    resourceType: "Instance",
                    resourceName: target.name,
                    onConfirm: {
                        Task { await vm.removeInstance(target) }
                        deleteTarget = nil
                    },
                    onCancel: { deleteTarget = nil },
                    note: vm.mayHaveSavedCredentials(target) ? "Saved credentials for this instance will be deleted as well." : nil
                )
            }
        }
        .sheet(isPresented: Binding(get: { credentialsTarget != nil }, set: { if !$0 { credentialsTarget = nil } })) {
            if let target = credentialsTarget {
                InstanceCredentialsView(target: target)
            }
        }
    }
}
