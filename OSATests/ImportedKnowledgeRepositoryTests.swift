import SwiftData
import XCTest
@testable import OSA

@MainActor
final class ImportedKnowledgeRepositoryTests: XCTestCase {

    /// Returns a shared container and repository pair.
    /// Each test that mutates data gets a fresh in-memory store because
    /// `isStoredInMemoryOnly` containers do not persist across container instances.
    /// However, to avoid repeated container creation crashes observed with
    /// SwiftData in the simulator test host, we create the container once per test class.
    private static var sharedContainer: ModelContainer = {
        let schema = Schema([
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
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    private func makeRepository() -> SwiftDataImportedKnowledgeRepository {
        SwiftDataImportedKnowledgeRepository(modelContext: Self.sharedContainer.mainContext)
    }

    /// Removes all persisted source records and associated documents/chunks between tests.
    private func cleanStore() throws {
        let context = Self.sharedContainer.mainContext
        let sources = try context.fetch(FetchDescriptor<PersistedSourceRecord>())
        for source in sources { context.delete(source) }
        let docs = try context.fetch(FetchDescriptor<PersistedImportedKnowledgeDocument>())
        for doc in docs { context.delete(doc) }
        let chunks = try context.fetch(FetchDescriptor<PersistedKnowledgeChunk>())
        for chunk in chunks { context.delete(chunk) }
        try context.save()
    }

    // MARK: - SourceRecord Tests

    func testCreateAndListSources() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Ready.gov", trustLevel: .curated)
        try repository.createSource(source)

        let sources = try repository.listSources(trustLevel: nil)
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.sourceTitle, "Ready.gov")
        XCTAssertEqual(sources.first?.trustLevel, .curated)
    }

    func testSourceByID() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "FEMA Guide")
        try repository.createSource(source)

