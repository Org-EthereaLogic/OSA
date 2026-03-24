import Foundation
import SwiftData

@Model
final class PersistedNoteRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var bodyMarkdown: String
    var plainText: String
    var noteTypeRawValue: String
    var tagsJSON: String
    var linkedSectionIDsJSON: String
    var linkedInventoryItemIDsJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        title: String,
        bodyMarkdown: String,
        plainText: String,
        noteTypeRawValue: String,
        tagsJSON: String,
        linkedSectionIDsJSON: String,
        linkedInventoryItemIDsJSON: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.bodyMarkdown = bodyMarkdown
        self.plainText = plainText
        self.noteTypeRawValue = noteTypeRawValue
        self.tagsJSON = tagsJSON
        self.linkedSectionIDsJSON = linkedSectionIDsJSON
        self.linkedInventoryItemIDsJSON = linkedInventoryItemIDsJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
