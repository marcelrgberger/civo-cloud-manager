import SwiftUI

// MARK: - Browser Item

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

    var iconColor: Color { isFolder ? .blue : .secondary }
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
    @State private var downloadTask: Task<Void, Never>?

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
                errorBar(error)
            }
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { navigateBack() }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    downloadTask = Task { await download(selection: selection) }
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
                    Label(store.name, systemImage: "tray.2").font(.caption.weight(.medium))
                }
                .buttonStyle(.borderless)

                let parts = currentPrefix.components(separatedBy: "/").filter { !$0.isEmpty }
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
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
                    Text(item.name).lineLimit(1)
                }
            }
            .width(min: 200)

            TableColumn("Size") { item in
                Text(item.sizeDisplay).foregroundStyle(.secondary).font(.callout)
            }
            .width(60)
        }
        .contextMenu(forSelectionType: String.self) { selected in
            if !selected.isEmpty {
                Button("Download \(selected.count == 1 ? "Item" : "\(selected.count) Items")") {
                    downloadTask = Task { await download(selection: selected) }
                }
            }
        } primaryAction: { selected in
            guard selected.count == 1, let id = selected.first,
                  let item = items.first(where: { $0.id == id }) else { return }
            if item.isFolder {
                navigateToFolder(item.key)
            } else {
                downloadTask = Task { await download(selection: selected) }
            }
        }
        .tableStyle(.bordered(alternatesRowBackgrounds: true))
    }

    // MARK: - Status Bars

    private var downloadBar: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(downloadProgress).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button {
                downloadTask?.cancel()
                downloadTask = nil
                isDownloading = false
                downloadProgress = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Cancel download")
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
    }

    private func errorBar(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.caption).foregroundStyle(.red)
            Spacer()
            Button("Dismiss") { error = nil }.buttonStyle(.borderless).font(.caption)
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
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
                browserItems.append(BrowserItem(id: prefix, name: folderName(prefix), isFolder: true, size: 0, key: prefix))
            }
            for obj in result.objects {
                browserItems.append(BrowserItem(id: obj.key, name: obj.name, isFolder: false, size: obj.size, key: obj.key))
            }
            items = browserItems
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Download (saves to temp, opens Finder)

    private func download(selection ids: Set<String>) async {
        let selectedItems = ids.compactMap { id in items.first { $0.id == id } }
        guard !selectedItems.isEmpty else { return }

        isDownloading = true
        error = nil

        do {
            // Collect all file keys (expand folders recursively)
            var fileKeys: [String] = []
            for item in selectedItems {
                if item.isFolder {
                    downloadProgress = "Listing \(item.name)..."
                    let contents = try await s3Client.listAllObjects(bucket: store.name, prefix: item.key)
                    fileKeys.append(contentsOf: contents.map(\.key))
                } else {
                    fileKeys.append(item.key)
                }
            }

            guard !fileKeys.isEmpty else {
                error = "No files found"
                isDownloading = false
                downloadProgress = ""
                return
            }

            // Create download directory in ~/Downloads
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let downloadDir = downloadsURL
                .appendingPathComponent("CivoDownload-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)

            // Download all files
            var savedURLs: [URL] = []
            for (index, key) in fileKeys.enumerated() {
                try Task.checkCancellation()

                let relativePath = String(key.dropFirst(currentPrefix.count))
                downloadProgress = "Downloading \(index + 1)/\(fileKeys.count): \(relativePath)"

                let data = try await s3Client.downloadObject(bucket: store.name, key: key)

                let fileURL = downloadDir.appendingPathComponent(relativePath)
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: fileURL)
                savedURLs.append(fileURL)
            }

            downloadProgress = "Done — \(fileKeys.count) files downloaded"

            // Open in Finder
            NSWorkspace.shared.activateFileViewerSelecting(savedURLs)

            try? await Task.sleep(for: .seconds(2))
            isDownloading = false
            downloadProgress = ""
        } catch is CancellationError {
            isDownloading = false
            downloadProgress = ""
        } catch {
            self.error = error.localizedDescription
            isDownloading = false
            downloadProgress = ""
        }
    }

    // MARK: - Helpers

    private func folderName(_ prefix: String) -> String {
        let trimmed = prefix.hasSuffix("/") ? String(prefix.dropLast()) : prefix
        return trimmed.components(separatedBy: "/").last ?? prefix
    }
}