        let fetched = try XCTUnwrap(repository.source(id: source.id))
        XCTAssertEqual(fetched.sourceTitle, "FEMA Guide")
    }

    func testSourceByIDReturnsNilForUnknownID() throws {
        try cleanStore()
        let repository = makeRepository()

        let result = try repository.source(id: UUID())
        XCTAssertNil(result)
    }

    func testSourceByURL() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Ready.gov", url: "https://www.ready.gov/kit")
        try repository.createSource(source)

        let fetched = try XCTUnwrap(repository.source(url: "https://www.ready.gov/kit"))
        XCTAssertEqual(fetched.sourceTitle, "Ready.gov")
    }

    func testSourceByURLReturnsNilForUnknownURL() throws {
        try cleanStore()
        let repository = makeRepository()

        let result = try repository.source(url: "https://nonexistent.example.com")
        XCTAssertNil(result)
    }

    func testUpdateSource() throws {
        try cleanStore()
        let repository = makeRepository()

        var source = makeSource(title: "Draft Source", reviewStatus: .pending)
        try repository.createSource(source)

        source.sourceTitle = "Approved Source"
        source.reviewStatus = .approved
        try repository.updateSource(source)

        let fetched = try XCTUnwrap(repository.source(id: source.id))
        XCTAssertEqual(fetched.sourceTitle, "Approved Source")
        XCTAssertEqual(fetched.reviewStatus, .approved)
    }

    func testDeleteSource() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "To Delete")
        try repository.createSource(source)

        try repository.deleteSource(id: source.id)

        let sources = try repository.listSources(trustLevel: nil)
        XCTAssertTrue(sources.isEmpty)
    }

    func testListSourcesFilteredByTrustLevel() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createSource(makeSource(title: "Curated", trustLevel: .curated))
        try repository.createSource(makeSource(title: "Community", trustLevel: .community))
        try repository.createSource(makeSource(title: "Unverified", trustLevel: .unverified))

        let curated = try repository.listSources(trustLevel: .curated)
        XCTAssertEqual(curated.count, 1)
        XCTAssertEqual(curated.first?.sourceTitle, "Curated")

        let community = try repository.listSources(trustLevel: .community)
        XCTAssertEqual(community.count, 1)
        XCTAssertEqual(community.first?.sourceTitle, "Community")
    }

    func testActiveSources() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createSource(makeSource(title: "Active", isActive: true))
        try repository.createSource(makeSource(title: "Inactive", isActive: false))

        let active = try repository.activeSources()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.sourceTitle, "Active")
    }

    func testStaleSources() throws {
        try cleanStore()
        let repository = makeRepository()

        let pastDate = Date(timeIntervalSince1970: 1_000_000)
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365)

        try repository.createSource(makeSource(title: "Stale", staleAfter: pastDate))
        try repository.createSource(makeSource(title: "Fresh", staleAfter: futureDate))

        let stale = try repository.staleSources(asOf: Date())
        XCTAssertEqual(stale.count, 1)
        XCTAssertEqual(stale.first?.sourceTitle, "Stale")
    }

    func testSourceTagsRoundTrip() throws {
        try cleanStore()
        let repository = makeRepository()

        let tags = ["survival", "water-purification", "pnw"]
        let source = makeSource(title: "Tagged", tags: tags)
        try repository.createSource(source)

        let fetched = try XCTUnwrap(repository.source(id: source.id))
        XCTAssertEqual(fetched.tags, tags)
    }

    func testSourceLocalChunkIDsRoundTrip() throws {
        try cleanStore()
        let repository = makeRepository()

        let chunkIDs = [UUID(), UUID(), UUID()]
        let source = makeSource(title: "With Chunks", localChunkIDs: chunkIDs)
        try repository.createSource(source)

        let fetched = try XCTUnwrap(repository.source(id: source.id))
        XCTAssertEqual(fetched.localChunkIDs, chunkIDs)
    }

    // MARK: - ImportedKnowledgeDocument Tests

    func testCreateAndListDocuments() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        let doc = makeDocument(sourceID: source.id, title: "Water Purification Guide")
        try repository.createDocument(doc)

        let docs = try repository.listDocuments(sourceID: source.id)
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs.first?.title, "Water Purification Guide")
    }

    func testDocumentByID() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        let doc = makeDocument(sourceID: source.id, title: "Emergency Supplies")
        try repository.createDocument(doc)

        let fetched = try XCTUnwrap(repository.document(id: doc.id))
        XCTAssertEqual(fetched.title, "Emergency Supplies")
        XCTAssertEqual(fetched.sourceID, source.id)
    }

    func testDocumentByIDReturnsNilForUnknownID() throws {
        try cleanStore()
        let repository = makeRepository()

        let result = try repository.document(id: UUID())
        XCTAssertNil(result)
    }

    func testUpdateDocument() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        var doc = makeDocument(sourceID: source.id, title: "Draft")
        try repository.createDocument(doc)

        doc.title = "Final Version"
        doc.versionHash = "updated-hash"
        try repository.updateDocument(doc)

        let fetched = try XCTUnwrap(repository.document(id: doc.id))
        XCTAssertEqual(fetched.title, "Final Version")
        XCTAssertEqual(fetched.versionHash, "updated-hash")
    }

    func testDeleteDocument() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        let doc = makeDocument(sourceID: source.id, title: "To Delete")
        try repository.createDocument(doc)

        try repository.deleteDocument(id: doc.id)
        let result = try repository.document(id: doc.id)
        XCTAssertNil(result)
    }

    func testDocumentSupersedesRoundTrip() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        let oldDocID = UUID()
        let doc = makeDocument(sourceID: source.id, title: "V2", supersedesDocumentID: oldDocID)
        try repository.createDocument(doc)

        let fetched = try XCTUnwrap(repository.document(id: doc.id))
        XCTAssertEqual(fetched.supersedesDocumentID, oldDocID)
    }

    // MARK: - KnowledgeChunk Tests

    func testCreateAndListChunks() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        let chunk = makeChunk(documentID: doc.id, headingPath: "Water > Purification", sortOrder: 0)
        try repository.createChunk(chunk)

        let chunks = try repository.listChunks(documentID: doc.id)
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks.first?.headingPath, "Water > Purification")
    }

    func testChunkByID() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        let chunk = makeChunk(documentID: doc.id, headingPath: "Shelter")
        try repository.createChunk(chunk)

        let fetched = try XCTUnwrap(repository.chunk(id: chunk.id))
        XCTAssertEqual(fetched.headingPath, "Shelter")
    }

    func testChunkByIDReturnsNilForUnknownID() throws {
        try cleanStore()
        let repository = makeRepository()

        let result = try repository.chunk(id: UUID())
        XCTAssertNil(result)
    }

    func testCreateChunksBatch() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        let chunks = (0..<3).map { index in
            makeChunk(documentID: doc.id, headingPath: "Section \(index)", sortOrder: index)
        }
        try repository.createChunks(chunks)

        let fetched = try repository.listChunks(documentID: doc.id)
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched.map(\.sortOrder), [0, 1, 2])
    }

    func testDeleteChunksByDocumentID() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "A", sortOrder: 0))
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "B", sortOrder: 1))

        try repository.deleteChunks(documentID: doc.id)

        let remaining = try repository.listChunks(documentID: doc.id)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testSearchableChunks() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Searchable", isSearchable: true))
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Not Searchable", isSearchable: false))

        let searchable = try repository.searchableChunks()
        XCTAssertEqual(searchable.count, 1)
        XCTAssertEqual(searchable.first?.headingPath, "Searchable")
    }

    func testChunkTagsRoundTrip() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        let tags = ["water", "safety", "purification"]
        let chunk = makeChunk(documentID: doc.id, headingPath: "Tagged", tags: tags)
        try repository.createChunk(chunk)

        let fetched = try XCTUnwrap(repository.chunk(id: chunk.id))
        XCTAssertEqual(fetched.tags, tags)
    }

    func testChunksOrderedBySortOrder() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)
        let doc = makeDocument(sourceID: source.id, title: "Doc")
        try repository.createDocument(doc)

        // Insert out of order to verify sorting
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Third", sortOrder: 2))
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "First", sortOrder: 0))
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Second", sortOrder: 1))

        let fetched = try repository.listChunks(documentID: doc.id)
        XCTAssertEqual(fetched.map(\.headingPath), ["First", "Second", "Third"])
    }

    // MARK: - Cascade Delete Tests

    func testDeleteSourceCascadesToDocumentsAndChunks() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Cascade Source")
        try repository.createSource(source)

        let doc = makeDocument(sourceID: source.id, title: "Cascade Doc")
        try repository.createDocument(doc)

        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Cascade Chunk"))

        try repository.deleteSource(id: source.id)

        let docs = try repository.listDocuments(sourceID: source.id)
        XCTAssertTrue(docs.isEmpty)

        let chunks = try repository.listChunks(documentID: doc.id)
        XCTAssertTrue(chunks.isEmpty)
    }

    func testDeleteDocumentCascadesToChunks() throws {
        try cleanStore()
        let repository = makeRepository()

        let source = makeSource(title: "Source")
        try repository.createSource(source)

        let doc = makeDocument(sourceID: source.id, title: "Doc with Chunks")
        try repository.createDocument(doc)

        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Chunk 1"))
        try repository.createChunk(makeChunk(documentID: doc.id, headingPath: "Chunk 2"))

        try repository.deleteDocument(id: doc.id)

        let chunks = try repository.listChunks(documentID: doc.id)
        XCTAssertTrue(chunks.isEmpty)
    }

    // MARK: - Helpers

    private func makeSource(
        title: String,
        url: String = "https://example.com",
        trustLevel: TrustLevel = .curated,
        reviewStatus: ReviewStatus = .approved,
        tags: [String] = [],
        localChunkIDs: [UUID] = [],
        isActive: Bool = true,
        staleAfter: Date = Date(timeIntervalSinceNow: 86400 * 30)
    ) -> SourceRecord {
        let now = Date()
        return SourceRecord(
            id: UUID(),
            sourceTitle: title,
            sourceURL: url,
            publisherDomain: "example.com",
            publisherName: "Example Publisher",
            fetchedAt: now,
            lastReviewedAt: now,
            contentHash: UUID().uuidString,
            trustLevel: trustLevel,
            tags: tags,
            localChunkIDs: localChunkIDs,
            reviewStatus: reviewStatus,
            licenseSummary: nil,
            isActive: isActive,
            staleAfter: staleAfter
        )
    }

    private func makeDocument(
        sourceID: UUID,
        title: String,
        documentType: DocumentType = .article,
        supersedesDocumentID: UUID? = nil
    ) -> ImportedKnowledgeDocument {
        ImportedKnowledgeDocument(
            id: UUID(),
            sourceID: sourceID,
            title: title,
            normalizedMarkdown: "# \(title)\n\nTest content.",
            plainText: "\(title) Test content.",
            documentType: documentType,
            versionHash: UUID().uuidString,
            importedAt: Date(),
            supersedesDocumentID: supersedesDocumentID
        )
    }

    private func makeChunk(
        documentID: UUID,
        headingPath: String,
        sortOrder: Int = 0,
        tags: [String] = [],
        isSearchable: Bool = true
    ) -> KnowledgeChunk {
        KnowledgeChunk(
            id: UUID(),
            documentID: documentID,
            localChunkID: UUID(),
            headingPath: headingPath,
            plainText: "Chunk text for \(headingPath)",
            sortOrder: sortOrder,
            tokenEstimate: 50,
            tags: tags,
            trustLevel: .curated,
            contentHash: UUID().uuidString,
            isSearchable: isSearchable
        )
    }
}
