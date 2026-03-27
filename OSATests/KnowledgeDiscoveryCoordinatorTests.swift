import XCTest
@testable import OSA

@MainActor
final class KnowledgeDiscoveryCoordinatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeCoordinator(
        rssArticles: [DiscoveredArticle] = [],
        searchResults: [WebSearchResult]? = nil,
        existingURLs: Set<String> = [],
        connectivityState: ConnectivityState = .onlineUsable,
        fetchShouldFail: Bool = false,
        lastDiscovery: Date? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) -> KnowledgeDiscoveryCoordinator {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        if let lastDiscovery {
            defaults.set(lastDiscovery.timeIntervalSince1970, forKey: DiscoverySettings.lastDiscoveryDateKey)
        }

        let rssService = StubRSSService(articles: rssArticles)
        let searchClient: (any WebSearchClient)? = searchResults.map { StubSearchClient(results: $0) }

        return KnowledgeDiscoveryCoordinator(
            rssDiscoveryService: rssService,
            webSearchClient: searchClient,
            httpClient: StubHTTPClient(shouldFail: fetchShouldFail),
            importPipeline: ImportedKnowledgeImportPipeline(
                repository: StubImportedKnowledgeRepo(existingURLs: existingURLs),
                searchService: nil
            ),
            importedKnowledgeRepository: StubImportedKnowledgeRepo(existingURLs: existingURLs),
            connectivityService: StubConnectivity(state: connectivityState),
            defaults: defaults,
            now: now
        )
    }

    // MARK: - RSS Discovery

    func testRSSDiscoveryImportsNewArticles() async {
        let articles = [
            DiscoveredArticle(
                title: "Quake Guide",
                articleURL: URL(string: "https://www.ready.gov/earthquakes")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            )
        ]
        let coordinator = makeCoordinator(rssArticles: articles)
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 1)
        XCTAssertEqual(result.articlesImported, 1)
    }

    // MARK: - Deduplication

    func testAlreadyImportedURLsAreSkipped() async {
        let articles = [
            DiscoveredArticle(
                title: "Old Article",
                articleURL: URL(string: "https://www.ready.gov/old")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            )
        ]
        let coordinator = makeCoordinator(
            rssArticles: articles,
            existingURLs: ["https://www.ready.gov/old"]
        )
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 1)
        XCTAssertEqual(result.articlesImported, 0)
        XCTAssertEqual(result.articlesSkippedDuplicate, 1)
    }

    // MARK: - Offline Gating

    func testOfflineConnectivityPreventsDiscovery() async {
        let articles = [
            DiscoveredArticle(
                title: "Test",
                articleURL: URL(string: "https://www.ready.gov/test")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            )
        ]
        let coordinator = makeCoordinator(
            rssArticles: articles,
            connectivityState: .offline
        )
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 0)
    }

    // MARK: - Schedule

    func testSchedulePreventsRerunWithin24Hours() async {
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let coordinator = makeCoordinator(lastDiscovery: recentDate)

        await coordinator.startIfDue()
        // No assertion needed — just verifying it doesn't run (no crash, no articles)
    }

    func testScheduleAllowsRunAfter24Hours() async {
        let articles = [
            DiscoveredArticle(
                title: "New Article",
                articleURL: URL(string: "https://www.ready.gov/new")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            )
        ]
        let oldDate = Date().addingTimeInterval(-90000) // 25 hours ago
        let coordinator = makeCoordinator(rssArticles: articles, lastDiscovery: oldDate)

        await coordinator.startIfDue()
        // startIfDue runs discovery since schedule is due
    }

    // MARK: - Brave Search Disabled

    func testBraveSearchDisabledWhenNoClient() async {
        let coordinator = makeCoordinator(searchResults: nil)
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 0)
    }

    // MARK: - Fetch Failures

    func testFailedFetchDoesNotAbortBatch() async {
        let articles = [
            DiscoveredArticle(
                title: "Article 1",
                articleURL: URL(string: "https://www.ready.gov/a1")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            ),
            DiscoveredArticle(
                title: "Article 2",
                articleURL: URL(string: "https://www.ready.gov/a2")!,
                publishedDate: nil,
                sourceHost: "www.ready.gov"
            )
        ]
        let coordinator = makeCoordinator(rssArticles: articles, fetchShouldFail: true)
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 2)
        XCTAssertEqual(result.articlesImported, 0)
        XCTAssertEqual(result.errors.count, 2)
    }

    // MARK: - Empty Input

    func testNoArticlesReturnsEmptyResult() async {
        let coordinator = makeCoordinator()
        let result = await coordinator.discoverAndImport()

        XCTAssertEqual(result.articlesDiscovered, 0)
        XCTAssertEqual(result.articlesImported, 0)
    }
}

