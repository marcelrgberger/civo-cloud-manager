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
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Key pair generated and shown in Finder")
                                .font(.caption.bold())
                        }

                        Text("Move the private key to ~/.ssh/ on your Mac:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("mv ~/path/to/\(name.replacingOccurrences(of: " ", with: "-").lowercased()) ~/.ssh/")
                                    .font(.caption2.monospaced())
                                Text("chmod 600 ~/.ssh/\(name.replacingOccurrences(of: " ", with: "-").lowercased())")
                                    .font(.caption2.monospaced())
                            }
                            .textSelection(.enabled)
                            .padding(4)
                        }

                        Text("The public key will be uploaded to Civo when you click Create.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Generates an Ed25519 key pair. The private key opens in Finder for you to move to ~/.ssh/. The public key is uploaded to Civo.")
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

    private func generateKey() {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "-").lowercased()

        // Use temp directory (sandbox-safe), then reveal in Finder
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ssh-keys")
        let privateKeyPath = tempDir.appendingPathComponent(sanitizedName)
        let publicKeyPath = tempDir.appendingPathComponent("\(sanitizedName).pub")

        isGenerating = true

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Remove existing temp key if any
        try? FileManager.default.removeItem(at: privateKeyPath)
        try? FileManager.default.removeItem(at: publicKeyPath)

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
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: privateKeyPath.path
                )

                let pubKey = try String(contentsOf: publicKeyPath, encoding: .utf8)
                publicKey = pubKey.trimmingCharacters(in: .whitespacesAndNewlines)
                generatedPrivateKeyPath = privateKeyPath.path

                // Reveal private key in Finder so user can move to ~/.ssh/
                NSWorkspace.shared.activateFileViewerSelecting([privateKeyPath, publicKeyPath])
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
