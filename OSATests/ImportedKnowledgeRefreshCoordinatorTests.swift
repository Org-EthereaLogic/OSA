import Foundation
import Testing
@testable import OSA

// MARK: - Fakes

private final class FakeImportedKnowledgeRepository: ImportedKnowledgeRepository {
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

private final class FakePendingOperationRepository: PendingOperationRepository {
    var operations: [PendingOperation] = []

    func listOperations(status: OperationStatus?) throws -> [PendingOperation] {
        if let status { return operations.filter { $0.status == status } }
        return operations
    }
    func operation(id: UUID) throws -> PendingOperation? { operations.first { $0.id == id } }
    func createOperation(_ op: PendingOperation) throws { operations.append(op) }
    func updateOperation(_ op: PendingOperation) throws {
        if let idx = operations.firstIndex(where: { $0.id == op.id }) { operations[idx] = op }
    }
    func deleteOperation(id: UUID) throws { operations.removeAll { $0.id == id } }
    func nextQueued() throws -> PendingOperation? {
        operations.filter { $0.status == .queued }.sorted(by: { $0.createdAt < $1.createdAt }).first
    }
    func failedOperations(maxRetries: Int) throws -> [PendingOperation] {
        operations.filter { $0.status == .failed && $0.retryCount < maxRetries }
    }
    func purgeCompleted() throws {
        operations.removeAll { $0.status == .completed }
    }
}

private final class FakeConnectivityService: ConnectivityService, @unchecked Sendable {
    @MainActor var currentState: ConnectivityState = .onlineUsable
    private var continuations: [AsyncStream<ConnectivityState>.Continuation] = []

    @MainActor func stateStream() -> AsyncStream<ConnectivityState> {
        // Return a stream that finishes immediately — the coordinator's
        // initial catch-up pass handles the current state already.
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func start() {}
    func stop() {}
    @MainActor func setSyncInProgress() {}
    @MainActor func clearSyncInProgress() {}
}

private final class FakeHTTPClient: TrustedSourceHTTPClient, @unchecked Sendable {
    var responseProvider: ((URL) throws -> TrustedSourceFetchResponse)?
    var fetchCallCount = 0

    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        fetchCallCount += 1
        guard let provider = responseProvider else {
            throw TrustedSourceFetchError.offline
        }
        return try provider(url)
    }
}

// MARK: - Helpers

private func makeStaleApprovedSource(id: UUID = UUID(), url: String = "https://www.ready.gov/water") -> SourceRecord {
    SourceRecord(
        id: id,
        sourceTitle: "Water Guide",
        sourceURL: url,
        publisherDomain: "www.ready.gov",
        publisherName: "Ready.gov",
        fetchedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60), // 60 days ago
        lastReviewedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60),
        contentHash: "abc123",
        trustLevel: .curated,
        tags: [],
        localChunkIDs: [],
        reviewStatus: .approved,
        licenseSummary: nil,
        isActive: true,
        staleAfter: Date().addingTimeInterval(-30 * 24 * 60 * 60) // stale 30 days ago
    )
}

private func makePendingSource(id: UUID = UUID()) -> SourceRecord {
    SourceRecord(
        id: id,
        sourceTitle: "Pending Source",
        sourceURL: "https://mountainhouse.com/blog",
        publisherDomain: "mountainhouse.com",
        publisherName: "Mountain House",
        fetchedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60),
        lastReviewedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60),
        contentHash: "def456",
        trustLevel: .unverified,
        tags: [],
        localChunkIDs: [],
        reviewStatus: .pending,
        licenseSummary: nil,
        isActive: true,
        staleAfter: Date().addingTimeInterval(-30 * 24 * 60 * 60)
    )
}

private func makeFetchResponse(url: URL) -> TrustedSourceFetchResponse {
    TrustedSourceFetchResponse(
        requestedURL: url,
        finalURL: url,
        httpStatusCode: 200,
        contentType: "text/html",
        body: Data("<html><head><title>Water Guide</title></head><body><p>Updated water storage information.</p></body></html>".utf8),
        fetchedAt: Date()
    )
}

