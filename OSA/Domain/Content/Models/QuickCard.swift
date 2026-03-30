import Foundation

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
}
