import SwiftUI

/// Simple block-level Markdown renderer using only Apple frameworks.
/// Supports: # headings (H1-H3), paragraphs, bullet lists, inline **bold**, *italic*, `code`, [links](url).
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
        MarkdownParser.parse(content)
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
