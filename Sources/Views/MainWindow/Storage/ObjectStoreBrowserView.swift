import SwiftUI
import UniformTypeIdentifiers

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

// MARK: - File Document for .fileExporter

struct S3DownloadedFile: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
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

    // Single file export via SwiftUI .fileExporter
    @State private var exportDocument: S3DownloadedFile?
    @State private var exportFileName = ""
    @State private var showExporter = false

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
                    startDownload()
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
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .data,
            defaultFilename: exportFileName
        ) { result in
            exportDocument = nil
            if case .failure(let err) = result {
                error = err.localizedDescription
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
                Button("Download \(selected.count == 1 ? "Item" : "\(selected.count) Items")") {
                    selection = selected
                    startDownload()
                }
            }
        } primaryAction: { selected in
            guard selected.count == 1, let id = selected.first,
                  let item = items.first(where: { $0.id == id }) else { return }
            if item.isFolder {
                navigateToFolder(item.key)
            } else {
                selection = selected
                startDownload()
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

    // MARK: - Download

    private func startDownload() {
        let selectedItems = selection.compactMap { id in items.first { $0.id == id } }
        guard !selectedItems.isEmpty else { return }

        // Single file: download and show native SwiftUI file exporter
        if selectedItems.count == 1, let item = selectedItems.first, !item.isFolder {
            downloadSingleFile(item)
            return
        }

        // Multiple items or folders: download all to temp, then zip or reveal
        downloadMultiple(selectedItems)
    }

    private func downloadSingleFile(_ item: BrowserItem) {
        isDownloading = true
        downloadProgress = "Downloading \(item.name)..."

        Task {
            do {
                let data = try await s3Client.downloadObject(bucket: store.name, key: item.key)
                exportDocument = S3DownloadedFile(data: data)
                exportFileName = item.name
                isDownloading = false
                downloadProgress = ""
                showExporter = true
            } catch {
                self.error = error.localizedDescription
                isDownloading = false
                downloadProgress = ""
            }
        }
    }

    private func downloadMultiple(_ selectedItems: [BrowserItem]) {
        let folders = selectedItems.filter(\.isFolder).map(\.key)
        let files = selectedItems.filter { !$0.isFolder }.map(\.key)
        let bucketName = store.name
        let client = s3Client
        let prefix = currentPrefix

        isDownloading = true
        downloadProgress = "Preparing..."

        Task {
            do {
                // Collect all file keys
                var allKeys: [String] = []

                for folderKey in folders {
                    downloadProgress = "Listing folder contents..."
                    let contents = try await client.listAllObjects(bucket: bucketName, prefix: folderKey)
                    allKeys.append(contentsOf: contents.map(\.key))
                }
                allKeys.append(contentsOf: files)

                // Download all to temp directory
                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("s3-download-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                for (index, key) in allKeys.enumerated() {
                    let relativePath = String(key.dropFirst(prefix.count))
                    downloadProgress = "Downloading \(index + 1)/\(allKeys.count): \(relativePath)"

                    let data = try await client.downloadObject(bucket: bucketName, key: key)

                    let fileURL = tempDir.appendingPathComponent(relativePath)
                    try FileManager.default.createDirectory(
                        at: fileURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try data.write(to: fileURL)
                }

                // Reveal in Finder
                downloadProgress = "Done — \(allKeys.count) files downloaded"
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: tempDir.path)

                try? await Task.sleep(for: .seconds(2))
                isDownloading = false
                downloadProgress = ""
            } catch {
                self.error = error.localizedDescription
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
}
