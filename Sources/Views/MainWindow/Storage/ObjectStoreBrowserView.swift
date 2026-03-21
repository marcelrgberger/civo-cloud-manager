import SwiftUI
import AppKit

struct ObjectStoreBrowserView: View {
    let store: CivoObjectStore
    let s3Client: S3Client
    let onBack: () -> Void

    @State private var currentPrefix = ""
    @State private var objects: [S3Object] = []
    @State private var folders: [String] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var pathHistory: [String] = [""]
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbs
            Divider()
            fileList
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") {
                    if pathHistory.count > 1 {
                        pathHistory.removeLast()
                        currentPrefix = pathHistory.last ?? ""
                        Task { await loadContents() }
                    } else {
                        onBack()
                    }
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await loadContents() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task { await loadContents() }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
    }

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    currentPrefix = ""
                    pathHistory = [""]
                    Task { await loadContents() }
                } label: {
                    Label(store.name, systemImage: "tray.2")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderless)

                let parts = currentPrefix.components(separatedBy: "/").filter { !$0.isEmpty }
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Button(part) {
                        let newPrefix = parts[0...index].joined(separator: "/") + "/"
                        currentPrefix = newPrefix
                        pathHistory = [""] + (0...index).map { parts[0...$0].joined(separator: "/") + "/" }
                        Task { await loadContents() }
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.quaternary.opacity(0.3))
    }

    private var fileList: some View {
        List {
            if isLoading && objects.isEmpty && folders.isEmpty {
                ProgressView("Loading...")
            } else if let error {
                ErrorBanner(message: error)
            } else if objects.isEmpty && folders.isEmpty {
                EmptyStateView(icon: "folder", title: "Empty", message: "No files or folders at this location.")
            } else {
                // Folders
                ForEach(Array(folders.enumerated()), id: \.element) { index, folder in
                    Button {
                        currentPrefix = folder
                        pathHistory.append(folder)
                        Task { await loadContents() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            Text(folderName(folder))
                                .font(.body.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .modifier(StaggeredAppear(index: index))
                }

                // Files
                ForEach(Array(objects.enumerated()), id: \.element.id) { index, object in
                    HStack(spacing: 10) {
                        Image(systemName: fileIcon(object.name))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(object.name)
                                .font(.body.weight(.medium))
                            Text(object.sizeDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("Download") {
                            Task { await downloadFile(object) }
                        }
                    }
                    .modifier(StaggeredAppear(index: index + folders.count))
                }
            }
        }
    }

    private func loadContents() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await s3Client.listObjects(bucket: store.name, prefix: currentPrefix)
            objects = result.objects
            folders = result.commonPrefixes
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func downloadFile(_ object: S3Object) async {
        do {
            let data = try await s3Client.downloadObject(bucket: store.name, key: object.key)

            await MainActor.run {
                let panel = NSSavePanel()
                panel.nameFieldStringValue = object.name
                panel.canCreateDirectories = true

                if panel.runModal() == .OK, let url = panel.url {
                    try? data.write(to: url)
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func folderName(_ prefix: String) -> String {
        let trimmed = prefix.hasSuffix("/") ? String(prefix.dropLast()) : prefix
        return trimmed.components(separatedBy: "/").last ?? prefix
    }

    private func fileIcon(_ name: String) -> String {
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "svg": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "bz2", "xz": return "archivebox"
        case "json", "xml", "yaml", "yml", "toml": return "doc.text"
        case "sql", "db", "sqlite": return "cylinder"
        case "log", "txt", "md": return "doc.plaintext"
        case "mp4", "mov", "avi": return "film"
        case "mp3", "wav", "aac": return "music.note"
        default: return "doc"
        }
    }
}
