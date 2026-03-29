import Foundation

struct StudyGuideBuilder {
    private let studyGuideTag = "study-guide"

    func makeNote(
        from result: AnswerResult,
        preferredTags: Set<String>,
        now: Date = Date()
    ) -> NoteRecord {
        let title = "Study Guide: \(result.query.trimmingCharacters(in: .whitespacesAndNewlines))"
        let markdown = buildMarkdown(from: result, preferredTags: preferredTags)
        let tags = Set([studyGuideTag] + preferredTags)
        let linkedSectionIDs = result.citations
            .filter { $0.kind == .handbookSection }
            .map(\.id)

        return NoteRecord(
            id: UUID(),
            title: title,
            bodyMarkdown: markdown,
            plainText: NoteExportFormatter.storedPlainText(fromMarkdown: markdown),
            noteType: .localReference,
            tags: tags.sorted(),
            linkedSectionIDs: linkedSectionIDs,
            linkedInventoryItemIDs: [],
            createdAt: now,
            updatedAt: now
        )
    }

    func buildMarkdown(
        from result: AnswerResult,
        preferredTags: Set<String>
    ) -> String {
        var sections = ["# Study Guide: \(result.query.trimmingCharacters(in: .whitespacesAndNewlines))"]

        if let regionLabel = preferredRegionLabel(from: preferredTags) {
            sections.append("## Preference Context\n- Region preference: \(regionLabel)")
        }

        sections.append("## Overview\n\(result.answerText.trimmingCharacters(in: .whitespacesAndNewlines))")

        let keyPoints = zip(result.evidence, result.citations).map { evidence, citation in
            "### \(citation.displayLabel)\n\(evidence.snippet.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        if !keyPoints.isEmpty {
            sections.append("## Key Points\n" + keyPoints.joined(separator: "\n\n"))
        }

        let sources = result.citations
            .map(\.displayLabel)
            .map { "- \($0)" }
        if !sources.isEmpty {
            sections.append("## Sources\n" + sources.joined(separator: "\n"))
        }

        return sections.joined(separator: "\n\n")
    }

    private func preferredRegionLabel(from preferredTags: Set<String>) -> String? {
        guard let regionTag = preferredTags.first(where: { $0.hasPrefix("region:") }) else {
            return nil
        }

        return regionTag
            .replacingOccurrences(of: "region:", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
