import SwiftUI

/// Simple block-level Markdown renderer using only Apple frameworks.
/// Supports: # headings (H1-H3), paragraphs, bullet lists, inline **bold**, *italic*, `code`, [links](url).
///
/// Relative `*.md` links are rewritten at render time: targets that map to a known
/// in-app `LegalDocument` become `civoccm://legal/<case>` (handled by `LegalView`'s
/// `OpenURLAction`); unresolved targets are unwrapped to plain text so the system
/// browser is never asked to open a non-existent file (which on macOS produces -50).
struct MarkdownView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                render(block)
            }
        }
    }

    private var blocks: [Block] {
        MarkdownParser.parse(MarkdownLinkRewriter.rewrite(content))
    }

    @ViewBuilder
    private func render(_ block: Block) -> some View {
        switch block {
        case .heading1(let text):
            Text(inline(text))
                .font(.title.bold())
                .padding(.top, 8)
        case .heading2(let text):
            Text(inline(text))
                .font(.title2.bold())
                .padding(.top, 6)
        case .heading3(let text):
            Text(inline(text))
                .font(.headline)
                .padding(.top, 4)
        case .paragraph(let text):
            Text(inline(text))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text(inline(item))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        case .horizontalRule:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
    }
}

// MARK: - Link rewriter

enum MarkdownLinkRewriter {
    /// Rewrites `[text](FILENAME.md)` style references:
    /// - if `FILENAME.md` maps to an in-app `LegalDocument`, the URL becomes `civoccm://legal/<case>`
    /// - otherwise the link wrapping is stripped so only the link text remains
    /// External `http(s)://` and `mailto:` links are left untouched.
    static func rewrite(_ content: String) -> String {
        // `(?s)` not needed — markdown links don't span lines
        // Pattern: [text](target) where target contains no spaces or close-paren
        // We don't try to be RFC-perfect; this matches the same shape MarkdownParser/AttributedString accept.
        guard let regex = try? NSRegularExpression(
            pattern: #"\[([^\]\n]+)\]\(([^)\s]+)\)"#
        ) else { return content }

        var result = ""
        var cursor = content.startIndex
        let nsContent = content as NSString
        let fullRange = NSRange(location: 0, length: nsContent.length)

        regex.enumerateMatches(in: content, range: fullRange) { match, _, _ in
            guard let match,
                  let textRange = Range(match.range(at: 1), in: content),
                  let targetRange = Range(match.range(at: 2), in: content),
                  let matchRange = Range(match.range, in: content)
            else { return }

            // Append everything between the previous match and this one verbatim
            result.append(contentsOf: content[cursor..<matchRange.lowerBound])
            cursor = matchRange.upperBound

            let text = String(content[textRange])
            let target = String(content[targetRange])

            if let doc = LegalDocument.documentForFilename(target) {
                result.append("[\(text)](civoccm://legal/\(doc.rawValue))")
            } else if target.hasSuffix(".md") {
                // Unknown sibling doc — strip link wrapping
                result.append(text)
            } else {
                // External link (https://, mailto:, etc) — keep as-is
                result.append("[\(text)](\(target))")
            }
        }
        result.append(contentsOf: content[cursor..<content.endIndex])
        return result
    }
}

// MARK: - Block Types

enum Block {
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case paragraph(String)
    case bulletList([String])
    case horizontalRule
}

// MARK: - Parser

enum MarkdownParser {
    static func parse(_ text: String) -> [Block] {
        var blocks: [Block] = []
        var paragraphBuffer: [String] = []
        var bulletBuffer: [String] = []

        func flushParagraph() {
            if !paragraphBuffer.isEmpty {
                let combined = paragraphBuffer.joined(separator: " ")
                blocks.append(.paragraph(combined))
                paragraphBuffer.removeAll()
            }
        }

        func flushBullets() {
            if !bulletBuffer.isEmpty {
                blocks.append(.bulletList(bulletBuffer))
                bulletBuffer.removeAll()
            }
        }

        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                flushBullets()
                continue
            }

            // Horizontal rule
            if line == "---" || line == "***" {
                flushParagraph()
                flushBullets()
                blocks.append(.horizontalRule)
                continue
            }

            // Headings
            if line.hasPrefix("### ") {
                flushParagraph()
                flushBullets()
                blocks.append(.heading3(String(line.dropFirst(4))))
                continue
            }
            if line.hasPrefix("## ") {
                flushParagraph()
                flushBullets()
                blocks.append(.heading2(String(line.dropFirst(3))))
                continue
            }
            if line.hasPrefix("# ") {
                flushParagraph()
                flushBullets()
                blocks.append(.heading1(String(line.dropFirst(2))))
                continue
            }

            // Bullet items
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                bulletBuffer.append(String(line.dropFirst(2)))
                continue
            }

            // Paragraph line
            flushBullets()
            paragraphBuffer.append(line)
        }

        flushParagraph()
        flushBullets()
        return blocks
    }
}
