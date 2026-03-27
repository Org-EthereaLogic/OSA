import Foundation

/// Errors raised during normalization of a fetched response.
enum NormalizationError: Error, Equatable {
    case emptyContent
    case unsupportedContentType(String?)
    case decodingFailed
}

/// Intermediate representation of a normalized document, ready for chunking and persistence.
struct NormalizedDocument: Equatable, Sendable {
    let title: String
    let normalizedMarkdown: String
    let plainText: String
    let documentType: DocumentType
    let contentHash: String
    let publisherDomain: String
    let sourceURL: String
}

/// Normalizes a `TrustedSourceFetchResponse` into a `NormalizedDocument`.
///
/// Supports `text/html`, `application/xhtml+xml`, and `text/plain`.
/// Uses Foundation-based text extraction — no third-party HTML parser.
enum ImportedKnowledgeNormalizer {

    // MARK: - Public

    static func normalize(_ response: TrustedSourceFetchResponse) throws -> NormalizedDocument {
        let mime = response.contentType?.lowercased() ?? ""

        let rawText: String
        switch mime {
        case "text/html", "application/xhtml+xml":
            rawText = try extractTextFromHTML(response.body)
        case "text/plain":
            rawText = try decodePlainText(response.body)
        default:
            throw NormalizationError.unsupportedContentType(response.contentType)
        }

        let cleaned = collapseWhitespace(rawText)
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NormalizationError.emptyContent
        }

        let title = deriveTitle(from: response.body, mime: mime, fallbackURL: response.finalURL)
        let documentType = classifyDocumentType(title: title, body: cleaned)
        let markdown = buildMarkdown(title: title, body: cleaned)
        let contentHash = stableHash(markdown)

        return NormalizedDocument(
            title: title,
            normalizedMarkdown: markdown,
            plainText: cleaned,
            documentType: documentType,
            contentHash: contentHash,
            publisherDomain: response.finalURL.host ?? "",
            sourceURL: response.finalURL.absoluteString
        )
    }

    // MARK: - HTML Extraction

    private static func extractTextFromHTML(_ data: Data) throws -> String {
        // Use NSAttributedString HTML import for Foundation-based extraction
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            // Fallback: try raw UTF-8 with tag stripping
            guard let raw = String(data: data, encoding: .utf8) else {
                throw NormalizationError.decodingFailed
            }
            return stripHTMLTags(raw)
        }

        return attributed.string
    }

    private static func stripHTMLTags(_ html: String) -> String {
        // Remove script and style blocks first
        var result = html
        let blockPatterns = [
            "<script[^>]*>[\\s\\S]*?</script[^>]*>",
            "<style[^>]*>[\\s\\S]*?</style[^>]*>"
        ]
        for pattern in blockPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }
        // Strip remaining tags
        if let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>") {
            result = tagRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        // Decode common HTML entities
        result = result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        return result
    }

    // MARK: - Plain Text

    private static func decodePlainText(_ data: Data) throws -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            throw NormalizationError.decodingFailed
        }
        return text
    }

    // MARK: - Whitespace Normalization

    private static func collapseWhitespace(_ text: String) -> String {
        // Normalize line endings
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Collapse runs of 3+ newlines to double newlines (preserve paragraph breaks)
        if let regex = try? NSRegularExpression(pattern: "\\n{3,}") {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "\n\n"
            )
        }

        // Collapse horizontal whitespace within lines
        let lines = result.components(separatedBy: "\n")
        let collapsed = lines.map { line in
            line.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        return collapsed.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Title Derivation

    private static func deriveTitle(from data: Data, mime: String, fallbackURL: URL) -> String {
        if mime == "text/html" || mime == "application/xhtml+xml" {
            if let html = String(data: data, encoding: .utf8) {
                // Try <title> tag
                if let titleRegex = try? NSRegularExpression(pattern: "<title[^>]*>([^<]+)</title>", options: .caseInsensitive),
                   let match = titleRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let title = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !title.isEmpty { return decodeHTMLEntities(title) }
                }
                // Try first <h1>
                if let h1Regex = try? NSRegularExpression(pattern: "<h1[^>]*>([^<]+)</h1>", options: .caseInsensitive),
                   let match = h1Regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let heading = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !heading.isEmpty { return decodeHTMLEntities(heading) }
                }
            }
        }

        // Fallback: use the last path component of the URL, cleaned up
        let lastComponent = fallbackURL.lastPathComponent
        if !lastComponent.isEmpty, lastComponent != "/" {
            return lastComponent
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

        return fallbackURL.host ?? "Imported Document"
    }

    private static func decodeHTMLEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    // MARK: - Document Type Classification

    private static func classifyDocumentType(title: String, body: String) -> DocumentType {
        let lowTitle = title.lowercased()
        let lowBody = body.lowercased()

        // Checklist heuristic: title or body has strong checklist signals
        let checklistKeywords = ["checklist", "check list", "to-do", "supply list", "packing list"]
        if checklistKeywords.contains(where: { lowTitle.contains($0) }) {
            return .checklist
        }

        // Guide heuristic
        let guideKeywords = ["how to", "guide", "tutorial", "step-by-step", "steps to"]
        if guideKeywords.contains(where: { lowTitle.contains($0) }) {
            return .guide
        }

        // Reference heuristic
        let referenceKeywords = ["reference", "fact sheet", "data sheet", "glossary", "faq"]
        if referenceKeywords.contains(where: { lowTitle.contains($0) }) {
            return .reference
        }

        // Body-level checklist check for prominent list structures
        let bulletCount = lowBody.components(separatedBy: "\n").filter {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("- ") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("• ") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("☐") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("☑")
        }.count
        if bulletCount > 10 {
            return .checklist
        }

        return .article
    }

    // MARK: - Markdown Assembly

    private static func buildMarkdown(title: String, body: String) -> String {
        "# \(title)\n\n\(body)"
    }

    // MARK: - Hashing

    static func stableHash(_ content: String) -> String {
        // Use a simple deterministic hash from the normalized content.
        // SHA-256 would be ideal but we avoid importing CryptoKit for this
        // minimal phase. A stable FNV-style hash is sufficient for dedupe.
        var hash: UInt64 = 14695981039346656037 // FNV offset basis
        for byte in content.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211 // FNV prime
        }
        return String(hash, radix: 16)
    }
}
