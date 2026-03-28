import Foundation
import Testing
@testable import OSA

// MARK: - In-Memory Repository

private final class InMemoryImportedKnowledgeRepository: ImportedKnowledgeRepository {
    var sources: [SourceRecord] = []
    var documents: [ImportedKnowledgeDocument] = []
    var chunks: [KnowledgeChunk] = []

    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord] {
        if let level = trustLevel { return sources.filter { $0.trustLevel == level } }
        return sources
    }
    func source(id: UUID) throws -> SourceRecord? { sources.first { $0.id == id } }
    func source(url: String) throws -> SourceRecord? { sources.first { $0.sourceURL == url } }
    func createSource(_ source: SourceRecord) throws { sources.append(source) }
    func updateSource(_ source: SourceRecord) throws {
        if let idx = sources.firstIndex(where: { $0.id == source.id }) { sources[idx] = source }
    }
    func deleteSource(id: UUID) throws { sources.removeAll { $0.id == id } }
    func activeSources() throws -> [SourceRecord] { sources.filter(\.isActive) }
    func staleSources(asOf date: Date) throws -> [SourceRecord] { sources.filter { $0.staleAfter < date } }

    func listDocuments(sourceID: UUID) throws -> [ImportedKnowledgeDocument] {
        documents.filter { $0.sourceID == sourceID }
    }
    func document(id: UUID) throws -> ImportedKnowledgeDocument? { documents.first { $0.id == id } }
    func createDocument(_ document: ImportedKnowledgeDocument) throws { documents.append(document) }
    func updateDocument(_ document: ImportedKnowledgeDocument) throws {
        if let idx = documents.firstIndex(where: { $0.id == document.id }) { documents[idx] = document }
    }
    func deleteDocument(id: UUID) throws { documents.removeAll { $0.id == id } }

    func listChunks(documentID: UUID) throws -> [KnowledgeChunk] {
        chunks.filter { $0.documentID == documentID }
    }
    func chunk(id: UUID) throws -> KnowledgeChunk? { chunks.first { $0.id == id } }
    func createChunk(_ chunk: KnowledgeChunk) throws { chunks.append(chunk) }
    func createChunks(_ newChunks: [KnowledgeChunk]) throws { chunks.append(contentsOf: newChunks) }
    func deleteChunks(documentID: UUID) throws { chunks.removeAll { $0.documentID == documentID } }
    func searchableChunks() throws -> [KnowledgeChunk] { chunks.filter(\.isSearchable) }
}

// MARK: - Tracking Search Service

private final class TrackingSearchService: SearchService {
    var indexedChunkIDs: [UUID] = []
    var removedIDs: [UUID] = []

    func search(
        query: String,
        scopes: Set<SearchResultKind>?,
        requiredTags: Set<String>,
        limit: Int
    ) throws -> [SearchResult] { [] }
    func suggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] { [] }
    func recordSuccessfulQuery(_ query: String) throws {}
    func indexAllContent() throws {}
    func indexInventoryItem(_ item: InventoryItem) throws {}
    func indexChecklistTemplate(_ template: ChecklistTemplate) throws {}
    func indexNote(_ note: NoteRecord) throws {}
    func indexHandbookSection(_ section: HandbookSection, chapterTitle: String) throws {}
    func indexQuickCard(_ card: QuickCard) throws {}
    func indexImportedChunk(_ chunk: KnowledgeChunk, sourceTitle: String, publisherDomain: String) throws {
        indexedChunkIDs.append(chunk.id)
    }
    func removeFromIndex(id: UUID) throws {
        removedIDs.append(id)
    }
}

// MARK: - Tests

@Suite("ImportedKnowledgeImportPipeline", .serialized)
struct ImportedKnowledgeImportPipelineTests {

    private func makeResponse(
        body: String = "<html><head><title>Water Storage</title></head><body><p>Store one gallon per person per day.</p></body></html>",
        contentType: String = "text/html",
        url: URL = URL(string: "https://www.ready.gov/water")!
    ) -> TrustedSourceFetchResponse {
        TrustedSourceFetchResponse(
            requestedURL: url,
            finalURL: url,
            httpStatusCode: 200,
            contentType: contentType,
            body: Data(body.utf8),
            fetchedAt: Date()
        )
    }

    // MARK: - First Import

    @Test("First import creates source, document, chunks, and index entries for approved source")
    func firstImportApproved() throws {
        let repo = InMemoryImportedKnowledgeRepository()
        let search = TrackingSearchService()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: search)

