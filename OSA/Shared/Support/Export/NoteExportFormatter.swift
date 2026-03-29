import Foundation

enum NoteExportFormatter {
    static func markdownContent(for note: NoteRecord) -> String {
        let body = note.bodyMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        return [header(for: note.title, usingMarkdown: true), body, "Shared from OSA"]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    static func plainTextContent(for note: NoteRecord) -> String {
        let body = note.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        return [header(for: note.title, usingMarkdown: false), body, "Shared from OSA"]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    static func storedPlainText(fromMarkdown markdown: String) -> String {
        markdown
            .replacingOccurrences(of: #"(?m)^\s{0,3}#{1,6}[ \t]*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^[ \t]*[-*+][ \t]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^[ \t]*\d+\.[ \t]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[*_~`>#\[\]()!]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func header(for title: String, usingMarkdown: Bool) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return usingMarkdown ? "# \(trimmed)" : trimmed
    }
}
