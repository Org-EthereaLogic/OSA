import Foundation

enum MarkdownPreprocessor {
    /// Converts markdown list items into paragraph-separated bullet points
    /// so that `AttributedString(markdown:)` preserves visual line breaks.
    ///
    /// SwiftUI's `Text(AttributedString)` does not render block-level list
    /// elements — bullet items collapse into a single paragraph. This
    /// preprocessor converts `\n- item` to `\n\n• item` and ensures
    /// numbered list items (`\n1. item`) are paragraph-separated.
    static func prepare(_ markdown: String) -> String {
        var result = markdown

        // Convert unordered list items to paragraph-separated bullets
        result = result.replacingOccurrences(of: "\n- ", with: "\n\n• ")

        // Convert nested unordered list items
        result = result.replacingOccurrences(of: "\n  - ", with: "\n\n  ◦ ")

        // Ensure numbered list items are paragraph-separated
        if let pattern = try? NSRegularExpression(pattern: #"\n(\d+)\. "#) {
            result = pattern.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "\n\n$1. "
            )
        }

        // Clean up any triple+ newlines created by double-conversion
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result
    }
}
