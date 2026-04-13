import CryptoKit
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
                        .replacing(Self.safeNamePattern, with: { _ in "" })
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

                        GroupBox {
                            Text(command)
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                                .padding(2)
                        }

                        Button {
                            copyAndOpenTerminal(command)
                        } label: {
                            Label(copiedToClipboard ? "Copied — paste in Terminal (⌘V + Enter)" : "Copy & Open Terminal", systemImage: copiedToClipboard ? "checkmark.circle.fill" : "terminal")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(copiedToClipboard ? .green : nil)

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

    @State private var copiedToClipboard = false

    private func copyAndOpenTerminal(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        copiedToClipboard = true
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
    }

    private static let safeNamePattern = try! Regex("[^A-Za-z0-9._-]")

    private func generateKey() {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "-").lowercased()
            .replacing(Self.safeNamePattern, with: { _ in "" })

        guard !sanitizedName.isEmpty else {
            vm.saveError = "Name must contain at least one letter or number"
            return
        }

        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            vm.saveError = "Could not access Downloads folder"
            return
        }
        let downloadedKeyPath = downloadsDir.appendingPathComponent(sanitizedName)

        if FileManager.default.fileExists(atPath: downloadedKeyPath.path) {
            vm.saveError = "File '\(sanitizedName)' already exists in Downloads. Rename the key or move the existing file."
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            // Generate Ed25519 key pair using CryptoKit
            let privateKey = Curve25519.Signing.PrivateKey()
            let pubKeyBytes = privateKey.publicKey.rawRepresentation
            let comment = "\(name) (Civo Cloud Manager)"

            // Format public key as OpenSSH: ssh-ed25519 <base64> <comment>
            let keyType = "ssh-ed25519"
            var pubBlob = Data()
            pubBlob.appendSSHString(keyType)
            pubBlob.appendSSHBytes(pubKeyBytes)
            publicKey = "\(keyType) \(pubBlob.base64EncodedString()) \(comment)"

            // Format private key in OpenSSH format
            let privateKeyData = formatOpenSSHPrivateKey(
                privateKey: privateKey,
                publicKeyBytes: pubKeyBytes,
                comment: comment
            )

            // Backup private key (encrypted in app storage)
            let saved = SSHKeychain.save(name: sanitizedName, privateKey: privateKeyData)
            Log.info("SSH key backup \(saved ? "OK" : "FAILED") for '\(sanitizedName)'")

            // Save private key to Downloads
            try privateKeyData.write(to: downloadedKeyPath)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: downloadedKeyPath.path
            )
            generatedPrivateKeyPath = downloadedKeyPath.path

            // Show in Finder
            NSWorkspace.shared.activateFileViewerSelecting([downloadedKeyPath])
        } catch {
            vm.saveError = "Key generation failed: \(error.localizedDescription)"
        }
    }

    /// Formats an Ed25519 private key in OpenSSH format (openssh-key-v1).
    private func formatOpenSSHPrivateKey(
        privateKey: Curve25519.Signing.PrivateKey,
        publicKeyBytes: Data,
        comment: String
    ) -> Data {
        let keyType = "ssh-ed25519"

        // Public key blob (same as in authorized_keys)
        var pubBlob = Data()
        pubBlob.appendSSHString(keyType)
        pubBlob.appendSSHBytes(publicKeyBytes)

        // Private section (unencrypted)
        let checkInt = UInt32.random(in: 0...UInt32.max)
        var privSection = Data()
        privSection.appendSSHUInt32(checkInt)
        privSection.appendSSHUInt32(checkInt)
        privSection.appendSSHString(keyType)
        privSection.appendSSHBytes(publicKeyBytes)
        // Ed25519 private key is 64 bytes: 32 bytes secret + 32 bytes public
        var ed25519Key = Data(privateKey.rawRepresentation)
        ed25519Key.append(publicKeyBytes)
        privSection.appendSSHBytes(ed25519Key)
        privSection.appendSSHString(comment)
        // Padding to block size (8 bytes for "none" cipher)
        let blockSize = 8
        var pad: UInt8 = 1
        while privSection.count % blockSize != 0 {
            privSection.append(pad)
            pad += 1
        }

        // Full file structure
        var file = Data()
        file.append(contentsOf: "openssh-key-v1\0".utf8)  // AUTH_MAGIC
        file.appendSSHString("none")                        // cipher
        file.appendSSHString("none")                        // kdfname
        file.appendSSHBytes(Data())                         // kdfoptions (empty)
        file.appendSSHUInt32(1)                             // number of keys
        file.appendSSHBytes(pubBlob)                        // public key
        file.appendSSHBytes(privSection)                    // private key section

        let b64 = file.base64EncodedString(options: .lineLength76Characters)
        let lines = ["-----BEGIN OPENSSH PRIVATE KEY-----", b64, "-----END OPENSSH PRIVATE KEY-----", ""]
        return Data(lines.joined(separator: "\n").utf8)
    }
}

// MARK: - SSH Wire Format Encoding

private extension Data {
    mutating func appendSSHUInt32(_ value: UInt32) {
        var big = value.bigEndian
        append(Data(bytes: &big, count: 4))
    }

    mutating func appendSSHString(_ string: String) {
        let bytes = Data(string.utf8)
        appendSSHUInt32(UInt32(bytes.count))
        append(bytes)
    }

    mutating func appendSSHBytes(_ data: Data) {
        appendSSHUInt32(UInt32(data.count))
        append(data)
    }
}
