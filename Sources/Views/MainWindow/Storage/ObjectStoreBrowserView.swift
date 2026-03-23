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
    @State private var isDownloading = false
    @State private var downloadProgress = ""
    @State private var error: String?
    @State private var pathHistory: [String] = [""]
    @State private var appeared = false

    // Download trigger: set key, view reacts
    @State private var downloadFileKey: String = ""
    @State private var downloadFolderPath: String = ""
    @State private var downloadCounter = 0

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbs
            Divider()
            fileList
            if isDownloading {
                Divider()
                downloadBar
            }
            if let error {
                Divider()
                ErrorBanner(message: error)
            }
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") {
                    navigateBack()
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
        .onChange(of: downloadCounter) { _, _ in
            if !downloadFileKey.isEmpty {
                let key = downloadFileKey
                downloadFileKey = ""
                handleFileDownload(key: key)
            } else if !downloadFolderPath.isEmpty {
                let folder = downloadFolderPath
                downloadFolderPath = ""
                handleFolderDownload(folder: folder)
            }
        }
    }

    // MARK: - Breadcrumbs

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

    // MARK: - File List

    private var fileList: some View {
        List {
            if isLoading && objects.isEmpty && folders.isEmpty {
                ProgressView("Loading...")
            } else if objects.isEmpty && folders.isEmpty && !isLoading {
                EmptyStateView(icon: "folder", title: "Empty", message: "No files or folders at this location.")
            } else {
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
                    .contextMenu {
                        Button("Download Folder") {
                            downloadFolderPath = folder
                            downloadCounter += 1
                        }
                    }
                    .modifier(StaggeredAppear(index: index))
                }

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
                            downloadFileKey = object.key
                            downloadCounter += 1
                        }
                    }
                    .modifier(StaggeredAppear(index: index + folders.count))
                }
            }
        }
    }

    // MARK: - Download Bar

    private var downloadBar: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(downloadProgress)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Navigation

    private func navigateBack() {
        if pathHistory.count > 1 {
            pathHistory.removeLast()
            currentPrefix = pathHistory.last ?? ""
            Task { await loadContents() }
        } else {
            onBack()
        }
    }

    // MARK: - Data Loading

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

    // MARK: - Download Handlers (called from .onChange, synchronous on main thread)

    private func handleFileDownload(key: String) {
        guard let object = objects.first(where: { $0.key == key }) else {
            error = "File not found: \(key)"
            return
        }

        let bucketName = store.name
        let client = s3Client
        let fileName = object.name

        isDownloading = true
        downloadProgress = "Downloading \(fileName)..."

        Task {
            do {
                let data = try await client.downloadObject(bucket: bucketName, key: object.key)

                await MainActor.run {
                    downloadProgress = "Download complete — choose save location..."
                    NSApp.activate(ignoringOtherApps: true)

                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = fileName
                    panel.canCreateDirectories = true

                    if panel.runModal() == .OK, let url = panel.url {
                        let accessed = url.startAccessingSecurityScopedResource()
                        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                        do {
                            try data.write(to: url)
                        } catch {
                            self.error = "Failed to save: \(error.localizedDescription)"
                        }
                    }

                    isDownloading = false
                    downloadProgress = ""
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isDownloading = false
                    downloadProgress = ""
                }
            }
        }
    }

    private func handleFolderDownload(folder: String) {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.title = "Choose download location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let targetDir = panel.url else { return }

        let bucketName = store.name
        let client = s3Client
        let prefix = currentPrefix

        isDownloading = true

        Task {
            let accessed = targetDir.startAccessingSecurityScopedResource()
            defer { if accessed { targetDir.stopAccessingSecurityScopedResource() } }

            do {
                await MainActor.run { downloadProgress = "Listing \(folderName(folder))..." }
                let allFiles = try await client.listAllObjects(bucket: bucketName, prefix: folder)

                for (index, file) in allFiles.enumerated() {
                    let relativePath = String(file.key.dropFirst(prefix.count))
                    await MainActor.run {
                        downloadProgress = "Downloading \(index + 1)/\(allFiles.count): \(relativePath)"
                    }

                    let data = try await client.downloadObject(bucket: bucketName, key: file.key)

                    let fileURL = targetDir.appendingPathComponent(relativePath)
                    let dir = fileURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    try data.write(to: fileURL)
                }

                await MainActor.run {
                    downloadProgress = "Done — \(allFiles.count) files downloaded"
                }
                try? await Task.sleep(for: .seconds(2))
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }

            await MainActor.run {
                isDownloading = false
                downloadProgress = ""
            }
        }
    }

    // MARK: - Helpers

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
