import Foundation
import SwiftData

@Model
final class PersistedQuickCard {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var title: String
    var category: String
    var summary: String
    var bodyMarkdown: String
    var priority: Int
    var relatedSectionIDsJSON: String
    var tagsJSON: String
    var lastReviewedAt: Date?
    var largeTypeLayoutVersion: Int

    init(
        id: UUID,
        slug: String,
        title: String,
        category: String,
        summary: String,
        bodyMarkdown: String,
        priority: Int,
        relatedSectionIDsJSON: String,
        tagsJSON: String,
        lastReviewedAt: Date?,
        largeTypeLayoutVersion: Int
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.category = category
        self.summary = summary
        self.bodyMarkdown = bodyMarkdown
        self.priority = priority
        self.relatedSectionIDsJSON = relatedSectionIDsJSON
        self.tagsJSON = tagsJSON
        self.lastReviewedAt = lastReviewedAt
        self.largeTypeLayoutVersion = largeTypeLayoutVersion
    }
}
