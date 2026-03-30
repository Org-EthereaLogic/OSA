import Foundation

struct QuickCardTranslation: Codable, Equatable, Sendable {
    let title: String?
    let summary: String?
    let bodyMarkdown: String?
}

struct QuickCard: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let slug: String
    let category: String
    let summary: String
    let bodyMarkdown: String
    let priority: Int
    let relatedSectionIDs: [UUID]
    let tags: [String]
    let lastReviewedAt: Date?
    let largeTypeLayoutVersion: Int
    let spanishTranslation: QuickCardTranslation?
    let mediaAttachments: [LocalMediaAttachment]
    let quizDefinition: QuizDefinition?
    let weeklyDrillMetadata: WeeklyDrillMetadata?

    init(
        id: UUID,
        title: String,
        slug: String,
        category: String,
        summary: String,
        bodyMarkdown: String,
        priority: Int,
        relatedSectionIDs: [UUID],
        tags: [String],
        lastReviewedAt: Date?,
        largeTypeLayoutVersion: Int,
        spanishTranslation: QuickCardTranslation? = nil,
        mediaAttachments: [LocalMediaAttachment] = [],
        quizDefinition: QuizDefinition? = nil,
        weeklyDrillMetadata: WeeklyDrillMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.category = category
        self.summary = summary
        self.bodyMarkdown = bodyMarkdown
        self.priority = priority
        self.relatedSectionIDs = relatedSectionIDs
        self.tags = tags
        self.lastReviewedAt = lastReviewedAt
        self.largeTypeLayoutVersion = largeTypeLayoutVersion
        self.spanishTranslation = spanishTranslation
        self.mediaAttachments = mediaAttachments
        self.quizDefinition = quizDefinition
        self.weeklyDrillMetadata = weeklyDrillMetadata
    }

    var searchableText: String {
        [
            title,
            summary,
            category,
            bodyMarkdown,
            mediaAttachments.map(\.searchableText).joined(separator: " "),
            quizDefinition?.searchableText
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    func localizedTitle(for language: AppLanguage) -> String {
        switch language {
        case .english:
            title
        case .spanish:
            spanishTranslation?.title?.nonEmpty ?? title
        }
    }

    func localizedSummary(for language: AppLanguage) -> String {
        switch language {
        case .english:
            summary
        case .spanish:
            spanishTranslation?.summary?.nonEmpty ?? summary
        }
    }

    func localizedBodyMarkdown(for language: AppLanguage) -> String {
        switch language {
        case .english:
            bodyMarkdown
        case .spanish:
            spanishTranslation?.bodyMarkdown?.nonEmpty ?? bodyMarkdown
        }
    }

    func localizedSearchableText(for language: AppLanguage) -> String {
        [
            localizedTitle(for: language),
            localizedSummary(for: language),
            category,
            localizedBodyMarkdown(for: language),
            mediaAttachments.map { $0.searchableText(for: language) }.joined(separator: " "),
            quizDefinition?.searchableText
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
