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
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") {
                    navigateBack()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await downloadSelection() }
                } label: {
                    Label(selection.isEmpty ? "Download" : "Download (\(selection.count))", systemImage: "arrow.down.circle")
                }
                .disabled(selection.isEmpty || isDownloading)
                .help("Download selected files and folders")
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
                    folderRow(folder)
                        .tag(folder)
                }
                ForEach(objects) { object in
                    fileRow(object)
                        .tag(object.key)
                }
            }
        }
        .contextMenu(forSelectionType: String.self) { items in
            contextMenuItems(for: items)
        } primaryAction: { items in
            handleDoubleClick(items)
        }
    }

    // MARK: - Rows (plain views, no buttons or nested context menus)

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

    // MARK: - Context Menu (single, on List level)

    @ViewBuilder
    private func contextMenuItems(for items: Set<String>) -> some View {
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
                    selection = [item]
                    Task { await downloadSelection() }
                } label: {
                    Label("Download Folder", systemImage: "arrow.down.circle")
                }
            } else {
                Button {
                    if let obj = objects.first(where: { $0.key == item }) {
                        Task { await downloadSingleFile(obj) }
                    }
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            }
        } else {
            Button {
                selection = items
                Task { await downloadSelection() }
            } label: {
                Label("Download \(items.count) Items", systemImage: "arrow.down.circle")
            }
        }
    }

    // MARK: - Double-Click (primaryAction)

    private func handleDoubleClick(_ items: Set<String>) {
        guard items.count == 1, let item = items.first else { return }
        if folders.contains(item) {
            navigateToFolder(item)
        } else if let obj = objects.first(where: { $0.key == item }) {
            Task { await downloadSingleFile(obj) }
        }
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

    // MARK: - Download

    private func downloadSelection() async {
        let selectedFolders = selection.filter { folders.contains($0) }
        let selectedFiles = selection.compactMap { key in objects.first { $0.key == key } }

        if selectedFolders.isEmpty && selectedFiles.count == 1, let file = selectedFiles.first {
            await downloadSingleFile(file)
            return
        }

        guard let targetDir = pickFolder() else { return }

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

    private func downloadSingleFile(_ object: S3Object) async {
        do {
            let url = await MainActor.run { () -> URL? in
                let panel = NSSavePanel()
                panel.nameFieldStringValue = object.name
                panel.canCreateDirectories = true
                return panel.runModal() == .OK ? panel.url : nil
            }
            guard let url else { return }

            isDownloading = true
            downloadProgress = "Downloading \(object.name)..."
            let data = try await s3Client.downloadObject(bucket: store.name, key: object.key)
            try data.write(to: url)
            isDownloading = false
            downloadProgress = ""
        } catch {
            isDownloading = false
            downloadProgress = ""
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose download location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        return panel.runModal() == .OK ? panel.url : nil
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
