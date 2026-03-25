import Foundation
import SwiftData

final class SwiftDataNoteRepository: NoteRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listNotes(type: NoteType?) throws -> [NoteRecord] {
        var descriptor: FetchDescriptor<PersistedNoteRecord>

        if let type {
            let rawValue = type.rawValue
            descriptor = FetchDescriptor<PersistedNoteRecord>(
                predicate: #Predicate { $0.noteTypeRawValue == rawValue },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PersistedNoteRecord>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }

        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func note(id: UUID) throws -> NoteRecord? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedNoteRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createNote(_ note: NoteRecord) throws {
        modelContext.insert(PersistedNoteRecord(from: note))
        try modelContext.save()
    }

    func updateNote(_ note: NoteRecord) throws {
        let targetID = note.id
        let descriptor = FetchDescriptor<PersistedNoteRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: note)
        try modelContext.save()
    }

    func deleteNote(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedNoteRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func recentNotes(limit: Int) throws -> [NoteRecord] {
        var descriptor = FetchDescriptor<PersistedNoteRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func notesLinkedToSection(id: UUID) throws -> [NoteRecord] {
        let targetIDString = id.uuidString
        var descriptor = FetchDescriptor<PersistedNoteRecord>(
            predicate: #Predicate { $0.linkedSectionIDsJSON.contains(targetIDString) },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { $0.toDomain() }
            .filter { $0.linkedSectionIDs.contains(id) }
    }

    func notesLinkedToInventoryItem(id: UUID) throws -> [NoteRecord] {
        let targetIDString = id.uuidString
        var descriptor = FetchDescriptor<PersistedNoteRecord>(
            predicate: #Predicate { $0.linkedInventoryItemIDsJSON.contains(targetIDString) },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { $0.toDomain() }
            .filter { $0.linkedInventoryItemIDs.contains(id) }
    }
}
