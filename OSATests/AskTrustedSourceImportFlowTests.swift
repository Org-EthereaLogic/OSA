import XCTest
@testable import OSA

@MainActor
final class AskTrustedSourceImportFlowTests: XCTestCase {

    // MARK: - URL Validation

    func testEmptyURLReturnsEmpty() {
        let vm = makeViewModel()
        vm.urlText = ""
        XCTAssertEqual(vm.urlValidation, .empty)
    }

    func testMalformedURLReturnsInvalid() {
        let vm = makeViewModel()
        vm.urlText = "not a url at all"
        if case .invalid = vm.urlValidation { } else {
            XCTFail("Expected invalid for malformed URL")
        }
    }

    func testHTTPSchemeRejected() {
        let vm = makeViewModel()
        vm.urlText = "http://www.ready.gov/plan"
        if case .invalid(let reason) = vm.urlValidation {
            XCTAssertTrue(reason.contains("HTTPS"))
        } else {
            XCTFail("Expected invalid for HTTP scheme")
        }
    }

    func testNonAllowlistedHostRejected() {
        let vm = makeViewModel()
        vm.urlText = "https://www.evil-site.com/page"
        if case .invalid(let reason) = vm.urlValidation {
            XCTAssertTrue(reason.contains("not an approved"))
        } else {
            XCTFail("Expected invalid for non-allowlisted host")
        }
    }

    func testPendingHostRejected() {
        let vm = makeViewModel()
        vm.urlText = "https://oregonhazlab.com/data"
        if case .invalid(let reason) = vm.urlValidation {
            XCTAssertTrue(reason.contains("pending review"))
        } else {
            XCTFail("Expected invalid for pending host")
        }
    }

    func testApprovedHostAccepted() {
        let vm = makeViewModel()
        vm.urlText = "https://www.ready.gov/plan"
        if case .valid(let url) = vm.urlValidation {
            XCTAssertEqual(url.host, "www.ready.gov")
        } else {
            XCTFail("Expected valid for approved host")
        }
    }

    // MARK: - Approved Source Filtering

    func testApprovedSourcesExcludePendingSources() {
        let vm = makeViewModel()
        let hosts = vm.approvedSources.map(\.canonicalHost)
        XCTAssertFalse(hosts.contains("oregonhazlab.com"))
        XCTAssertFalse(hosts.contains("mountainhouse.com"))
        XCTAssertFalse(hosts.contains("survivalcommonsense.com"))
    }

    func testApprovedSourcesIncludeAllApprovedHosts() {
        let vm = makeViewModel()
        let hosts = vm.approvedSources.map(\.canonicalHost)
        XCTAssertTrue(hosts.contains("www.ready.gov"))
        XCTAssertTrue(hosts.contains("theprepared.com"))
        XCTAssertTrue(hosts.contains("pnsn.org"))
    }

    func testSearchFilterNarrowsSources() {
        let vm = makeViewModel()
        vm.searchText = "Red Cross"
        XCTAssertEqual(vm.approvedSources.count, 1)
        XCTAssertEqual(vm.approvedSources.first?.canonicalHost, "www.redcross.org")
    }

    func testSearchFilterCaseInsensitive() {
        let vm = makeViewModel()
        vm.searchText = "READY"
        XCTAssertTrue(vm.approvedSources.contains(where: { $0.canonicalHost == "www.ready.gov" }))
    }

    // MARK: - Preview Fetch

    func testFetchPreviewSuccess() async {
        let stub = StubHTTPClient(result: .success(makeFetchResponse()))
        let vm = makeViewModel(httpClient: stub)
        vm.urlText = "https://www.ready.gov/plan"

        await vm.fetchPreview()

        XCTAssertEqual(vm.importState, .previewing)
        XCTAssertNotNil(vm.previewTitle)
        XCTAssertNotNil(vm.previewDomain)
        XCTAssertNotNil(vm.previewExcerpt)
        XCTAssertNil(vm.errorMessage)
    }

