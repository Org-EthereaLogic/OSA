import Foundation

final class SearchIndexedNoteRepository: NoteRepository {
    private let base: any NoteRepository
    private let searchService: any SearchService

    init(base: any NoteRepository, searchService: any SearchService) {
        self.base = base
        self.searchService = searchService
    }

    func listNotes(type: NoteType?) throws -> [NoteRecord] {
        try base.listNotes(type: type)
    }

    func note(id: UUID) throws -> NoteRecord? {
        try base.note(id: id)
    }

    func createNote(_ note: NoteRecord) throws {
        try base.createNote(note)
        try? searchService.indexNote(note)
    }

    func updateNote(_ note: NoteRecord) throws {
        try base.updateNote(note)
        try? searchService.indexNote(note)
    }

    func deleteNote(id: UUID) throws {
        try base.deleteNote(id: id)
        try? searchService.removeFromIndex(id: id)
    }

    func recentNotes(limit: Int) throws -> [NoteRecord] {
        try base.recentNotes(limit: limit)
    }

    func notesLinkedToSection(id: UUID) throws -> [NoteRecord] {
        try base.notesLinkedToSection(id: id)
    }

    func notesLinkedToInventoryItem(id: UUID) throws -> [NoteRecord] {
        try base.notesLinkedToInventoryItem(id: id)
    }
}
