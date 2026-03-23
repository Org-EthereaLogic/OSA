import Foundation
import SwiftData

@Model
final class PersistedHandbookSection {
    @Attribute(.unique) var id: UUID
    var chapterID: UUID
    var parentSectionID: UUID?
    var heading: String
    var bodyMarkdown: String
    var plainText: String
    var sortOrder: Int
    var tagsJSON: String
    var safetyLevelRawValue: String
    var chunkGroupID: String
    var version: Int
    var lastReviewedAt: Date?
    var chapter: PersistedHandbookChapter?

    init(
        id: UUID,
        chapterID: UUID,
        parentSectionID: UUID?,
        heading: String,
        bodyMarkdown: String,
        plainText: String,
        sortOrder: Int,
        tagsJSON: String,
        safetyLevelRawValue: String,
        chunkGroupID: String,
        version: Int,
        lastReviewedAt: Date?,
        chapter: PersistedHandbookChapter?
    ) {
        self.id = id
        self.chapterID = chapterID
        self.parentSectionID = parentSectionID
        self.heading = heading
        self.bodyMarkdown = bodyMarkdown
        self.plainText = plainText
        self.sortOrder = sortOrder
        self.tagsJSON = tagsJSON
        self.safetyLevelRawValue = safetyLevelRawValue
        self.chunkGroupID = chunkGroupID
        self.version = version
        self.lastReviewedAt = lastReviewedAt
        self.chapter = chapter
    }
}
