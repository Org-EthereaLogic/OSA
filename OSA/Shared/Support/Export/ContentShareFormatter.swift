import Foundation

enum ContentShareFormatter {
    static func quickCardText(for card: QuickCard, language: AppLanguage = .english) -> String {
        [
            card.localizedTitle(for: language),
            card.localizedSummary(for: language).trimmingCharacters(in: .whitespacesAndNewlines),
            AppLocalization.localized("Shared from OSA", language: language)
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    static func handbookSectionText(
        for section: HandbookSection,
        chapterTitle: String?
    ) -> String {
        var parts = [section.heading]

        if let chapterTitle, !chapterTitle.isEmpty {
            parts.append("Handbook: \(chapterTitle)")
        }

        parts.append(excerpt(from: section.plainText, maxLength: 480))
        parts.append("Shared from OSA")

        return parts
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func excerpt(from text: String, maxLength: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }

        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return "\(trimmed[..<endIndex])."
    }
}
