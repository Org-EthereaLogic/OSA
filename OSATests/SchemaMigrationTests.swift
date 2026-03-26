import SwiftData
import XCTest
@testable import OSA

/// Validates that the current SwiftData schema (V1) can be created, populated,
/// and round-tripped without corruption. These tests form a baseline assertion
/// so future schema changes can be verified against a known-good starting point.
@MainActor
final class SchemaMigrationTests: XCTestCase {

    // MARK: - Full-Schema Model Types

    /// The canonical list of all model types that must be present in the V1 schema.
    private static let allModelTypes: [any PersistentModel.Type] = [
        PersistedHandbookChapter.self,
        PersistedHandbookSection.self,
        PersistedQuickCard.self,
        PersistedSeedContentState.self,
        PersistedInventoryItem.self,
        PersistedChecklistTemplate.self,
        PersistedChecklistTemplateItem.self,
        PersistedChecklistRun.self,
        PersistedChecklistRunItem.self,
        PersistedNoteRecord.self,
        PersistedSourceRecord.self,
        PersistedImportedKnowledgeDocument.self,
        PersistedKnowledgeChunk.self,
        PersistedPendingOperation.self
    ]

    // MARK: - Container Creation

    func testContainerCanBeCreatedWithAllModelTypes() throws {
        let container = try makeFullSchemaContainer()
        XCTAssertNotNil(container)
    }

    func testAllFourteenModelTypesAreRegisteredInSchema() throws {
        let schema = Schema(Self.allModelTypes)
        let entityNames = Set(schema.entities.map(\.name))

        XCTAssertEqual(entityNames.count, 14, "Expected 14 entity types in the V1 schema")
        XCTAssertTrue(entityNames.contains("PersistedHandbookChapter"))
        XCTAssertTrue(entityNames.contains("PersistedHandbookSection"))
        XCTAssertTrue(entityNames.contains("PersistedQuickCard"))
        XCTAssertTrue(entityNames.contains("PersistedSeedContentState"))
        XCTAssertTrue(entityNames.contains("PersistedInventoryItem"))
        XCTAssertTrue(entityNames.contains("PersistedChecklistTemplate"))
        XCTAssertTrue(entityNames.contains("PersistedChecklistTemplateItem"))
        XCTAssertTrue(entityNames.contains("PersistedChecklistRun"))
        XCTAssertTrue(entityNames.contains("PersistedChecklistRunItem"))
        XCTAssertTrue(entityNames.contains("PersistedNoteRecord"))
        XCTAssertTrue(entityNames.contains("PersistedSourceRecord"))
        XCTAssertTrue(entityNames.contains("PersistedImportedKnowledgeDocument"))
        XCTAssertTrue(entityNames.contains("PersistedKnowledgeChunk"))
        XCTAssertTrue(entityNames.contains("PersistedPendingOperation"))
    }

    // MARK: - Insert and Fetch Round-Trips

    func testHandbookChapterCanBeInsertedAndFetched() throws {
        let container = try makeFullSchemaContainer()
        let context = container.mainContext
        let chapterID = UUID()

        let chapter = PersistedHandbookChapter(
            id: chapterID,
            slug: "test-chapter",
            title: "Test Chapter",
            summary: "A test chapter summary.",
            sortOrder: 1,
            tagsJSON: "[]",
            version: 1,
            isSeeded: true,
            lastReviewedAt: nil
        )
        context.insert(chapter)
        try context.save()

        let descriptor = FetchDescriptor<PersistedHandbookChapter>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, chapterID)
        XCTAssertEqual(fetched.first?.slug, "test-chapter")
        XCTAssertEqual(fetched.first?.title, "Test Chapter")
    }

    func testInventoryItemCanBeInsertedAndFetched() throws {
        let container = try makeFullSchemaContainer()
        let context = container.mainContext
        let itemID = UUID()
        let now = Date()

        let item = PersistedInventoryItem(
            id: itemID,
            name: "Flashlight",
            categoryRawValue: InventoryCategory.lighting.rawValue,
            quantity: 2,
            unit: "units",
            location: "Garage shelf",
            notes: "LED, waterproof",
            expiryDate: nil,
            reorderThreshold: 1,
            tagsJSON: "[]",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<PersistedInventoryItem>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, itemID)
        XCTAssertEqual(fetched.first?.name, "Flashlight")
        XCTAssertEqual(fetched.first?.quantity, 2)
    }

    func testNoteRecordCanBeInsertedAndFetched() throws {
        let container = try makeFullSchemaContainer()
        let context = container.mainContext
        let noteID = UUID()
        let now = Date()

        let note = PersistedNoteRecord(
            id: noteID,
            title: "Emergency Contacts",
            bodyMarkdown: "Call 911 first.",
            plainText: "Call 911 first.",
            noteTypeRawValue: NoteType.personal.rawValue,
            tagsJSON: "[]",
            linkedSectionIDsJSON: "[]",
            linkedInventoryItemIDsJSON: "[]",
            createdAt: now,
            updatedAt: now
        )
        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<PersistedNoteRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, noteID)
        XCTAssertEqual(fetched.first?.title, "Emergency Contacts")
    }

    func testSeedContentStateCanBeWrittenAndReadBack() throws {
        let container = try makeFullSchemaContainer()
        let context = container.mainContext
        let appliedAt = Date(timeIntervalSince1970: 1_742_601_600)

        let state = PersistedSeedContentState(
            schemaVersion: 1,
            contentPackVersion: "0.1.0",
            appliedAt: appliedAt
        )
        context.insert(state)
        try context.save()

        let descriptor = FetchDescriptor<PersistedSeedContentState>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)

        let record = try XCTUnwrap(fetched.first)
        XCTAssertEqual(record.identifier, PersistedSeedContentState.singletonIdentifier)
        XCTAssertEqual(record.schemaVersion, 1)
        XCTAssertEqual(record.contentPackVersion, "0.1.0")
        XCTAssertEqual(record.appliedAt, appliedAt)
    }

    // MARK: - Idempotent Container Creation

    func testContainerCreationIsIdempotent() throws {
        let container1 = try makeFullSchemaContainer()
        let context1 = container1.mainContext
        let now = Date()

        let item = PersistedInventoryItem(
            id: UUID(),
            name: "Canteen",
            categoryRawValue: InventoryCategory.water.rawValue,
            quantity: 1,
            unit: "units",
            location: "Pantry",
            notes: "",
            expiryDate: nil,
            reorderThreshold: nil,
            tagsJSON: "[]",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        context1.insert(item)
        try context1.save()

        // Creating a second in-memory container does not affect the first.
        let container2 = try makeFullSchemaContainer()
        let context2 = container2.mainContext

        // The second container is a fresh in-memory store; verify it is empty.
        let itemsInSecond = try context2.fetch(FetchDescriptor<PersistedInventoryItem>())
        XCTAssertEqual(itemsInSecond.count, 0, "New in-memory container should start empty")

        // The original container's data should remain intact.
        let itemsInFirst = try context1.fetch(FetchDescriptor<PersistedInventoryItem>())
        XCTAssertEqual(itemsInFirst.count, 1, "Original container data must not be corrupted")
        XCTAssertEqual(itemsInFirst.first?.name, "Canteen")
    }

    // MARK: - Helpers

    private func makeFullSchemaContainer() throws -> ModelContainer {
        let schema = Schema(Self.allModelTypes)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
