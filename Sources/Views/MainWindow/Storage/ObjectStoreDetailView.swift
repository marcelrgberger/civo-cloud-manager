import SwiftUI

struct ObjectStoreDetailView: View {
    let store: CivoObjectStore
    @Bindable var vm: VolumeViewModel
    let onBack: () -> Void
    @State private var appeared = false
    @State private var newSize: Int
    @State private var isResizing = false

    init(store: CivoObjectStore, vm: VolumeViewModel, onBack: @escaping () -> Void) {
        self.store = store
        self.vm = vm
        self.onBack = onBack
        _newSize = State(initialValue: store.maxSize ?? 500)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                credentialsSection
                configSection
                resizeSection
            }
            .padding(24)
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.largeTitle.bold())
                Text(store.maxSizeDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: store.status ?? "Unknown")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    private var credentialsSection: some View {
        GroupBox("Credentials") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow("Endpoint", store.objectstoreEndpoint ?? "—")
                if let url = store.bucketURL {
                    infoRow("Bucket URL", url)
                }
                infoRow("Access Key ID", store.accessKeyId ?? "—")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Secret Access Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.secretAccessKey ?? "—")
                        .font(.subheadline.monospaced())
                        .textSelection(.enabled)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    private var configSection: some View {
        GroupBox("Details") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow("Max Size", store.maxSizeDisplay)
                infoRow("Region", store.region ?? "—")
                infoRow("Created", store.createdAt ?? "—")
                infoRow("Status", store.status ?? "—")
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private var resizeSection: some View {
        GroupBox("Resize") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Change the maximum storage size for this object store.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper("New Size: \(newSize) GB", value: $newSize, in: 250...100000, step: 250)

                if newSize != (store.maxSize ?? 500) {
                    Button {
                        isResizing = true
                        Task {
                            let success = await vm.updateObjectStoreSize(store.id, newSize: newSize)
                            isResizing = false
                            if success { onBack() }
                        }
                    } label: {
                        HStack {
                            if isResizing {
                                ProgressView().controlSize(.small)
                            }
                            Text("Apply: \(store.maxSize ?? 0) GB → \(newSize) GB")
                        }
                    }
                    .disabled(isResizing)
                }

                if let error = vm.saveError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(8)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospaced())
                .textSelection(.enabled)
        }
    }
}
