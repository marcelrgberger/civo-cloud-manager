import SwiftUI

struct CreateSSHKeyView: View {
    @Bindable var vm: InstanceViewModel
    @State private var name = ""
    @State private var publicKey = ""
    @State private var isGenerating = false
    @State private var generatedPrivateKeyPath: String?

    var body: some View {
        Form {
            Section("SSH Key Details") {
                TextField("Name", text: $name)
                    .onChange(of: name) { _, _ in
                        // Clear generated key if name changes
                        generatedPrivateKeyPath = nil
                    }

                TextEditor(text: $publicKey)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if publicKey.isEmpty {
                            Text("Paste your public key or click Generate")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                HStack {
                    Button {
                        generateKey()
                    } label: {
                        Label("Generate SSH Key", systemImage: "key.fill")
                    }
                    .disabled(name.isEmpty || isGenerating)

                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if generatedPrivateKeyPath != nil {
                    let keyName = name.replacingOccurrences(of: " ", with: "-").lowercased()
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Key pair saved to Downloads and shown in Finder")
                                .font(.caption.bold())
                        }

                        let command = "mv ~/Downloads/\(keyName) ~/.ssh/\(keyName) && chmod 600 ~/.ssh/\(keyName)"

                        Text("Move it to your SSH directory:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            GroupBox {
                                Text(command)
                                    .font(.caption2.monospaced())
                                    .textSelection(.enabled)
                                    .padding(2)
                            }
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(command, forType: .string)
                                openTerminalWithCommand(command)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .help("Copy and open Terminal")
                            }
                            .buttonStyle(.borderless)
                        }

                        Text("Click Create to upload the public key to Civo.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Generates an Ed25519 key pair. Private key is saved to Downloads, public key is uploaded to Civo.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let error = vm.saveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add SSH Key")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isCreatingSSHKey = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        _ = await vm.createSSHKey([
                            "name": name,
                            "public_key": publicKey,
                        ])
                    }
                }
                .disabled(name.isEmpty || publicKey.isEmpty || vm.isSaving)
            }
        }
    }

    private func openTerminalWithCommand(_ command: String) {
        let script = "tell application \"Terminal\"\nactivate\ndo script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\"\nend tell"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    private func generateKey() {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "-").lowercased()

        // Generate in temp, then move private key to Downloads
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ssh-gen-\(UUID().uuidString)")
        let privateKeyPath = tempDir.appendingPathComponent(sanitizedName)
        let publicKeyPath = tempDir.appendingPathComponent("\(sanitizedName).pub")

        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            vm.saveError = "Could not access Downloads folder"
            return
        }
        let downloadedKeyPath = downloadsDir.appendingPathComponent(sanitizedName)

        isGenerating = true

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.arguments = [
            "-t", "ed25519",
            "-f", privateKeyPath.path,
            "-N", "",
            "-C", "\(name) (Civo Cloud Manager)",
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Read public key (stays in memory, uploaded to Civo)
                let pubKey = try String(contentsOf: publicKeyPath, encoding: .utf8)
                publicKey = pubKey.trimmingCharacters(in: .whitespacesAndNewlines)

                // Move private key to Downloads
                try? FileManager.default.removeItem(at: downloadedKeyPath)
                try FileManager.default.moveItem(at: privateKeyPath, to: downloadedKeyPath)
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: downloadedKeyPath.path
                )
                generatedPrivateKeyPath = downloadedKeyPath.path

                // Clean up temp (public key not needed as file)
                try? FileManager.default.removeItem(at: tempDir)

                // Show in Finder
                NSWorkspace.shared.activateFileViewerSelecting([downloadedKeyPath])
            } else {
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                vm.saveError = "ssh-keygen failed: \(output)"
            }
        } catch {
            vm.saveError = "Failed to run ssh-keygen: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
