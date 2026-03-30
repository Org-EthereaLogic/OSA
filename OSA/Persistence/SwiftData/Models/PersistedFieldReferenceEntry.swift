import Foundation
import SwiftData

@Model
final class PersistedFieldReferenceEntry {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var title: String
    var categoryRawValue: String
    var summary: String
    var sortOrder: Int
    var sectionsJSON: String
    var relatedSectionIDsJSON: String
    var tagsJSON: String
    var safetyLevelRawValue: String
    var lastReviewedAt: Date?

    init(
        id: UUID,
        slug: String,
        title: String,
        categoryRawValue: String,
        summary: String,
        sortOrder: Int,
        sectionsJSON: String,
        relatedSectionIDsJSON: String,
        tagsJSON: String,
        safetyLevelRawValue: String,
        lastReviewedAt: Date?
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.categoryRawValue = categoryRawValue
        self.summary = summary
        self.sortOrder = sortOrder
        self.sectionsJSON = sectionsJSON
        self.relatedSectionIDsJSON = relatedSectionIDsJSON
        self.tagsJSON = tagsJSON
        self.safetyLevelRawValue = safetyLevelRawValue
        self.lastReviewedAt = lastReviewedAt
    }
}