// MARK: - Tests

@Suite("ImportedKnowledgeRefreshCoordinator", .serialized)
struct ImportedKnowledgeRefreshCoordinatorTests {

    @Test("Startup enqueues and refreshes one approved stale source")
    func startupEnqueuesStaleSource() async {
        let sourceID = UUID()
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makeStaleApprovedSource(id: sourceID)]

        let opsRepo = FakePendingOperationRepository()
        let connectivity = FakeConnectivityService()
        let httpClient = FakeHTTPClient()
        httpClient.responseProvider = { url in makeFetchResponse(url: url) }

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()

        #expect(httpClient.fetchCallCount == 1)
    }

    @Test("Pending source is not enqueued automatically")
    func pendingSourceNotEnqueued() async {
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makePendingSource()]

        let opsRepo = FakePendingOperationRepository()
        let connectivity = FakeConnectivityService()
        let httpClient = FakeHTTPClient()

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()

        #expect(httpClient.fetchCallCount == 0)
        let queued = opsRepo.operations.filter { $0.operationType == .refreshKnownSource }
        #expect(queued.isEmpty)
    }

    @Test("Offline connectivity prevents queue execution")
    func offlinePreventsExecution() async {
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makeStaleApprovedSource()]

        let opsRepo = FakePendingOperationRepository()
        let connectivity = FakeConnectivityService()
        await MainActor.run { connectivity.currentState = .offline }
        let httpClient = FakeHTTPClient()

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()

        #expect(httpClient.fetchCallCount == 0)
        // Operations should be enqueued but not processed
        let queued = opsRepo.operations.filter { $0.status == .queued }
        #expect(!queued.isEmpty)
    }

    @Test("Failure marks operation failed with retry count and lastError")
    func failureMarksOperationFailed() async {
        let sourceID = UUID()
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makeStaleApprovedSource(id: sourceID)]

        let opsRepo = FakePendingOperationRepository()
        let connectivity = FakeConnectivityService()
        let httpClient = FakeHTTPClient()
        httpClient.responseProvider = { _ in throw TrustedSourceFetchError.offline }

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()

        let failed = opsRepo.operations.filter { $0.status == .failed }
        #expect(failed.count == 1)
        #expect(failed.first?.retryCount == 1)
        #expect(failed.first?.lastError != nil)
    }

    @Test("start() is idempotent")
    func startIsIdempotent() async {
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makeStaleApprovedSource()]

        let opsRepo = FakePendingOperationRepository()
        let connectivity = FakeConnectivityService()
        let httpClient = FakeHTTPClient()
        httpClient.responseProvider = { url in makeFetchResponse(url: url) }

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()
        await coordinator.start() // second call should be no-op

        #expect(httpClient.fetchCallCount == 1)
    }

    @Test("Duplicate stale sources are not double-enqueued")
    func noDuplicateEnqueue() async {
        let sourceID = UUID()
        let knowledgeRepo = FakeImportedKnowledgeRepository()
        knowledgeRepo.sources = [makeStaleApprovedSource(id: sourceID)]

        let opsRepo = FakePendingOperationRepository()
        // Pre-enqueue an existing operation for this source
        let existingOp = PendingOperation(
            id: UUID(),
            operationType: .refreshKnownSource,
            status: .queued,
            payloadReference: sourceID.uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            retryCount: 0,
            lastError: nil
        )
        try! opsRepo.createOperation(existingOp)

        let connectivity = FakeConnectivityService()
        let httpClient = FakeHTTPClient()
        httpClient.responseProvider = { url in makeFetchResponse(url: url) }

        let pipeline = ImportedKnowledgeImportPipeline(
            repository: knowledgeRepo,
            searchService: nil
        )

        let coordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: knowledgeRepo,
            pendingOperationRepository: opsRepo,
            connectivityService: connectivity,
            httpClient: httpClient,
            importPipeline: pipeline
        )

        await coordinator.start()

        // Should have processed the existing operation exactly once, not created a duplicate
        #expect(httpClient.fetchCallCount == 1)
    }
}
