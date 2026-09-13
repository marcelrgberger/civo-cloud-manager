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
/// matching the system's preferred languages with an explicit English fallback.
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

    static let supportedLanguages = ["en", "de", "es", "fr", "it", "nl", "pl", "pt"]

    static func preferredLanguage(for preferences: [String]) -> String {
        Bundle.preferredLocalizations(from: supportedLanguages, forPreferences: preferences).first ?? "en"
    }

    func load(bundle: Bundle = .main, preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        let language = Self.preferredLanguage(for: preferredLanguages)
        let candidates = language == "en" ? ["en"] : [language, "en"]
        for candidate in candidates {
            guard let url = bundle.resourceURL?
                .appendingPathComponent("\(candidate).lproj", isDirectory: true)
                .appendingPathComponent("\(filename).md") else { continue }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                // Source/version comments are for maintaining the documents, not display.
                let displayedContent = content.replacingOccurrences(
                    of: #"(?s)<!--.*?-->"#, with: "", options: .regularExpression
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                if !displayedContent.isEmpty { return displayedContent }
            }
        }
        Log.error("LegalDocument: \(filename).md unavailable in \(language) and English")
        return String(localized: "Document not available.")
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
