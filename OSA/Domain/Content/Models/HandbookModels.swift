import Foundation

enum HandbookSafetyLevel: String, Codable, Equatable, Sendable {
    case normal
    case sensitiveStaticOnly = "sensitive-static-only"
}

struct HandbookChapterSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let sortOrder: Int
    let tags: [String]
    let version: Int
    let isSeeded: Bool
    let lastReviewedAt: Date?
}

struct HandbookSection: Identifiable, Equatable, Sendable {
    let id: UUID
    let chapterID: UUID
    let parentSectionID: UUID?
    let heading: String
    let bodyMarkdown: String
    let plainText: String
    let sortOrder: Int
    let tags: [String]
    let safetyLevel: HandbookSafetyLevel
    let chunkGroupID: String
    let version: Int
    let lastReviewedAt: Date?
}

struct HandbookChapter: Identifiable, Equatable, Sendable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let sortOrder: Int
    let tags: [String]
    let version: Int
    let isSeeded: Bool
    let lastReviewedAt: Date?
    let sections: [HandbookSection]

    var summaryValue: HandbookChapterSummary {
        HandbookChapterSummary(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            sortOrder: sortOrder,
            tags: tags,
            version: version,
            isSeeded: isSeeded,
            lastReviewedAt: lastReviewedAt
        )
    }
}