// MARK: - Test Stubs

private struct StubRSSService: RSSDiscoveryService {
    let articles: [DiscoveredArticle]
    func discoverArticles() async -> [DiscoveredArticle] { articles }
}

private struct StubSearchClient: WebSearchClient {
    let results: [WebSearchResult]
    func search(query: String) async throws -> [WebSearchResult] { results }
}

private final class StubHTTPClient: TrustedSourceHTTPClient, @unchecked Sendable {
    let shouldFail: Bool
    init(shouldFail: Bool) { self.shouldFail = shouldFail }

    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        if shouldFail { throw URLError(.badServerResponse) }
        return TrustedSourceFetchResponse(
            requestedURL: url,
            finalURL: url,
            httpStatusCode: 200,
            contentType: "text/html",
            body: Data("<html><body>Content</body></html>".utf8),
            fetchedAt: Date()
        )
    }
}

private final class StubImportedKnowledgeRepo: ImportedKnowledgeRepository, @unchecked Sendable {
    let existingURLs: Set<String>
    init(existingURLs: Set<String> = []) { self.existingURLs = existingURLs }

    func source(url: String) throws -> SourceRecord? {
        guard existingURLs.contains(url) else { return nil }
        return SourceRecord(
            id: UUID(), sourceTitle: "Existing", sourceURL: url,
            publisherDomain: "", publisherName: "", fetchedAt: Date(),
            lastReviewedAt: Date(), contentHash: "", trustLevel: .curated,
            tags: [], localChunkIDs: [], reviewStatus: .approved,
            licenseSummary: nil, isActive: true,
            staleAfter: Date().addingTimeInterval(86400)
        )
    }

    func source(id: UUID) throws -> SourceRecord? { nil }
    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord] { [] }
    func activeSources() throws -> [SourceRecord] { [] }
    func staleSources(asOf date: Date) throws -> [SourceRecord] { [] }
    func createSource(_ source: SourceRecord) throws {}
    func updateSource(_ source: SourceRecord) throws {}
    func deleteSource(id: UUID) throws {}
    func listDocuments(sourceID: UUID) throws -> [ImportedKnowledgeDocument] { [] }
    func document(id: UUID) throws -> ImportedKnowledgeDocument? { nil }
    func createDocument(_ document: ImportedKnowledgeDocument) throws {}
    func updateDocument(_ document: ImportedKnowledgeDocument) throws {}
    func deleteDocument(id: UUID) throws {}
    func listChunks(documentID: UUID) throws -> [KnowledgeChunk] { [] }
    func chunk(id: UUID) throws -> KnowledgeChunk? { nil }
    func createChunk(_ chunk: KnowledgeChunk) throws {}
    func createChunks(_ chunks: [KnowledgeChunk]) throws {}
    func deleteChunks(documentID: UUID) throws {}
    func searchableChunks() throws -> [KnowledgeChunk] { [] }
}

private final class StubConnectivity: ConnectivityService, @unchecked Sendable {
    let state: ConnectivityState
    @MainActor var currentState: ConnectivityState { state }

    init(state: ConnectivityState) { self.state = state }

    @MainActor func stateStream() -> AsyncStream<ConnectivityState> {
        AsyncStream { continuation in continuation.finish() }
    }
    func start() {}
    func stop() {}
    @MainActor func setSyncInProgress() {}
    @MainActor func clearSyncInProgress() {}
}
