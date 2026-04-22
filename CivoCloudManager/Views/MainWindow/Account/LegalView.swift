import SwiftUI

/// Unified legal information view with tabs for Privacy Policy, Terms of Use, and Imprint.
/// Documents are loaded from localized Markdown files (`.lproj/*.md`) in the user's language,
/// falling back to English automatically via macOS bundle localization.
struct LegalView: View {
    @State private var selectedDocument: LegalDocument = .privacy

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
    }
}

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy
    case terms
    case impressum

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        case .impressum: return "Imprint"
        }
    }

    private var filename: String {
        switch self {
        case .privacy: return "PrivacyPolicy"
        case .terms: return "TermsOfService"
        case .impressum: return "Impressum"
        }
    }

    func load() -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return "Document not available."
        }
        return text
    }
}
