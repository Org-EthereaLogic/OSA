import Foundation

/// Splits a `NormalizedDocument` into ordered `KnowledgeChunk` values
/// suitable for retrieval and FTS indexing.
///
/// Chunking strategy:
/// 1. If the text contains heading-like lines (lines that start with `# `),
///    split at heading boundaries.
/// 2. Otherwise, group adjacent paragraphs into chunks of roughly
///    150–400 words.
/// 3. Never split mid-sentence unless a single paragraph exceeds the
///    maximum chunk size.
enum KnowledgeChunker {

    /// Target word count range per chunk.
    private static let minWordsPerChunk = 150
    private static let maxWordsPerChunk = 400

    /// Chunks a normalized document into ordered `KnowledgeChunk` values.
    ///
    /// - Parameters:
    ///   - document: The normalized document to chunk.
    ///   - documentID: The persistence ID of the parent `ImportedKnowledgeDocument`.
    ///   - trustLevel: Inherited from the trusted-source definition.
    ///   - isSearchable: `true` only when the source review status is `.approved`.
    ///   - tags: Metadata tags to attach to each chunk.
    static func chunk(
        _ document: NormalizedDocument,
        documentID: UUID,
        trustLevel: TrustLevel,
        isSearchable: Bool,
        tags: [String]
    ) -> [KnowledgeChunk] {
        let sections = splitIntoSections(document.plainText)
        var chunks: [KnowledgeChunk] = []
        var sortOrder = 0

        for section in sections {
            let sectionChunks = splitSectionIntoParagraphGroups(section.body)
            for chunkText in sectionChunks {
                let trimmed = chunkText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                let wordCount = trimmed.components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }.count
                let localChunkID = deterministicChunkID(
                    sourceURL: document.sourceURL,
                    sortOrder: sortOrder,
                    contentHash: ImportedKnowledgeNormalizer.stableHash(trimmed)
                )

                chunks.append(KnowledgeChunk(
                    id: UUID(),
                    documentID: documentID,
                    localChunkID: localChunkID,
                    headingPath: section.heading,
                    plainText: trimmed,
                    sortOrder: sortOrder,
                    tokenEstimate: max(1, Int(Double(wordCount) * 1.3)),
                    tags: tags,
                    trustLevel: trustLevel,
                    contentHash: ImportedKnowledgeNormalizer.stableHash(trimmed),
                    isSearchable: isSearchable
                ))
                sortOrder += 1
            }
        }

        return chunks
    }

    // MARK: - Section Splitting

    private struct Section {
        let heading: String
        let body: String
    }

    /// Splits text at heading lines (lines starting with `# `).
    private static func splitIntoSections(_ text: String) -> [Section] {
        let lines = text.components(separatedBy: "\n")
        var sections: [Section] = []
        var currentHeading = ""
        var currentBody: [String] = []

        for line in lines {
            if line.hasPrefix("# ") || line.hasPrefix("## ") || line.hasPrefix("### ") {
                // Flush previous section
                if !currentBody.isEmpty {
                    sections.append(Section(
                        heading: currentHeading,
                        body: currentBody.joined(separator: "\n")
                    ))
                }
                currentHeading = line.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                currentBody = []
            } else {
                currentBody.append(line)
            }
        }

        // Flush last section
        if !currentBody.isEmpty {
            sections.append(Section(
                heading: currentHeading,
                body: currentBody.joined(separator: "\n")
            ))
        }

        // If no headings were found, return the whole text as one section
        if sections.isEmpty {
            return [Section(heading: "", body: text)]
        }

        return sections
    }

    // MARK: - Paragraph Grouping

    /// Groups paragraphs within a section into chunks of roughly
    /// `minWordsPerChunk` to `maxWordsPerChunk` words.
    private static func splitSectionIntoParagraphGroups(_ text: String) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !paragraphs.isEmpty else { return [] }

        var groups: [String] = []
        var currentGroup: [String] = []
        var currentWordCount = 0

        for paragraph in paragraphs {
            let words = paragraph.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.count

            // If a single paragraph exceeds max, flush current group and add it alone
            if words > maxWordsPerChunk {
                if !currentGroup.isEmpty {
                    groups.append(currentGroup.joined(separator: "\n\n"))
                    currentGroup = []
                    currentWordCount = 0
                }
                groups.append(paragraph)
                continue
            }

            // If adding this paragraph would exceed max, flush first
            if currentWordCount + words > maxWordsPerChunk, !currentGroup.isEmpty {
                groups.append(currentGroup.joined(separator: "\n\n"))
                currentGroup = []
                currentWordCount = 0
            }

            currentGroup.append(paragraph)
            currentWordCount += words
        }

        // Flush remaining
        if !currentGroup.isEmpty {
            groups.append(currentGroup.joined(separator: "\n\n"))
        }

        return groups
    }

    // MARK: - Deterministic Chunk ID

    /// Produces a deterministic UUID from source URL, sort order, and content hash.
    private static func deterministicChunkID(sourceURL: String, sortOrder: Int, contentHash: String) -> UUID {
        let input = "\(sourceURL):\(sortOrder):\(contentHash)"
        let hash = ImportedKnowledgeNormalizer.stableHash(input)
        // Pad or truncate to 32 hex chars for UUID
        let padded = (hash + hash + hash).prefix(32)
        let uuidString = formatAsUUID(String(padded))
        return UUID(uuidString: uuidString) ?? UUID()
    }

    private static func formatAsUUID(_ hex: String) -> String {
        let chars = Array(hex)
        guard chars.count >= 32 else { return hex }
        let parts = [
            String(chars[0..<8]),
            String(chars[8..<12]),
            String(chars[12..<16]),
            String(chars[16..<20]),
            String(chars[20..<32])
        ]
        return parts.joined(separator: "-")
    }
}
