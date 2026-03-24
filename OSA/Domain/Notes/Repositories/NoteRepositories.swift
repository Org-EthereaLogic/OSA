import Foundation

protocol NoteRepository {
    func listNotes(type: NoteType?) throws -> [NoteRecord]
    func note(id: UUID) throws -> NoteRecord?
    func createNote(_ note: NoteRecord) throws
    func updateNote(_ note: NoteRecord) throws
    func deleteNote(id: UUID) throws
    func recentNotes(limit: Int) throws -> [NoteRecord]
    func notesLinkedToSection(id: UUID) throws -> [NoteRecord]
    func notesLinkedToInventoryItem(id: UUID) throws -> [NoteRecord]
}
