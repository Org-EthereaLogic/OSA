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
}
