import Foundation

extension PersistedNoteRecord {
    convenience init(from note: NoteRecord) {
        self.init(
            id: note.id,
            title: note.title,
            bodyMarkdown: note.bodyMarkdown,
            plainText: note.plainText,
            noteTypeRawValue: note.noteType.rawValue,
            tagsJSON: PersistenceValueCoding.encode(note.tags),
            linkedSectionIDsJSON: PersistenceValueCoding.encode(note.linkedSectionIDs),
            linkedInventoryItemIDsJSON: PersistenceValueCoding.encode(note.linkedInventoryItemIDs),
            createdAt: note.createdAt,
            updatedAt: note.updatedAt
        )
    }

    func update(from note: NoteRecord) {
        title = note.title
        bodyMarkdown = note.bodyMarkdown
        plainText = note.plainText
        noteTypeRawValue = note.noteType.rawValue
        tagsJSON = PersistenceValueCoding.encode(note.tags)
        linkedSectionIDsJSON = PersistenceValueCoding.encode(note.linkedSectionIDs)
        linkedInventoryItemIDsJSON = PersistenceValueCoding.encode(note.linkedInventoryItemIDs)
        updatedAt = note.updatedAt
    }

    func toDomain() -> NoteRecord {
        NoteRecord(
            id: id,
            title: title,
            bodyMarkdown: bodyMarkdown,
            plainText: plainText,
            noteType: NoteType(rawValue: noteTypeRawValue) ?? .personal,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            linkedSectionIDs: PersistenceValueCoding.decodeUUIDs(from: linkedSectionIDsJSON),
            linkedInventoryItemIDs: PersistenceValueCoding.decodeUUIDs(from: linkedInventoryItemIDsJSON),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
