import SwiftUI

/// Shared navigation target for the Legal window — callers set this before
/// opening the `legal` window to request a specific initial tab.
@Observable
@MainActor
final class LegalNavigation {
    static let shared = LegalNavigation()
    var requestedDocument: LegalDocument = .privacy
}

/// Unified legal information view with tabs for Privacy Policy, Terms of Use, and Imprint.
/// Documents are loaded from localized Markdown files (`.lproj/*.md`) in the user's language,
/// falling back to English automatically via macOS bundle localization.
struct LegalView: View {
    @State private var navigation = LegalNavigation.shared
    @State private var selectedDocument: LegalDocument = LegalNavigation.shared.requestedDocument

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedDocument) {
                ForEach(LegalDocument.allCases) { doc in
                    Text(doc.title).tag(doc)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                MarkdownView(content: selectedDocument.load())
                    .padding(24)
                    .textSelection(.enabled)
                    .id(selectedDocument)
            }
        }
        .navigationTitle("Legal")
        .environment(\.openURL, OpenURLAction { url in
            // In-app cross-references between legal documents
            if url.scheme == "civoccm", url.host == "legal",
               let rawCase = url.pathComponents.last,
               let doc = LegalDocument(rawValue: rawCase) {
                selectedDocument = doc
                return .handled
            }
            // External http(s) / mailto / etc — let the system handle it (browser/Mail)
            return .systemAction
        })
        .onAppear {
            selectedDocument = navigation.requestedDocument
        }
        .onChange(of: navigation.requestedDocument) { _, newValue in
            selectedDocument = newValue
        }
    }
}

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy
    case terms
    case eula
    case acceptableUse
    case notifications
    case trademarks
    case impressum

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .privacy: return "Privacy"
        case .terms: return "Terms"
        case .eula: return "EULA"
        case .acceptableUse: return "Acceptable Use"
        case .notifications: return "Notifications"
        case .trademarks: return "Trademarks"
        case .impressum: return "Imprint"
        }
    }

    private var filename: String {
        switch self {
        case .privacy: return "PrivacyPolicy"
        case .terms: return "TermsOfService"
        case .eula: return "EULA"
        case .acceptableUse: return "AcceptableUsePolicy"
        case .notifications: return "PushNotificationConsent"
        case .trademarks: return "TrademarkDisclaimer"
        case .impressum: return "Impressum"
        }
    }

    func load() -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "md") else {
            Log.error("LegalDocument: \(filename).md not found in bundle")
            return "Document not available."
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            Log.error("LegalDocument: failed to read \(filename).md: \(error.localizedDescription)")
            return "Document not available."
        }
    }

    /// Maps the canonical legal-repo filenames (and our in-app filenames) to LegalDocument cases.
    /// Used by `MarkdownLinkRewriter` to route `[X](FILENAME.md)` cross-references to the right tab.
    static func documentForFilename(_ filename: String) -> LegalDocument? {
        switch filename {
        case "PrivacyPolicy.md", "PRIVACY_POLICY.md":        return .privacy
        case "TermsOfService.md", "TERMS_OF_SERVICE.md":     return .terms
        case "EULA.md":                                       return .eula
        case "AcceptableUsePolicy.md", "ACCEPTABLE_USE_POLICY.md": return .acceptableUse
        case "PushNotificationConsent.md", "PUSH_NOTIFICATION_CONSENT.md": return .notifications
        case "TrademarkDisclaimer.md", "TRADEMARK_DISCLAIMER.md": return .trademarks
        case "Impressum.md", "IMPRESSUM.md":                  return .impressum
        default: return nil
        }
    }
}
