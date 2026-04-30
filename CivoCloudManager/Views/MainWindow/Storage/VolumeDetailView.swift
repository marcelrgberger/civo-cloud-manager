import SwiftUI

struct VolumeDetailView: View {
    let volume: CivoVolume
    let instances: [CivoInstance]
    let onBack: () -> Void
    var vm: VolumeViewModel? = nil
    @State private var appeared = false
    @State private var showResize = false

    private var attachedTo: String {
        if let instanceId = volume.instanceId {
            if let instance = instances.first(where: { $0.id == instanceId }) {
                return "Instance: \(instance.name)"
            }
            return "Instance: \(instanceId)"
        }
        if let clusterId = volume.clusterId {
            return "Kubernetes Cluster: \(clusterId)"
        }
        return "Not attached"
    }

    private var attachmentIcon: String {
        if volume.instanceId != nil { return "desktopcomputer" }
        if volume.clusterId != nil { return "helm" }
        return "eject"
    }

    private var attachmentColor: Color {
        if volume.instanceId != nil || volume.clusterId != nil { return .green }
        return .secondary
    }

    private var isAttached: Bool {
        volume.instanceId != nil || volume.clusterId != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                attachmentSection
                configSection
            }
            .padding(24)
        }
        .navigationTitle(volume.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
                    .help("Return to list")
            }
            if vm != nil {
                ToolbarItem(placement: .automatic) {
                    Button("Resize", systemImage: "arrow.up.left.and.arrow.down.right") {
                        showResize = true
                    }
                    .disabled(isAttached)
                    .help(isAttached
                        ? "Detach volume before resizing"
                        : "Increase volume size")
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
        .sheet(isPresented: $showResize) {
            if let vm {
                ResizeVolumeSheet(vm: vm, volume: volume) { showResize = false }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(volume.name)
                    .font(.largeTitle.bold())
                Text(volume.sizeDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: volume.status ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var attachmentSection: some View {
        GroupBox("Attachment") {
            HStack(spacing: 12) {
                Image(systemName: attachmentIcon)
                    .font(.title2)
                    .foregroundStyle(attachmentColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachedTo)
                        .font(.subheadline.weight(.medium))
                    if let mountpoint = volume.mountpoint {
                        Text("Mounted at: \(mountpoint)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not mounted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Details") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Size", volume.sizeDisplay)
                infoRow("Status", volume.status ?? "—")
                infoRow("Region", volume.region ?? "—")
                infoRow("Network ID", volume.networkId ?? "Default")
                infoRow("Bootable", volume.bootable == true ? "Yes" : "No")
                infoRow("Created", volume.createdAt ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}

struct ResizeVolumeSheet: View {
    @Bindable var vm: VolumeViewModel
    let volume: CivoVolume
    let onDismiss: () -> Void

    @State private var newSize: Int

    init(vm: VolumeViewModel, volume: CivoVolume, onDismiss: @escaping () -> Void) {
        self.vm = vm
        self.volume = volume
        self.onDismiss = onDismiss
        let current = volume.sizeGb ?? 1
        _newSize = State(initialValue: current + 1)
    }

    private var currentSize: Int { volume.sizeGb ?? 1 }
    private var minSize: Int { currentSize + 1 }
    private var canSubmit: Bool { newSize >= minSize && !vm.isSaving }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Resize Volume")
                .font(.title2.bold())

            Text(volume.name)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Text("Current size")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currentSize) GB")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("New size")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Stepper(value: $newSize, in: minSize...10000, step: 1) {
                        Text("\(newSize) GB")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .frame(width: 180)
                }
            }
            .padding()
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Volume size can only be increased, not decreased. The volume will be expanded online — no downtime required.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if let error = vm.saveError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Resize") {
                    Task {
                        let ok = await vm.resizeVolume(volume.id, newSizeGb: newSize)
                        if ok { onDismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 460)
        .overlay {
            if vm.isSaving {
                Color.black.opacity(0.1)
                    .overlay { ProgressView("Resizing...") }
            }
        }
    }
}
