import SwiftData
import XCTest
@testable import OSA

@MainActor
final class NoteRepositoryTests: XCTestCase {
    func testCreateAndListNotes() throws {
        let repository = try makeRepository()

        let note = makeNote(title: "Emergency Contacts", noteType: .familyPlan)
        try repository.createNote(note)

        let notes = try repository.listNotes(type: nil)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Emergency Contacts")
        XCTAssertEqual(notes.first?.noteType, .familyPlan)
    }

    func testNoteByID() throws {
        let repository = try makeRepository()

        let note = makeNote(title: "Meeting Points", noteType: .personal)
        try repository.createNote(note)

        let fetched = try XCTUnwrap(repository.note(id: note.id))
        XCTAssertEqual(fetched.title, "Meeting Points")
    }

    func testUpdateNote() throws {
        let repository = try makeRepository()

        var note = makeNote(title: "Draft", noteType: .personal)
        try repository.createNote(note)

        note.title = "Final Version"
        note.bodyMarkdown = "Updated content"
        note.plainText = "Updated content"
        note.updatedAt = Date()
        try repository.updateNote(note)

        let fetched = try XCTUnwrap(repository.note(id: note.id))
        XCTAssertEqual(fetched.title, "Final Version")
        XCTAssertEqual(fetched.bodyMarkdown, "Updated content")
    }

    func testDeleteNote() throws {
        let repository = try makeRepository()

        let note = makeNote(title: "To Delete", noteType: .personal)
        try repository.createNote(note)

        try repository.deleteNote(id: note.id)
        let fetched = try repository.note(id: note.id)
        XCTAssertNil(fetched)
    }

    func testFilterByType() throws {
        let repository = try makeRepository()

        try repository.createNote(makeNote(title: "Personal Note", noteType: .personal))
        try repository.createNote(makeNote(title: "Family Plan", noteType: .familyPlan))
        try repository.createNote(makeNote(title: "Reference", noteType: .localReference))

        let personal = try repository.listNotes(type: .personal)
        XCTAssertEqual(personal.count, 1)
        XCTAssertEqual(personal.first?.title, "Personal Note")

        let family = try repository.listNotes(type: .familyPlan)
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(family.first?.title, "Family Plan")
    }

    func testRecentNotes() throws {
        let repository = try makeRepository()

        let older = makeNote(title: "Older", noteType: .personal, updatedAt: Date(timeIntervalSince1970: 1_000_000))
        let newer = makeNote(title: "Newer", noteType: .personal, updatedAt: Date(timeIntervalSince1970: 2_000_000))

        try repository.createNote(older)
        try repository.createNote(newer)

        let recent = try repository.recentNotes(limit: 1)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.title, "Newer")
    }

    func testNotesLinkedToSection() throws {
        let repository = try makeRepository()

        let sectionID = UUID()
        let linked = makeNote(title: "Linked", noteType: .personal, linkedSectionIDs: [sectionID])
        let unlinked = makeNote(title: "Unlinked", noteType: .personal)

        try repository.createNote(linked)
        try repository.createNote(unlinked)

        let results = try repository.notesLinkedToSection(id: sectionID)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Linked")
    }

    func testNotesLinkedToInventoryItem() throws {
        let repository = try makeRepository()

        let itemID = UUID()
        let linked = makeNote(title: "Linked", noteType: .personal, linkedInventoryItemIDs: [itemID])
        let unlinked = makeNote(title: "Unlinked", noteType: .personal)

        try repository.createNote(linked)
        try repository.createNote(unlinked)

        let results = try repository.notesLinkedToInventoryItem(id: itemID)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Linked")
    }

    // MARK: - Helpers

    private func makeRepository() throws -> SwiftDataNoteRepository {
        let schema = Schema([PersistedNoteRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return SwiftDataNoteRepository(modelContext: container.mainContext)
    }

    private func makeNote(
        title: String,
        noteType: NoteType,
        updatedAt: Date = Date(),
        linkedSectionIDs: [UUID] = [],
        linkedInventoryItemIDs: [UUID] = []
    ) -> NoteRecord {
        NoteRecord(
            id: UUID(),
            title: title,
            bodyMarkdown: "Test body",
            plainText: "Test body",
            noteType: noteType,
            tags: [],
            linkedSectionIDs: linkedSectionIDs,
            linkedInventoryItemIDs: linkedInventoryItemIDs,
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }
}