        let response = makeResponse()
        let source = try pipeline.importFetchedContent(response)

        #expect(source.trustLevel == .curated)
        #expect(source.reviewStatus == .approved)
        #expect(repo.sources.count == 1)
        #expect(repo.documents.count == 1)
        #expect(!repo.chunks.isEmpty)
        #expect(!search.indexedChunkIDs.isEmpty)
        #expect(search.indexedChunkIDs.count == repo.chunks.count)
    }

    // MARK: - Pending Source

    @Test("Pending source persists locally but does not create index entries")
    func pendingSourceNotIndexed() throws {
        let repo = InMemoryImportedKnowledgeRepository()
        let search = TrackingSearchService()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: search)

        // Use a Tier 3 source
        let url = URL(string: "https://mountainhouse.com/blog/prep")!
        let html = "<html><head><title>Freeze Dried Guide</title></head><body><p>Freeze dried food lasts 25 years.</p></body></html>"
        let response = makeResponse(body: html, url: url)
        let source = try pipeline.importFetchedContent(response)

        #expect(source.trustLevel == .unverified)
        #expect(source.reviewStatus == .pending)
        #expect(repo.sources.count == 1)
        #expect(repo.documents.count == 1)
        #expect(!repo.chunks.isEmpty)
        // Chunks persisted but NOT indexed
        #expect(search.indexedChunkIDs.isEmpty)
        let noneSearchable = repo.chunks.allSatisfy { !$0.isSearchable }
        #expect(noneSearchable)
    }

    // MARK: - Dedupe: Same Hash

    @Test("Same-source same-hash re-import refreshes metadata without duplicating")
    func sameHashDeduplication() throws {
        let repo = InMemoryImportedKnowledgeRepository()
        let search = TrackingSearchService()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: search)

        let response = makeResponse()
        try pipeline.importFetchedContent(response)

        let initialSourceCount = repo.sources.count
        let initialDocCount = repo.documents.count
        let initialChunkCount = repo.chunks.count

        // Re-import same content
        try pipeline.importFetchedContent(response)

        #expect(repo.sources.count == initialSourceCount)
        #expect(repo.documents.count == initialDocCount)
        #expect(repo.chunks.count == initialChunkCount)
    }

    // MARK: - Dedupe: Changed Content

    @Test("Same-source changed-content creates new document version")
    func changedContentNewVersion() throws {
        let repo = InMemoryImportedKnowledgeRepository()
        let search = TrackingSearchService()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: search)

        let url = URL(string: "https://www.ready.gov/water")!
        let response1 = makeResponse(
            body: "<html><head><title>Water V1</title></head><body><p>Version one content.</p></body></html>",
            url: url
        )
        try pipeline.importFetchedContent(response1)

        let firstDocCount = repo.documents.count
        let firstChunkIDs = search.indexedChunkIDs

        let response2 = makeResponse(
            body: "<html><head><title>Water V2</title></head><body><p>Completely different version two content.</p></body></html>",
            url: url
        )
        try pipeline.importFetchedContent(response2)

        // Still one source
        #expect(repo.sources.count == 1)
        // Two documents now
        #expect(repo.documents.count == firstDocCount + 1)
        // New document supersedes old one
        let latestDoc = repo.documents.sorted(by: { $0.importedAt < $1.importedAt }).last
        #expect(latestDoc?.supersedesDocumentID != nil)
        // Old chunks were de-indexed
        #expect(search.removedIDs.count == firstChunkIDs.count)
    }

    // MARK: - Empty Content

    @Test("Import fails for empty normalized content")
    func emptyContentFails() {
        let repo = InMemoryImportedKnowledgeRepository()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: nil)

        let response = makeResponse(body: "   \n  ")
        #expect(throws: ImportPipelineError.self) {
            try pipeline.importFetchedContent(response)
        }
    }

    // MARK: - Source Fields

    @Test("Source record fields are populated correctly")
    func sourceFieldsPopulated() throws {
        let repo = InMemoryImportedKnowledgeRepository()
        let pipeline = ImportedKnowledgeImportPipeline(repository: repo, searchService: nil)

        let response = makeResponse()
        let source = try pipeline.importFetchedContent(response)

        #expect(source.publisherDomain == "www.ready.gov")
        #expect(source.publisherName == "Ready.gov")
        #expect(source.isActive)
        #expect(!source.contentHash.isEmpty)
        #expect(!source.localChunkIDs.isEmpty)
        #expect(source.staleAfter > source.fetchedAt)
    }
}
