import Foundation
import SwiftData

@Model
final class PersistedChecklistTemplate {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var title: String
    var category: String
    var templateDescription: String
    var estimatedMinutes: Int
    var tagsJSON: String
    var sourceTypeRawValue: String
    var lastReviewedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \PersistedChecklistTemplateItem.template)
    var items: [PersistedChecklistTemplateItem]

    init(
        id: UUID,
        slug: String,
        title: String,
        category: String,
        templateDescription: String,
        estimatedMinutes: Int,
        tagsJSON: String,
        sourceTypeRawValue: String,
        lastReviewedAt: Date?,
        items: [PersistedChecklistTemplateItem] = []
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.category = category
        self.templateDescription = templateDescription
        self.estimatedMinutes = estimatedMinutes
        self.tagsJSON = tagsJSON
        self.sourceTypeRawValue = sourceTypeRawValue
        self.lastReviewedAt = lastReviewedAt
        self.items = items
    }
}
