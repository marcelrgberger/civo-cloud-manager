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
    @State private var selection: Set<String> = []

    // Download triggers — UUID guarantees .onChange always fires
    @State private var downloadTrigger = UUID()
    @State private var downloadKeys: Set<String> = []
    @State private var downloadMode: DownloadMode = .single

    // Host window for sheet-based NSSavePanel
    @State private var hostWindow: NSWindow?

    private enum DownloadMode { case single, multi }

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbs
            Divider()
            fileList
            if isDownloading {
                Divider()
                downloadBar
            }
        }
        .background(WindowAccessor { hostWindow = $0 })
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") {
                    navigateBack()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    triggerDownload(keys: selection, mode: .multi)
                } label: {
                    Label(selection.isEmpty ? "Download" : "Download (\(selection.count))", systemImage: "arrow.down.circle")
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
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { appeared = true }
        }
        .onChange(of: downloadTrigger) { _, _ in
            let keys = downloadKeys
            let mode = downloadMode
            guard !keys.isEmpty else { return }

            Task { @MainActor in
                await Task.yield()
                handleDownload(keys: keys, mode: mode)
            }
        }
    }

    // MARK: - Breadcrumbs

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    navigateToRoot()
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

    // MARK: - File List

    private var fileList: some View {
        List(selection: $selection) {
            if isLoading && objects.isEmpty && folders.isEmpty {
                ProgressView("Loading...")
            } else if let error {
                ErrorBanner(message: error)
            } else if objects.isEmpty && folders.isEmpty {
                EmptyStateView(icon: "folder", title: "Empty", message: "No files or folders at this location.")
            } else {
                ForEach(folders, id: \.self) { folder in
                    folderRow(folder).tag(folder)
                }
                ForEach(objects) { object in
                    fileRow(object).tag(object.key)
                }
            }
        }
        .contextMenu(forSelectionType: String.self) { items in
            contextMenuContent(for: items)
        } primaryAction: { items in
            guard items.count == 1, let item = items.first else { return }
            if folders.contains(item) {
                navigateToFolder(item)
            } else {
                triggerDownload(keys: [item], mode: .single)
            }
        }
    }

    // MARK: - Rows

    private func folderRow(_ folder: String) -> some View {
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

    private func fileRow(_ object: S3Object) -> some View {
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
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuContent(for items: Set<String>) -> some View {
        if items.isEmpty {
            EmptyView()
        } else if items.count == 1, let item = items.first {
            if folders.contains(item) {
                Button {
                    navigateToFolder(item)
                } label: {
                    Label("Open", systemImage: "folder")
                }
                Divider()
                Button {
                    triggerDownload(keys: [item], mode: .multi)
                } label: {
                    Label("Download Folder", systemImage: "arrow.down.circle")
                }
            } else {
                Button {
                    triggerDownload(keys: [item], mode: .single)
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            }
        } else {
            Button {
                triggerDownload(keys: items, mode: .multi)
            } label: {
                Label("Download \(items.count) Items", systemImage: "arrow.down.circle")
            }
        }
    }

    // MARK: - Download Trigger

    private func triggerDownload(keys: Set<String>, mode: DownloadMode) {
        downloadKeys = keys
        downloadMode = mode
        downloadTrigger = UUID()
    }

    // MARK: - Download Handler (called after Task.yield lets menu dismiss)

    private func handleDownload(keys: Set<String>, mode: DownloadMode) {
        let selectedFolders = Array(keys.filter { folders.contains($0) })
        let selectedFiles = keys.compactMap { key in objects.first { $0.key == key } }

        if mode == .single && selectedFolders.isEmpty && selectedFiles.count == 1, let file = selectedFiles.first {
            presentSavePanelAndDownload(file)
        } else {
            presentFolderPickerAndDownload(selectedFolders: selectedFolders, selectedFiles: selectedFiles)
        }
    }

    private func presentSavePanelAndDownload(_ object: S3Object) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = object.name
        panel.canCreateDirectories = true

        let response: NSApplication.ModalResponse
        if let window = hostWindow ?? NSApp.keyWindow {
            panel.beginSheetModal(for: window) { sheetResponse in
                guard sheetResponse == .OK, let url = panel.url else { return }
                Task { await performSingleDownload(object, to: url) }
            }
            return
        } else {
            response = panel.runModal()
        }

        guard response == .OK, let url = panel.url else { return }
        Task { await performSingleDownload(object, to: url) }
    }

    private func performSingleDownload(_ object: S3Object, to url: URL) async {
        isDownloading = true
        downloadProgress = "Downloading \(object.name)..."
        do {
            let data = try await s3Client.downloadObject(bucket: store.name, key: object.key)
            try data.write(to: url)
        } catch {
            self.error = error.localizedDescription
        }
        isDownloading = false
        downloadProgress = ""
    }

    private func presentFolderPickerAndDownload(selectedFolders: [String], selectedFiles: [S3Object]) {
        let panel = NSOpenPanel()
        panel.title = "Choose download location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        let showPanel: (@escaping (URL) -> Void) -> Void = { completion in
            if let window = self.hostWindow ?? NSApp.keyWindow {
                panel.beginSheetModal(for: window) { response in
                    guard response == .OK, let url = panel.url else { return }
                    completion(url)
                }
            } else {
                guard panel.runModal() == .OK, let url = panel.url else { return }
                completion(url)
            }
        }

        showPanel { targetDir in
            Task {
                await performMultiDownload(
                    folders: selectedFolders,
                    files: selectedFiles,
                    to: targetDir
                )
            }
        }
    }

    private func performMultiDownload(folders selectedFolders: [String], files selectedFiles: [S3Object], to targetDir: URL) async {
        isDownloading = true
        defer {
            isDownloading = false
            downloadProgress = ""
        }

        do {
            var allFiles: [(key: String, relativeTo: String)] = []

            for folder in selectedFolders {
                downloadProgress = "Listing \(folderName(folder))..."
                let contents = try await s3Client.listAllObjects(bucket: store.name, prefix: folder)
                for obj in contents {
                    allFiles.append((key: obj.key, relativeTo: currentPrefix))
                }
            }

            for file in selectedFiles {
                allFiles.append((key: file.key, relativeTo: currentPrefix))
            }

            for (index, file) in allFiles.enumerated() {
                let relativePath = String(file.key.dropFirst(file.relativeTo.count))
                downloadProgress = "Downloading \(index + 1)/\(allFiles.count): \(relativePath)"

                let data = try await s3Client.downloadObject(bucket: store.name, key: file.key)

                let fileURL = targetDir.appendingPathComponent(relativePath)
                let dir = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                try data.write(to: fileURL)
            }

            downloadProgress = "Done — \(allFiles.count) files downloaded"
            try? await Task.sleep(for: .seconds(2))
        } catch {
            self.error = error.localizedDescription
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

    private func navigateToFolder(_ folder: String) {
        currentPrefix = folder
        pathHistory.append(folder)
        selection.removeAll()
        Task { await loadContents() }
    }

    private func navigateToRoot() {
        currentPrefix = ""
        pathHistory = [""]
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
            objects = result.objects
            folders = result.commonPrefixes
        } catch {
            self.error = error.localizedDescription
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

// MARK: - Window Accessor (needed for beginSheetModal)

private struct WindowAccessor: NSViewRepresentable {
    let onResolve: @MainActor (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
    }
}
