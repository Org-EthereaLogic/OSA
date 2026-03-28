import SwiftData
import XCTest
@testable import OSA

/// Validates offline hardening scenarios: container creation resilience,
/// data persistence across container re-creation, repository reads without
/// connectivity, and PendingOperation isolation from search results.
@MainActor
final class OfflineStressTests: XCTestCase {

    // MARK: - Full-Schema Model Types

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
        PersistedEmergencyContact.self,
        PersistedNoteRecord.self,
        PersistedSourceRecord.self,
        PersistedImportedKnowledgeDocument.self,
        PersistedKnowledgeChunk.self,
        PersistedPendingOperation.self,
        PersistedDailyForecast.self,
        PersistedWeatherAlert.self
    ]

    // MARK: - Cold Start

    func testInMemoryContainerCreationSucceeds() throws {
        let container = try makeInMemoryContainer()
        XCTAssertNotNil(container)

        // Verify the container is functional by performing a simple fetch.
        let items = try container.mainContext.fetch(FetchDescriptor<PersistedInventoryItem>())
        XCTAssertEqual(items.count, 0)
    }

    // MARK: - Repeated Container Creation

    func testRepeatedContainerCreationDoesNotCorruptExistingData() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let now = Date()

        // Insert data into the first container.
        let item = PersistedInventoryItem(
            id: UUID(),
            name: "Emergency Radio",
            categoryRawValue: InventoryCategory.communication.rawValue,
            quantity: 1,
            unit: "units",
            location: "Go bag",
            notes: "Battery-powered",
            expiryDate: nil,
            reorderThreshold: nil,
            tagsJSON: "[]",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        context.insert(item)
        try context.save()

        // Create additional containers (simulating repeated cold starts with in-memory stores).
        for _ in 0..<5 {
            let anotherContainer = try makeInMemoryContainer()
            // Each new in-memory container starts empty.
            let count = try anotherContainer.mainContext.fetch(FetchDescriptor<PersistedInventoryItem>()).count
            XCTAssertEqual(count, 0)
        }

        // Original container data must remain intact.
        let surviving = try context.fetch(FetchDescriptor<PersistedInventoryItem>())
        XCTAssertEqual(surviving.count, 1)
        XCTAssertEqual(surviving.first?.name, "Emergency Radio")
    }

    // MARK: - Repository Reads Without Connectivity

    func testRepositoryReadsWorkWithoutConnectivityService() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        // Insert a chapter via the repository.
        let repository = SwiftDataContentRepository(modelContext: context)
        let chapter = HandbookChapter(
            id: UUID(),
            slug: "offline-test",
            title: "Offline Test Chapter",
            summary: "Verifying offline reads.",
            sortOrder: 1,
            tags: [],
            version: 1,
            isSeeded: true,
            lastReviewedAt: nil,
            sections: []
        )
        context.insert(PersistedHandbookChapter(from: chapter))
        try context.save()

        // Read back — no connectivity service involved.
        let chapters = try repository.listChapters()
        XCTAssertEqual(chapters.count, 1)
        XCTAssertEqual(chapters.first?.slug, "offline-test")

        let fetched = try XCTUnwrap(repository.chapter(slug: "offline-test"))
        XCTAssertEqual(fetched.title, "Offline Test Chapter")
    }

    func testInventoryRepositoryReadsWorkWithoutConnectivity() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)
        let now = Date()

        let item = InventoryItem(
            id: UUID(),
            name: "Water Filter",
            category: .water,
            quantity: 2,
            unit: "units",
            location: "Kitchen",
            notes: "",
            expiryDate: nil,
            reorderThreshold: nil,
            tags: [],
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        try repository.createItem(item)

        let items = try repository.listItems(includeArchived: false)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Water Filter")
    }

    func testNoteRepositoryReadsWorkWithoutConnectivity() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
        let now = Date()

        let note = NoteRecord(
            id: UUID(),
            title: "Evacuation Route",
            bodyMarkdown: "Head north on Highway 5.",
            plainText: "Head north on Highway 5.",
            noteType: .familyPlan,
            tags: ["evacuation"],
            linkedSectionIDs: [],
            linkedInventoryItemIDs: [],
            createdAt: now,
            updatedAt: now
        )
        try repository.createNote(note)

        let notes = try repository.listNotes(type: nil)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Evacuation Route")
    }

    // MARK: - Persistent Store Across Container Re-creation

    func testSeedContentStatePersistsAcrossContainerReCreation() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OfflineStressTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("test.store")
        let appliedAt = Date(timeIntervalSince1970: 1_742_601_600)

        // First container: write seed content state.
        do {
            let container = try makePersistentContainer(url: storeURL)
            let context = container.mainContext

            let state = PersistedSeedContentState(
                schemaVersion: 1,
                contentPackVersion: "0.1.0",
                appliedAt: appliedAt
            )
            context.insert(state)
            try context.save()
        }

        // Second container pointing at the same store: data should survive.
        do {
            let container = try makePersistentContainer(url: storeURL)
            let context = container.mainContext

            let states = try context.fetch(FetchDescriptor<PersistedSeedContentState>())
            XCTAssertEqual(states.count, 1)

            let record = try XCTUnwrap(states.first)
            XCTAssertEqual(record.schemaVersion, 1)
            XCTAssertEqual(record.contentPackVersion, "0.1.0")
            XCTAssertEqual(record.appliedAt, appliedAt)
        }
    }

    // MARK: - PendingOperation Isolation

    func testPendingOperationsDoNotLeakIntoSearchResults() throws {
        // Insert a PendingOperation and verify it does not appear when
        // searching via the SearchIndexStore (FTS5 sidecar). The search
        // index only contains entries explicitly indexed; PendingOperation
        // records are never indexed.

        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let now = Date()

        let pending = PersistedPendingOperation(
            id: UUID(),
            operationTypeRawValue: "refresh",
            statusRawValue: "pending",
            payloadReference: "https://example.com/article",
            createdAt: now,
            updatedAt: now,
            retryCount: 0,
            lastError: nil
        )
        context.insert(pending)
        try context.save()

        // Create an in-memory search index and search — nothing should match.
        let store = try SearchIndexStore()
        let service = LocalSearchService(store: store)

        let results = try service.search(query: "refresh", scopes: nil, limit: 10)
        XCTAssertTrue(results.isEmpty, "PendingOperation records must never appear in search results")

        // Also verify the PendingOperation exists in SwiftData.
        let ops = try context.fetch(FetchDescriptor<PersistedPendingOperation>())
        XCTAssertEqual(ops.count, 1)
    }

    // MARK: - Helpers

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(Self.allModelTypes)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makePersistentContainer(url: URL) throws -> ModelContainer {
        let schema = Schema(Self.allModelTypes)
        let configuration = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
