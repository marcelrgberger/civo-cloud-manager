import SwiftUI

/// Sheet to save, show, copy, edit and delete an instance's credentials in this Mac's keychain.
struct InstanceCredentialsView: View {
    @State private var vault: InstanceCredentialVault
    @State private var username = ""
    @State private var password = ""
    @State private var showsTypedPassword = false
    /// The stored password while editing, until the password field was emptied. Before that the field
    /// holds (parts of) the stored password and stays masked.
    @State private var storedPassword: String?
    @State private var confirmDelete = false
    @State private var canAuthenticate = true
    @Environment(\.dismiss) private var dismiss
    private let store = StoreManager.shared

    init(target: ConsoleTarget) {
        _vault = State(initialValue: InstanceCredentialVault(target: target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credentials for \(vault.target.instanceName)")
                .font(.title2.bold())
            Text("Stored only in this Mac's keychain, without iCloud sync. Showing, copying and editing require Touch ID or your system password.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            content

            if let message = vault.error?.userMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            canAuthenticate = DeviceOwner.canAuthenticate()
            vault.refresh()
        }
        .relocksPassword(vault.access)
        .onChange(of: vault.isEditing) { _, editing in
            if !editing { clearForm() }
        }
        .onChange(of: vault.relocks) {
            // Timeout, lock events and closing also hide a password typed for a new entry.
            showsTypedPassword = false
        }
        .onChange(of: password) { _, typed in
            if typed.isEmpty { storedPassword = nil }
        }
        .task(id: showsTypedPassword) {
            guard showsTypedPassword else { return }
            try? await Task.sleep(for: PasswordAccess.visibleDuration)
            if !Task.isCancelled { showsTypedPassword = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .instanceCredentialsDidChange)) { _ in
            // Saved or deleted elsewhere, e.g. by deleting the instance: check again.
            vault.refresh()
        }
        .onChange(of: store.isFullAccessUnlocked) { _, unlocked in
            if !unlocked {
                vault.invalidate()
                dismiss()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .civoAPIKeyDidChange)) { _ in
            vault.invalidate()
            clearForm()
        }
        .confirmationDialog("Delete the saved credentials?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { vault.delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The username and password for this instance are removed from this Mac's keychain.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if vault.isEditing || vault.entry == .absent {
            form
        } else if vault.entry == .present {
            savedEntry
        } else {
            HStack {
                if vault.error == nil { ProgressView().controlSize(.small) }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
    }

    // MARK: - Saved entry

    private var savedEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Username").foregroundStyle(.secondary)
                    CredentialFieldValue(vault: vault, field: .username)
                }
                GridRow {
                    Text("Password").foregroundStyle(.secondary)
                    CredentialFieldValue(vault: vault, field: .password)
                }
            }
            if vault.access.isDeviceAuthenticationUnavailable {
                DeviceAuthenticationRequiredHint()
            }
            HStack {
                Button("Edit") {
                    Task {
                        if let credential = await vault.beginEditing() {
                            username = credential.username
                            password = credential.password
                            storedPassword = credential.password
                        }
                    }
                }
                Button("Delete…", role: .destructive) { confirmDelete = true }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Username").foregroundStyle(.secondary)
                    ConcealedTextField(placeholder: String(localized: "Optional"), text: $username)
                }
                GridRow {
                    Text("Password").foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        if showsTypedPassword && canShowTypedPassword {
                            ConcealedTextField(placeholder: String(localized: "Required"), text: $password)
                        } else {
                            SecureField("Required", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                        Button {
                            showsTypedPassword.toggle()
                        } label: {
                            Label(
                                showsTypedPassword ? "Hide password" : "Show password",
                                systemImage: showsTypedPassword ? "eye.slash" : "eye"
                            )
                            .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                        .help(showsTypedPassword ? "Hide password" : "Show password")
                        .disabled(!canShowTypedPassword)
                    }
                }
            }
            if !vault.isEditing && !canAuthenticate {
                Label("Touch ID or a system password is required to save credentials.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("Cancel") {
                    if vault.isEditing {
                        vault.cancelEditing()
                    } else {
                        dismiss()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Button("Save") {
                    if vault.save(username: username, password: password) { clearForm() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty || (!vault.isEditing && !canAuthenticate))
            }
        }
    }

    private var canShowTypedPassword: Bool {
        storedPassword == nil
    }

    private func clearForm() {
        username = ""
        password = ""
        storedPassword = nil
        showsTypedPassword = false
    }
}

/// A saved user name or password: masked until revealed, readable in monospace without text
/// selection, copied only through `SecretPasteboard`.
struct CredentialFieldValue: View {
    let vault: InstanceCredentialVault
    let field: InstanceCredentialVault.Field
    @State private var copied = false

    var body: some View {
        HStack(spacing: 6) {
            if let value = vault.value(of: field) {
                if value.isEmpty {
                    Text("No username")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text(verbatim: value)
                        .font(.callout.monospaced())
                }
            } else {
                Text(verbatim: String(repeating: "*", count: 12))
                    .font(.callout.monospaced())
            }
            let isRevealed = vault.revealedFields.contains(field)
            Button {
                if isRevealed {
                    vault.hide(field)
                } else {
                    Task { await vault.reveal(field) }
                }
            } label: {
                Label(revealTitle(isRevealed), systemImage: isRevealed ? "eye.slash" : "eye")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(revealTitle(isRevealed))
            Button {
                Task {
                    if await vault.copy(field) { copied = true }
                }
            } label: {
                Label(copyTitle, systemImage: copied ? "checkmark" : "doc.on.doc")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(copyTitle)
        }
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copied = false }
        }
    }

    private func revealTitle(_ isRevealed: Bool) -> LocalizedStringKey {
        switch (field, isRevealed) {
        case (.username, false): "Show username"
        case (.username, true): "Hide username"
        case (.password, false): "Show password"
        case (.password, true): "Hide password"
        }
    }

    private var copyTitle: LocalizedStringKey {
        field == .username ? "Copy username" : "Copy password"
    }
}
