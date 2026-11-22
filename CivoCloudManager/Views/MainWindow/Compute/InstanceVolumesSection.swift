import SwiftUI

/// The Volumes box of the instance detail page. Attaching and detaching use the target captured when the
/// sheet or confirmation opened; the view model checks it, Full Access and the volume list again on confirm.
struct InstanceVolumesSection: View {
    let instance: CivoInstance
    let vm: InstanceViewModel

    private var options: InstanceVolumeOptions? { vm.volumeOptions(for: instance) }

    private var pendingDetach: (volumeName: String, instanceName: String)? {
        guard let pending = vm.pendingAction, pending.target.instanceId == instance.id,
              case .detachVolume(_, let name) = pending.kind else { return nil }
        return (name, pending.target.instanceName)
    }

    var body: some View {
        GroupBox("Volumes") {
            VStack(alignment: .leading, spacing: 10) {
                attachedVolumes
                if vm.consoleTarget(for: instance) != nil {
                    HStack {
                        Spacer()
                        Button("Attach Volume...") { vm.beginConfirmation(.attachVolume, for: instance) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(options == nil)
                            .help("Attach a free volume of this instance's network")
                    }
                }
            }
            .padding(8)
        }
        .task(id: instance.id) { await vm.loadVolumeOptions(for: instance) }
        .sheet(isPresented: Binding(
            get: { vm.pendingAction?.kind == .attachVolume && vm.pendingAction?.target.instanceId == instance.id },
            set: { if !$0 { vm.cancelConfirmation() } }
        )) {
            InstanceVolumeAttachSheet(instance: instance, vm: vm)
        }
        .alert(
            pendingDetach.map { Text("Detach \($0.volumeName) from \($0.instanceName)?") } ?? Text(verbatim: ""),
            isPresented: Binding(get: { pendingDetach != nil }, set: { if !$0 { vm.cancelConfirmation() } })
        ) {
            Button("Detach", role: .destructive) {
                guard let confirmed = vm.confirmDetach() else { return }
                Task { await vm.detachVolume(confirmed) }
            }
            Button("Cancel", role: .cancel) { vm.cancelConfirmation() }
        } message: {
            Text("Unmount the volume in the operating system of the instance first. Detaching a volume that is still mounted can lose data that was not yet written to it.")
        }
    }

    @ViewBuilder
    private var attachedVolumes: some View {
        if let message = vm.volumeOptionsError {
            HStack {
                Text(verbatim: message)
                    .font(.caption)
                    .foregroundStyle(.red)
                Spacer()
                Button("Retry") { Task { await vm.loadVolumeOptions(for: instance) } }
                    .controlSize(.small)
            }
        } else if let options {
            let attached = options.attached(to: instance)
            if attached.isEmpty {
                Text("No volume is attached to this instance.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(attached) { volume in
                    row(volume)
                }
            }
        } else {
            ProgressView()
                .controlSize(.small)
        }
    }

    private func row(_ volume: CivoVolume) -> some View {
        HStack {
            Image(systemName: "externaldrive")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: volume.name)
                    .font(.subheadline)
                HStack(spacing: 8) {
                    Text(verbatim: volume.sizeDisplay)
                    if let mountpoint = volume.mountpoint, !mountpoint.isEmpty {
                        Text(verbatim: mountpoint)
                            .monospaced()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if vm.consoleTarget(for: instance) != nil {
                Button("Detach...") {
                    vm.beginConfirmation(.detachVolume(id: volume.id, name: volume.name), for: instance)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Detach this volume from the instance")
            }
        }
    }
}

/// Lists the volumes that may be attached to the instance, opened with `beginConfirmation(.attachVolume, for:)`.
struct InstanceVolumeAttachSheet: View {
    let instance: CivoInstance
    let vm: InstanceViewModel
    @State private var selectedId: String?

    private var options: InstanceVolumeOptions? { vm.volumeOptions(for: instance) }
    private var offered: [CivoVolume] { options?.attachable(to: instance) ?? [] }
    private var selected: CivoVolume? { offered.first { $0.id == selectedId } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attach Volume")
                .font(.title2.bold())
            Text("Only volumes that are not attached and are in the network and region of this instance are listed.")
                .font(.caption)
                .foregroundStyle(.secondary)

            volumeList
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 260)

            Label("After attaching, mount the volume in the operating system of the instance. Format it only if it is new and empty, otherwise its data is lost.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") { vm.cancelConfirmation() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Attach") {
                    guard let volume = selected, let target = vm.confirmPendingAction() else { return }
                    Task { await vm.attachVolume(volume.id, to: target) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.volumeOptionsError != nil || selected == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .task { await vm.loadVolumeOptions(for: instance) }
    }

    @ViewBuilder
    private var volumeList: some View {
        if let message = vm.volumeOptionsError {
            VStack(spacing: 8) {
                Text(verbatim: message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Retry") { Task { await vm.loadVolumeOptions(for: instance) } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if options == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if offered.isEmpty {
            Text("No free volume was found in the network of this instance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(offered, selection: $selectedId) { volume in
                HStack {
                    Text(verbatim: volume.name)
                    Spacer()
                    Text(verbatim: volume.sizeDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
