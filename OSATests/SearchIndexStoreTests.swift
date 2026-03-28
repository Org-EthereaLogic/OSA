import XCTest
@testable import OSA

final class SearchIndexStoreTests: XCTestCase {
    func testInsertAndQuery() throws {
        let store = try SearchIndexStore()

        try store.upsert(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            kind: .handbookSection,
            title: "Water Storage Basics",
            body: "Store one gallon per person per day for at least three days.",
            tags: "water storage basics"
        )

        let results = try store.query(text: "water", kindFilter: nil, limit: 10)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Water Storage Basics")
        XCTAssertEqual(results.first?.kind, .handbookSection)
    }

    func testUpsertReplacesExisting() throws {
        let store = try SearchIndexStore()
        let id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        try store.upsert(id: id, kind: .inventoryItem, title: "Old Title", body: "Old body", tags: "")
        try store.upsert(id: id, kind: .inventoryItem, title: "New Title", body: "New body", tags: "")

        let results = try store.query(text: "new", kindFilter: nil, limit: 10)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "New Title")

        let oldResults = try store.query(text: "old", kindFilter: nil, limit: 10)
        XCTAssertTrue(oldResults.isEmpty)
    }

    func testRemoveEntry() throws {
        let store = try SearchIndexStore()
        let id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        try store.upsert(id: id, kind: .noteRecord, title: "Test Note", body: "Some content", tags: "")
        try store.removeEntry(id: id)

        let results = try store.query(text: "test", kindFilter: nil, limit: 10)
        XCTAssertTrue(results.isEmpty)
    }

    func testKindFilter() throws {
        let store = try SearchIndexStore()

        try store.upsert(id: UUID(), kind: .handbookSection, title: "Water Guide", body: "Water info", tags: "")
        try store.upsert(id: UUID(), kind: .inventoryItem, title: "Water Jug", body: "Water storage", tags: "")

        let onlyHandbook = try store.query(text: "water", kindFilter: [.handbookSection], limit: 10)
        XCTAssertEqual(onlyHandbook.count, 1)
        XCTAssertEqual(onlyHandbook.first?.kind, .handbookSection)

        let onlyInventory = try store.query(text: "water", kindFilter: [.inventoryItem], limit: 10)
        XCTAssertEqual(onlyInventory.count, 1)
        XCTAssertEqual(onlyInventory.first?.kind, .inventoryItem)

        let both = try store.query(text: "water", kindFilter: [.handbookSection, .inventoryItem], limit: 10)
        XCTAssertEqual(both.count, 2)
    }

    func testEmptyQueryReturnsNoResults() throws {
        let store = try SearchIndexStore()
        try store.upsert(id: UUID(), kind: .quickCard, title: "Test", body: "Content", tags: "")

        let results = try store.query(text: "", kindFilter: nil, limit: 10)
        XCTAssertTrue(results.isEmpty)

        let whitespace = try store.query(text: "   ", kindFilter: nil, limit: 10)
        XCTAssertTrue(whitespace.isEmpty)
    }

    func testRemoveAll() throws {
        let store = try SearchIndexStore()
        try store.upsert(id: UUID(), kind: .noteRecord, title: "Note 1", body: "Content", tags: "")
        try store.upsert(id: UUID(), kind: .noteRecord, title: "Note 2", body: "Content", tags: "")

        try store.removeAll()

        let results = try store.query(text: "note", kindFilter: nil, limit: 10)
        XCTAssertTrue(results.isEmpty)
    }

    func testStemming() throws {
        let store = try SearchIndexStore()
        try store.upsert(id: UUID(), kind: .handbookSection, title: "Running Water", body: "The water is running", tags: "")

        // Porter stemmer should match "run" to "running"
        let results = try store.query(text: "run", kindFilter: nil, limit: 10)
        XCTAssertEqual(results.count, 1)
    }

    func testSuggestionsIncludeTitlesAndNamespacedTags() throws {
        let store = try SearchIndexStore()
        try store.upsert(
            id: UUID(),
            kind: .quickCard,
            title: "Wildfire Evacuation Checklist",
            body: "Pack the car early.",
            tags: "scenario:wildfire region:pacific-northwest season:summer"
        )

        let titleSuggestions = try store.suggestions(prefix: "wild", limit: 5)
        XCTAssertTrue(titleSuggestions.contains { $0.text == "Wildfire Evacuation Checklist" && $0.source == .title })

        let tagSuggestions = try store.suggestions(prefix: "scenario:w", limit: 5)
        XCTAssertTrue(tagSuggestions.contains { $0.text == "scenario:wildfire" && $0.source == .tag })
    }

    func testSuggestionsDeduplicateCaseVariants() throws {
        let store = try SearchIndexStore()
        let sharedID = UUID()

        try store.upsert(
            id: sharedID,
            kind: .quickCard,
            title: "Winter Storm Plan",
            body: "Stay warm.",
            tags: "scenario:winter-storm"
        )
        try store.upsert(
            id: UUID(),
            kind: .handbookSection,
            title: "winter storm plan",
            body: "Duplicate casing.",
            tags: "scenario:winter-storm"
        )

        let suggestions = try store.suggestions(prefix: "winter", limit: 10)
        XCTAssertEqual(
            suggestions.filter { $0.text.lowercased() == "winter storm plan" }.count,
            1
        )
    }
}
