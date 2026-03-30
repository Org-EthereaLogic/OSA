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
    var spanishTranslationJSON: String = "null"
    var mediaAttachmentsJSON: String
    var quizDefinitionJSON: String
    var weeklyDrillMetadataJSON: String

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
        largeTypeLayoutVersion: Int,
        spanishTranslationJSON: String = "null",
        mediaAttachmentsJSON: String,
        quizDefinitionJSON: String,
        weeklyDrillMetadataJSON: String
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
        self.spanishTranslationJSON = spanishTranslationJSON
        self.mediaAttachmentsJSON = mediaAttachmentsJSON
        self.quizDefinitionJSON = quizDefinitionJSON
        self.weeklyDrillMetadataJSON = weeklyDrillMetadataJSON
    }
}
