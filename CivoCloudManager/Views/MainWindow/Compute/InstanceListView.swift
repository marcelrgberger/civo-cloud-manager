import SwiftUI

struct InstanceListView: View {
    @Bindable var vm: InstanceViewModel
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
                        if let target = vm.consoleTarget(for: inst) {
                            if inst.status?.lowercased() == "active" {
                                Button("Stop") { vm.beginConfirmation(.power(.stop), for: inst) }
                                Button("Soft Reboot") { vm.beginConfirmation(.power(.softReboot), for: inst) }
                                Button("Hard Reboot...") { vm.beginConfirmation(.power(.hardReboot), for: inst) }
                                Button("Open Console") {
                                    vm.handOverConsoleLogin(of: inst, to: target)
                                    openWindow(id: "console", value: target)
                                }
                            }
                            Button("Credentials…") { credentialsTarget = target }
                            if inst.status?.lowercased() == "shutoff" {
                                Button("Start") { vm.beginConfirmation(.power(.start), for: inst) }
                            }
                        }
                        Divider()
                        Button("Delete", role: .destructive) { vm.beginConfirmation(.delete, for: inst) }
                    }
                }
            }
        }
        .animation(.easeOut, value: vm.instances.map(\.id))
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                if let error = vm.error { ErrorBanner(message: error) }
                if vm.instanceCompleteness.mayBeMissingItems { IncompleteListBanner() }
            }
        }
        .navigationTitle("Instances")
        .overlay { if vm.isLoading && vm.instances.isEmpty { ProgressView("Loading instances...") } }
        .sheet(isPresented: Binding(get: { vm.pendingAction?.kind == .delete }, set: { if !$0 { vm.cancelConfirmation() } })) {
            if let target = vm.pendingAction?.target {
                DeleteConfirmationSheet(
                    resourceType: "Instance",
                    resourceName: target.instanceName,
                    onConfirm: {
                        guard let target = vm.confirmPendingAction() else { return }
                        Task { await vm.removeInstance(target) }
                    },
                    onCancel: { vm.cancelConfirmation() },
                    note: vm.mayHaveSavedCredentials(target) ? "Saved credentials for this instance will be deleted as well." : nil
                )
            }
        }
        .sheet(isPresented: Binding(get: { credentialsTarget != nil }, set: { if !$0 { credentialsTarget = nil } })) {
            if let target = credentialsTarget {
                InstanceCredentialsView(target: target)
            }
        }
        .instancePowerConfirmation(vm)
    }
}
