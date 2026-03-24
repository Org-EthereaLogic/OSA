import Foundation

enum QueryNormalizer {
    /// Normalize a user query for retrieval. Returns nil if the query is empty or trivially invalid.
    static func normalize(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowered = trimmed.lowercased()

        // Strip trivial filler words that add no retrieval value
        let stopwords: Set<String> = [
            "a", "an", "the", "is", "are", "was", "were", "be", "been",
            "do", "does", "did", "have", "has", "had", "will", "would",
            "can", "could", "should", "may", "might", "shall",
            "i", "me", "my", "we", "our", "you", "your",
            "it", "its", "this", "that", "these", "those",
            "of", "in", "on", "at", "to", "for", "with", "by", "from",
            "and", "or", "but", "not", "no", "so", "if", "then",
            "what", "how", "where", "when", "who", "which", "why"
        ]

        let words = lowered.components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopwords.contains($0) }

        guard !words.isEmpty else { return nil }

        return words.joined(separator: " ")
    }
}
