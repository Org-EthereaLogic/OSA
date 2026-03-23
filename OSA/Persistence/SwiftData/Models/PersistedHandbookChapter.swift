import Foundation
import SwiftData

@Model
final class PersistedHandbookChapter {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var title: String
    var summary: String
    var sortOrder: Int
    var tagsJSON: String
    var version: Int
    var isSeeded: Bool
    var lastReviewedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \PersistedHandbookSection.chapter)
    var sections: [PersistedHandbookSection]

    init(
        id: UUID,
        slug: String,
        title: String,
        summary: String,
        sortOrder: Int,
        tagsJSON: String,
        version: Int,
        isSeeded: Bool,
        lastReviewedAt: Date?,
        sections: [PersistedHandbookSection] = []
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.sortOrder = sortOrder
        self.tagsJSON = tagsJSON
        self.version = version
        self.isSeeded = isSeeded
        self.lastReviewedAt = lastReviewedAt
        self.sections = sections
    }
}