    func testFetchPreviewOfflineError() async {
        let stub = StubHTTPClient(result: .failure(TrustedSourceFetchError.offline))
        let vm = makeViewModel(httpClient: stub)
        vm.urlText = "https://www.ready.gov/plan"

        await vm.fetchPreview()

        XCTAssertEqual(vm.importState, .failed)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.errorMessage!.contains("offline"))
    }

    func testFetchPreviewEmptyContentError() async {
        let emptyResponse = TrustedSourceFetchResponse(
            requestedURL: URL(string: "https://www.ready.gov/empty")!,
            finalURL: URL(string: "https://www.ready.gov/empty")!,
            httpStatusCode: 200,
            contentType: "text/plain",
            body: Data(),
            fetchedAt: Date()
        )
        let stub = StubHTTPClient(result: .success(emptyResponse))
        let vm = makeViewModel(httpClient: stub)
        vm.urlText = "https://www.ready.gov/empty"

        await vm.fetchPreview()

        XCTAssertEqual(vm.importState, .failed)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - Import

    func testConfirmImportSuccess() async {
        let stub = StubHTTPClient(result: .success(makeFetchResponse()))
        let pipeline = makeStubPipeline()
        let vm = makeViewModel(httpClient: stub, pipeline: pipeline)
        vm.urlText = "https://www.ready.gov/plan"

        await vm.fetchPreview()
        XCTAssertEqual(vm.importState, .previewing)

        await vm.confirmImport()
        XCTAssertEqual(vm.importState, .succeeded)
    }

    // MARK: - State Reset

    func testResetToSearchClearsState() async {
        let stub = StubHTTPClient(result: .success(makeFetchResponse()))
        let vm = makeViewModel(httpClient: stub)
        vm.urlText = "https://www.ready.gov/plan"
        await vm.fetchPreview()

        vm.resetToSearch()

        XCTAssertEqual(vm.importState, .browsing)
        XCTAssertNil(vm.previewTitle)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Prefill

    func testPrefillHostSetsURLText() {
        let vm = makeViewModel()
        vm.prefillHost("www.ready.gov")
        XCTAssertEqual(vm.urlText, "https://www.ready.gov/")
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        httpClient: any TrustedSourceHTTPClient = StubHTTPClient(result: .failure(.offline)),
        pipeline: ImportedKnowledgeImportPipeline? = nil
    ) -> TrustedSourceImportViewModel {
        TrustedSourceImportViewModel(
            httpClient: httpClient,
            importPipeline: pipeline ?? makeStubPipeline(),
            originalQuery: "earthquake preparedness"
        )
    }

    private func makeStubPipeline() -> ImportedKnowledgeImportPipeline {
        ImportedKnowledgeImportPipeline(
            repository: StubImportedKnowledgeRepository(),
            searchService: nil
        )
    }

    private func makeFetchResponse() -> TrustedSourceFetchResponse {
        let html = "<html><head><title>Ready.gov Plan</title></head><body><p>Make a plan for emergencies. Prepare your family with water, food, and supplies.</p></body></html>"
        return TrustedSourceFetchResponse(
            requestedURL: URL(string: "https://www.ready.gov/plan")!,
            finalURL: URL(string: "https://www.ready.gov/plan")!,
            httpStatusCode: 200,
            contentType: "text/html",
            body: html.data(using: .utf8)!,
            fetchedAt: Date()
        )
    }
}

// MARK: - Stubs

private final class StubHTTPClient: TrustedSourceHTTPClient, @unchecked Sendable {
    let result: Result<TrustedSourceFetchResponse, TrustedSourceFetchError>

    init(result: Result<TrustedSourceFetchResponse, TrustedSourceFetchError>) {
        self.result = result
    }

    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        try result.get()
    }
}

private final class StubImportedKnowledgeRepository: ImportedKnowledgeRepository {
    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord] { [] }
    func source(id: UUID) throws -> SourceRecord? { nil }
    func source(url: String) throws -> SourceRecord? { nil }
    func createSource(_ source: SourceRecord) throws {}
    func updateSource(_ source: SourceRecord) throws {}
    func deleteSource(id: UUID) throws {}
    func activeSources() throws -> [SourceRecord] { [] }
    func staleSources(asOf date: Date) throws -> [SourceRecord] { [] }
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
