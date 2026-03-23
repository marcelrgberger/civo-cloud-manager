import SwiftUI
import AppKit

// MARK: - Browser Item (unified model for Table)

struct BrowserItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let isFolder: Bool
    let size: Int
    let key: String

    var sizeDisplay: String {
        if isFolder { return "—" }
        if size < 1024 { return "\(size) B" }
        if size < 1024 * 1024 { return "\(size / 1024) KB" }
        if size < 1024 * 1024 * 1024 { return "\(size / (1024 * 1024)) MB" }
        return String(format: "%.1f GB", Double(size) / (1024 * 1024 * 1024))
    }

    var icon: String {
        if isFolder { return "folder.fill" }
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

    var iconColor: Color {
        isFolder ? .blue : .secondary
    }
}

// MARK: - Browser View

struct ObjectStoreBrowserView: View {
    let store: CivoObjectStore
    let s3Client: S3Client
    let onBack: () -> Void

    @State private var currentPrefix = ""
    @State private var items: [BrowserItem] = []
    @State private var isLoading = false
    @State private var isDownloading = false
    @State private var downloadProgress = ""
    @State private var error: String?
    @State private var pathHistory: [String] = [""]
    @State private var selection: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbs
            Divider()
            browserTable
            if isDownloading {
                Divider()
                downloadBar
            }
            if let error {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Dismiss") { self.error = nil }
                        .buttonStyle(.borderless)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
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
                    startDownloadSelected()
                } label: {
                    Label(
                        selection.isEmpty ? "Download" : "Download (\(selection.count))",
                        systemImage: "arrow.down.circle"
                    )
                }
                .disabled(selection.isEmpty || isDownloading)
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
    }

    // MARK: - Breadcrumbs

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    currentPrefix = ""
                    pathHistory = [""]
                    selection.removeAll()
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
                        selection.removeAll()
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

    // MARK: - Table

    private var browserTable: some View {
        Table(items, selection: $selection) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(systemName: item.icon)
                        .foregroundStyle(item.iconColor)
                        .frame(width: 20)
                    Text(item.name)
                        .lineLimit(1)
                }
            }
            .width(min: 200)

            TableColumn("Size") { item in
                Text(item.sizeDisplay)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .width(60)
        }
        .contextMenu(forSelectionType: String.self) { selected in
            if !selected.isEmpty {
                let folders = selected.filter { id in items.first { $0.id == id }?.isFolder == true }
                let files = selected.filter { id in items.first { $0.id == id }?.isFolder == false }

                if folders.count == 1, files.isEmpty, let folderId = folders.first {
                    Button("Open Folder") { navigateToFolder(folderId) }
                    Divider()
                }

                Button("Download \(selected.count == 1 ? "Item" : "\(selected.count) Items")") {
                    selection = selected
                    startDownloadSelected()
                }
            }
        } primaryAction: { selected in
            guard selected.count == 1, let id = selected.first,
                  let item = items.first(where: { $0.id == id }) else { return }
            if item.isFolder {
                navigateToFolder(item.key)
            } else {
                startSingleDownload(item)
            }
        }
        .tableStyle(.bordered(alternatesRowBackgrounds: true))
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

    private func navigateToFolder(_ key: String) {
        currentPrefix = key
        pathHistory.append(key)
        selection.removeAll()
        Task { await loadContents() }
    }

    private func navigateBack() {
        if pathHistory.count > 1 {
            pathHistory.removeLast()
            currentPrefix = pathHistory.last ?? ""
            selection.removeAll()
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

            var browserItems: [BrowserItem] = []
            for prefix in result.commonPrefixes {
                let name = folderName(prefix)
                browserItems.append(BrowserItem(id: prefix, name: name, isFolder: true, size: 0, key: prefix))
            }
            for obj in result.objects {
                browserItems.append(BrowserItem(id: obj.key, name: obj.name, isFolder: false, size: obj.size, key: obj.key))
            }
            items = browserItems
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Download

    private func startSingleDownload(_ item: BrowserItem) {
        let bucketName = store.name
        let client = s3Client
        let fileName = item.name
        let fileKey = item.key

        isDownloading = true
        downloadProgress = "Downloading \(fileName)..."

        Task {
            do {
                let data = try await client.downloadObject(bucket: bucketName, key: fileKey)

                // Save to temp file first, then show panel via DispatchQueue
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
                try data.write(to: tempURL)

                DispatchQueue.main.async { [self] in
                    downloadProgress = "Download complete — choose save location..."
                    NSApp.activate(ignoringOtherApps: true)

                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = fileName
                    panel.canCreateDirectories = true

                    if panel.runModal() == .OK, let url = panel.url {
                        let accessed = url.startAccessingSecurityScopedResource()
                        do {
                            if FileManager.default.fileExists(atPath: url.path) {
                                try FileManager.default.removeItem(at: url)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: url)
                        } catch {
                            self.error = "Save failed: \(error.localizedDescription)"
                        }
                        if accessed { url.stopAccessingSecurityScopedResource() }
                    } else {
                        try? FileManager.default.removeItem(at: tempURL)
                    }

                    isDownloading = false
                    downloadProgress = ""
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    self.error = error.localizedDescription
                    isDownloading = false
                    downloadProgress = ""
                }
            }
        }
    }

    private func startFolderDownload(_ item: BrowserItem) {
        let bucketName = store.name
        let client = s3Client
        let folderKey = item.key
        let prefix = currentPrefix

        isDownloading = true
        downloadProgress = "Listing folder contents..."

        Task {
            do {
                let allFiles = try await client.listAllObjects(bucket: bucketName, prefix: folderKey)

                DispatchQueue.main.async { [self] in
                    downloadProgress = "Found \(allFiles.count) files — choose save location..."
                    NSApp.activate(ignoringOtherApps: true)

                    let panel = NSOpenPanel()
                    panel.title = "Choose download location"
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    panel.allowsMultipleSelection = false

                    guard panel.runModal() == .OK, let targetDir = panel.url else {
                        isDownloading = false
                        downloadProgress = ""
                        return
                    }

                    Task {
                        let accessed = targetDir.startAccessingSecurityScopedResource()
                        defer { if accessed { targetDir.stopAccessingSecurityScopedResource() } }

                        do {
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
                                downloadProgress = "Done — \(allFiles.count) files saved"
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
            } catch {
                DispatchQueue.main.async { [self] in
                    self.error = error.localizedDescription
                    isDownloading = false
                    downloadProgress = ""
                }
            }
        }
    }

    private func startDownloadSelected() {
        let selectedItems = selection.compactMap { id in items.first { $0.id == id } }

        if selectedItems.count == 1, let item = selectedItems.first, !item.isFolder {
            startSingleDownload(item)
            return
        }

        // Multiple items or folders: collect all files, then pick target dir
        let bucketName = store.name
        let client = s3Client
        let prefix = currentPrefix
        let selectedFolders = selectedItems.filter(\.isFolder).map(\.key)
        let selectedFileKeys = selectedItems.filter { !$0.isFolder }.map(\.key)

        isDownloading = true
        downloadProgress = "Preparing download..."

        Task {
            do {
                var allFiles: [(key: String, relativeTo: String)] = []

                for folderKey in selectedFolders {
                    await MainActor.run { downloadProgress = "Listing folder contents..." }
                    let contents = try await client.listAllObjects(bucket: bucketName, prefix: folderKey)
                    for obj in contents {
                        allFiles.append((key: obj.key, relativeTo: prefix))
                    }
                }

                for fileKey in selectedFileKeys {
                    allFiles.append((key: fileKey, relativeTo: prefix))
                }

                DispatchQueue.main.async { [self] in
                    downloadProgress = "\(allFiles.count) files ready — choose save location..."
                    NSApp.activate(ignoringOtherApps: true)

                    let panel = NSOpenPanel()
                    panel.title = "Choose download location"
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    panel.allowsMultipleSelection = false

                    guard panel.runModal() == .OK, let targetDir = panel.url else {
                        isDownloading = false
                        downloadProgress = ""
                        return
                    }

                    Task {
                        let accessed = targetDir.startAccessingSecurityScopedResource()
                        defer { if accessed { targetDir.stopAccessingSecurityScopedResource() } }

                        do {
                            for (index, file) in allFiles.enumerated() {
                                let relativePath = String(file.key.dropFirst(file.relativeTo.count))
                                await MainActor.run {
                                    downloadProgress = "Downloading \(index + 1)/\(allFiles.count): \(relativePath)"
                                }
                                let data = try await client.downloadObject(bucket: bucketName, key: file.key)
                                let fileURL = targetDir.appendingPathComponent(relativePath)
                                let dir = fileURL.deletingLastPathComponent()
                                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                                try data.write(to: fileURL)
                            }
                            await MainActor.run { downloadProgress = "Done — \(allFiles.count) files saved" }
                            try? await Task.sleep(for: .seconds(2))
                        } catch {
                            await MainActor.run { self.error = error.localizedDescription }
                        }

                        await MainActor.run {
                            isDownloading = false
                            downloadProgress = ""
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    self.error = error.localizedDescription
                    isDownloading = false
                    downloadProgress = ""
                }
            }
        }
    }

    // MARK: - Helpers

    private func folderName(_ prefix: String) -> String {
        let trimmed = prefix.hasSuffix("/") ? String(prefix.dropLast()) : prefix
        return trimmed.components(separatedBy: "/").last ?? prefix
    }
}
