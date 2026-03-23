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

                if let path = generatedPrivateKeyPath {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Private key saved to:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(path)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Text("Generates an Ed25519 key pair. The private key is saved to ~/.ssh/ and the public key is uploaded to Civo.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
        let sshDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        let privateKeyPath = sshDir.appendingPathComponent(sanitizedName)
        let publicKeyPath = sshDir.appendingPathComponent("\(sanitizedName).pub")

        // Don't overwrite existing keys
        if FileManager.default.fileExists(atPath: privateKeyPath.path) {
            // Key exists — read the public key
            if let pubKey = try? String(contentsOf: publicKeyPath, encoding: .utf8) {
                publicKey = pubKey.trimmingCharacters(in: .whitespacesAndNewlines)
                generatedPrivateKeyPath = privateKeyPath.path
            } else {
                vm.saveError = "Key \(sanitizedName) already exists but public key not found"
            }
            return
        }

        isGenerating = true

        // Create .ssh directory if needed
        try? FileManager.default.createDirectory(at: sshDir, withIntermediateDirectories: true)

        // Run ssh-keygen
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.arguments = [
            "-t", "ed25519",
            "-f", privateKeyPath.path,
            "-N", "",  // No passphrase
            "-C", "\(name) (Civo Cloud Manager)",
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Set correct permissions
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: privateKeyPath.path
                )

                // Read public key
                let pubKey = try String(contentsOf: publicKeyPath, encoding: .utf8)
                publicKey = pubKey.trimmingCharacters(in: .whitespacesAndNewlines)
                generatedPrivateKeyPath = privateKeyPath.path
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
