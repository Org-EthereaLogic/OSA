import XCTest
import CoreLocation
@testable import OSA

@MainActor
final class AppEntityQueryTests: XCTestCase {

    // MARK: - Quick Card Query

    func testQuickCardQueryResolvesKnownCard() {
        let card = QuickCard(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            title: "Boil Water Advisory",
            slug: "boil-water",
            category: "Water",
            summary: "Steps to follow during a boil water advisory.",
            bodyMarkdown: "",
            priority: 1,
            relatedSectionIDs: [],
            tags: ["water", "boil"],
            lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
        let deps = makeTestDependencies(
            quickCards: [card],
            searchResults: [SearchResult(id: card.id, kind: .quickCard, title: card.title, snippet: card.summary, score: 1.0, tags: [])]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        let results = resolver.searchQuickCards(query: "boil water")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, card.id)
        XCTAssertEqual(results.first?.title, "Boil Water Advisory")
    }

    // MARK: - Handbook Section Query

    func testHandbookSectionQueryIncludesChapterContext() {
        let sectionID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let chapterID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let section = HandbookSection(
            id: sectionID,
            chapterID: chapterID,
            parentSectionID: nil,
            heading: "Water Purification Methods",
            bodyMarkdown: "",
            plainText: "Boil, filter, or treat water.",
            sortOrder: 0,
            tags: ["water"],
            safetyLevel: .normal,
            chunkGroupID: "water-purification",
            version: 1,
            lastReviewedAt: nil
        )
        let chapter = HandbookChapter(
            id: chapterID,
            slug: "water",
            title: "Water Safety",
            summary: "",
            sortOrder: 0,
            tags: [],
            version: 1,
            isSeeded: true,
            lastReviewedAt: nil,
            sections: [section]
        )
        let deps = makeTestDependencies(
            chapters: [chapter],
            sections: [section],
            searchResults: [SearchResult(id: sectionID, kind: .handbookSection, title: section.heading, snippet: section.plainText, score: 1.0, tags: [])]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        let results = resolver.searchHandbookSections(query: "water purification")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.section.id, sectionID)
        XCTAssertEqual(results.first?.chapterTitle, "Water Safety")

        let entity = HandbookSectionEntity(from: results[0])
        XCTAssertEqual(entity.heading, "Water Purification Methods")
        XCTAssertEqual(entity.chapterTitle, "Water Safety")
    }

    // MARK: - Checklist Template Only

    func testChecklistQueryResolvesTemplatesOnly() {
        let templateID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let template = ChecklistTemplate(
            id: templateID,
            title: "72-Hour Kit",
            slug: "72-hour-kit",
            category: "Emergency",
            description: "Essential supplies for 72 hours.",
            estimatedMinutes: 30,
            tags: ["emergency"],
            sourceType: .seeded,
            lastReviewedAt: nil,
            items: [
                ChecklistTemplateItem(
                    id: UUID(),
                    templateID: templateID,
                    text: "Water",
                    detail: nil,
                    sortOrder: 0,
                    isOptional: false,
                    riskLevel: nil
                )
            ]
        )
        let deps = makeTestDependencies(
            templates: [template],
            searchResults: [SearchResult(id: templateID, kind: .checklistTemplate, title: template.title, snippet: template.description, score: 1.0, tags: [])]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        let results = resolver.searchChecklistTemplates(query: "72 hour")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, templateID)
        XCTAssertEqual(results.first?.title, "72-Hour Kit")
        XCTAssertEqual(results.first?.itemCount, 1)
    }

    // MARK: - Inventory Excludes Archived

    func testInventoryQueryExcludesArchivedItems() {
        let activeID = UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!
        let archivedID = UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!
        let now = Date()
        let activeItem = InventoryItem(
            id: activeID, name: "Water Jug", category: .water,
            quantity: 5, unit: "gallons", location: "Garage", notes: "Secret note",
            expiryDate: nil, reorderThreshold: nil, tags: [], createdAt: now, updatedAt: now, isArchived: false
        )
        let archivedItem = InventoryItem(
            id: archivedID, name: "Old Flashlight", category: .lighting,
            quantity: 1, unit: "each", location: "Closet", notes: "",
            expiryDate: nil, reorderThreshold: nil, tags: [], createdAt: now, updatedAt: now, isArchived: true
        )
        let deps = makeTestDependencies(
            inventoryItems: [activeItem, archivedItem],
            searchResults: [
                SearchResult(id: activeID, kind: .inventoryItem, title: "Water Jug", snippet: "", score: 2.0, tags: []),
                SearchResult(id: archivedID, kind: .inventoryItem, title: "Old Flashlight", snippet: "", score: 1.0, tags: [])
            ]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        let results = resolver.searchInventoryItems(query: "water")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, activeID)

        // ID-based lookup also rejects archived
        XCTAssertNil(resolver.inventoryItem(id: archivedID))
    }

    // MARK: - Stale Hit Handling

    func testStaleSearchHitsAreDropped() {
        let staleID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let deps = makeTestDependencies(
            quickCards: [], // No card exists for the search hit
            searchResults: [SearchResult(id: staleID, kind: .quickCard, title: "Deleted Card", snippet: "", score: 1.0, tags: [])]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        let results = resolver.searchQuickCards(query: "deleted")
        XCTAssertTrue(results.isEmpty, "Stale search hits should be silently dropped")
    }

    // MARK: - ID-Based Resolution Round Trips

    func testIDResolutionRoundTripsHandbookSection() {
        let sectionID = UUID(uuidString: "aaaaaaaa-1111-2222-3333-444444444444")!
        let chapterID = UUID(uuidString: "aaaaaaaa-5555-6666-7777-888888888888")!
        let section = HandbookSection(
            id: sectionID, chapterID: chapterID, parentSectionID: nil,
            heading: "Shelter Basics", bodyMarkdown: "", plainText: "",
            sortOrder: 0, tags: [], safetyLevel: .normal,
            chunkGroupID: "shelter", version: 1, lastReviewedAt: nil
        )
        let chapter = HandbookChapter(
            id: chapterID, slug: "shelter", title: "Shelter",
            summary: "", sortOrder: 0, tags: [], version: 1,
            isSeeded: true, lastReviewedAt: nil, sections: [section]
        )
        let deps = makeTestDependencies(chapters: [chapter], sections: [section])
        let resolver = EntityQueryResolver(dependencies: deps)

        let result = resolver.handbookSection(id: sectionID)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.section.id, sectionID)
    }

    func testIDResolutionRoundTripsQuickCard() {
        let card = QuickCard(
            id: UUID(uuidString: "bbbbbbbb-1111-2222-3333-444444444444")!,
            title: "First Aid", slug: "first-aid", category: "Medical",
            summary: "", bodyMarkdown: "", priority: 1,
            relatedSectionIDs: [], tags: [], lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
        let deps = makeTestDependencies(quickCards: [card])
        let resolver = EntityQueryResolver(dependencies: deps)

        XCTAssertNotNil(resolver.quickCard(id: card.id))
    }

    func testIDResolutionRoundTripsChecklistTemplate() {
        let templateID = UUID(uuidString: "cccccccc-1111-2222-3333-444444444444")!
        let template = ChecklistTemplate(
            id: templateID, title: "Go Bag", slug: "go-bag",
            category: "Emergency", description: "", estimatedMinutes: 15,
            tags: [], sourceType: .seeded, lastReviewedAt: nil, items: []
        )
        let deps = makeTestDependencies(templates: [template])
        let resolver = EntityQueryResolver(dependencies: deps)

        XCTAssertNotNil(resolver.checklistTemplate(id: templateID))
    }

    func testIDResolutionRoundTripsInventoryItem() {
        let now = Date()
        let item = InventoryItem(
            id: UUID(uuidString: "dddddddd-1111-2222-3333-444444444444")!,
            name: "Flashlight", category: .lighting,
            quantity: 2, unit: "each", location: "Kit", notes: "",
            expiryDate: nil, reorderThreshold: nil, tags: [],
            createdAt: now, updatedAt: now, isArchived: false
        )
        let deps = makeTestDependencies(inventoryItems: [item])
        let resolver = EntityQueryResolver(dependencies: deps)

        XCTAssertNotNil(resolver.inventoryItem(id: item.id))
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsNoResults() {
        let deps = makeTestDependencies(
            searchResults: [SearchResult(id: UUID(), kind: .quickCard, title: "Test", snippet: "", score: 1.0, tags: [])]
        )
        let resolver = EntityQueryResolver(dependencies: deps)

        XCTAssertTrue(resolver.searchQuickCards(query: "").isEmpty)
        XCTAssertTrue(resolver.searchQuickCards(query: "   ").isEmpty)
        XCTAssertTrue(resolver.searchHandbookSections(query: "").isEmpty)
        XCTAssertTrue(resolver.searchChecklistTemplates(query: "").isEmpty)
        XCTAssertTrue(resolver.searchInventoryItems(query: "").isEmpty)
    }
}

// MARK: - Test Dependency Builder

private func makeTestDependencies(
    chapters: [HandbookChapter] = [],
    sections: [HandbookSection] = [],
    quickCards: [QuickCard] = [],
    templates: [ChecklistTemplate] = [],
    inventoryItems: [InventoryItem] = [],
    searchResults: [SearchResult] = []
) -> AppDependencies {
    let handbookRepo = StubHandbookRepository(chapters: chapters, sections: sections)
    let quickCardRepo = StubQuickCardRepository(cards: quickCards)
    let checklistRepo = StubChecklistRepository(templates: templates)
    let inventoryRepo = StubInventoryRepository(items: inventoryItems)
    let searchService = StubSearchService(results: searchResults)

    return AppDependencies(
        handbookRepository: handbookRepo,
        quickCardRepository: quickCardRepo,
        seedContentRepository: StubSeedContentRepository(),
        inventoryRepository: inventoryRepo,
        checklistRepository: checklistRepo,
        noteRepository: StubNoteRepository(),
        importedKnowledgeRepository: StubImportedKnowledgeRepository(),
        pendingOperationRepository: StubPendingOperationRepository(),
        capabilityDetector: StubCapabilityDetector(mode: .extractiveOnly),
        searchService: searchService,
        retrievalService: nil,
        connectivityService: StubConnectivityService(),
        trustedSourceHTTPClient: StubTrustedSourceHTTPClient(),
        importPipeline: ImportedKnowledgeImportPipeline(
            repository: StubImportedKnowledgeRepository(),
            searchService: searchService
        ),
        refreshCoordinator: ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: StubImportedKnowledgeRepository(),
            pendingOperationRepository: StubPendingOperationRepository(),
            connectivityService: StubConnectivityService(),
            httpClient: StubTrustedSourceHTTPClient(),
            importPipeline: ImportedKnowledgeImportPipeline(
                repository: StubImportedKnowledgeRepository(),
                searchService: searchService
            )
        ),
        inventoryCompletionService: LocalInventoryCompletionService(
            capabilityDetector: StubCapabilityDetector(mode: .extractiveOnly)
        ),
        rssDiscoveryService: StubRSSDiscoveryService(),
        discoveryCoordinator: KnowledgeDiscoveryCoordinator(
            rssDiscoveryService: StubRSSDiscoveryService(),
            webSearchClientProvider: { nil },
            httpClient: StubTrustedSourceHTTPClient(),
            importPipeline: ImportedKnowledgeImportPipeline(
                repository: StubImportedKnowledgeRepository(),
                searchService: searchService
            ),
            importedKnowledgeRepository: StubImportedKnowledgeRepository(),
            connectivityService: StubConnectivityService()
        ),
        weatherForecastRepository: StubWeatherForecastRepository(),
        weatherForecastService: StubWeatherForecastService(),
        weatherAlertService: StubWeatherAlertService(),
        locationService: StubLocationService(),
        mapAnnotationProvider: StubMapAnnotationProvider(),
        tileCacheService: StubTileCacheService()
    )
}

private struct StubRSSDiscoveryService: RSSDiscoveryService {
    func discoverArticles() async -> [DiscoveredArticle] { [] }
}

private final class StubWeatherForecastRepository: WeatherForecastRepository, @unchecked Sendable {
    func cachedForecasts() throws -> [DailyForecast] { [] }
    func replaceForecasts(_ forecasts: [DailyForecast]) throws {}
    func cacheInfo() throws -> ForecastCacheInfo? { nil }
    func cachedAlerts() throws -> [WeatherAlert] { [] }
    func replaceAlerts(_ alerts: [WeatherAlert]) throws {}
    func activeAlerts() throws -> [WeatherAlert] { [] }
}

private struct StubWeatherForecastService: WeatherForecastService {
    func fetchTenDayForecast(for location: CoreLocation.CLLocationCoordinate2D) async throws -> [DailyForecast] { [] }
    func attribution() async -> (markURL: URL, legalURL: URL)? { nil }
}

private struct StubWeatherAlertService: WeatherAlertService {
    func fetchAlerts() async -> [WeatherAlert] { [] }
}

private final class StubLocationService: LocationService, @unchecked Sendable {
    @MainActor var currentLocation: CoreLocation.CLLocationCoordinate2D? { nil }
    @MainActor var authorizationStatus: CoreLocation.CLAuthorizationStatus { .notDetermined }
    func requestWhenInUseAuthorization() {}
    @MainActor func locationStream() -> AsyncStream<CoreLocation.CLLocationCoordinate2D> {
        AsyncStream { $0.finish() }
    }
}

private struct StubMapAnnotationProvider: MapAnnotationProvider {
    func annotations(near coordinate: CoreLocation.CLLocationCoordinate2D, radiusKm: Double) -> [MapAnnotationItem] { [] }
    func allAnnotations() -> [MapAnnotationItem] { [] }
}

private struct StubTileCacheService: TileCacheService {
    func hasCachedTiles(for region: CachedTileRegion) -> Bool { false }
    func cachedRegions() -> [CachedTileRegion] { [] }
    func tileData(x: Int, y: Int, z: Int) -> Data? { nil }
}

// MARK: - Focused Stubs (reuses StubSearchService and StubCapabilityDetector from LocalRetrievalServiceTests)

private final class StubHandbookRepository: HandbookRepository, @unchecked Sendable {
    let chapters: [HandbookChapter]
    let sections: [HandbookSection]
    init(chapters: [HandbookChapter] = [], sections: [HandbookSection] = []) {
        self.chapters = chapters
        self.sections = sections
    }
    func listChapters() throws -> [HandbookChapterSummary] {
        chapters.map(\.summaryValue)
    }
    func chapter(slug: String) throws -> HandbookChapter? {
        chapters.first { $0.slug == slug }
    }
    func chapter(id: UUID) throws -> HandbookChapter? {
        chapters.first { $0.id == id }
    }
    func section(id: UUID) throws -> HandbookSection? {
        sections.first { $0.id == id }
    }
}

private final class StubQuickCardRepository: QuickCardRepository, @unchecked Sendable {
    let cards: [QuickCard]
    init(cards: [QuickCard] = []) { self.cards = cards }
    func listQuickCards() throws -> [QuickCard] { cards }
    func quickCard(slug: String) throws -> QuickCard? { cards.first { $0.slug == slug } }
    func quickCard(id: UUID) throws -> QuickCard? { cards.first { $0.id == id } }
}

private final class StubChecklistRepository: ChecklistRepository, @unchecked Sendable {
    let templates: [ChecklistTemplate]
    init(templates: [ChecklistTemplate] = []) { self.templates = templates }
    func listTemplates() throws -> [ChecklistTemplateSummary] { templates.map(\.summaryValue) }
    func template(slug: String) throws -> ChecklistTemplate? { templates.first { $0.slug == slug } }
    func template(id: UUID) throws -> ChecklistTemplate? { templates.first { $0.id == id } }
    func listRuns(status: ChecklistRunStatus?) throws -> [ChecklistRun] { [] }
    func run(id: UUID) throws -> ChecklistRun? { nil }
    func createRun(_ run: ChecklistRun) throws {}
    func updateRun(_ run: ChecklistRun) throws {}
    func deleteRun(id: UUID) throws {}
    func startRun(from templateID: UUID, title: String, contextNote: String?) throws -> ChecklistRun {
        fatalError("Not expected in entity tests")
    }
    func activeRuns() throws -> [ChecklistRun] { [] }
}

private final class StubInventoryRepository: InventoryRepository, @unchecked Sendable {
    let items: [InventoryItem]
    init(items: [InventoryItem] = []) { self.items = items }
    func listItems(includeArchived: Bool) throws -> [InventoryItem] {
        includeArchived ? items : items.filter { !$0.isArchived }
    }
    func item(id: UUID) throws -> InventoryItem? { items.first { $0.id == id } }
    func createItem(_ item: InventoryItem) throws {}
    func updateItem(_ item: InventoryItem) throws {}
    func archiveItem(id: UUID) throws {}
    func deleteItem(id: UUID) throws {}
    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] { [] }
    func itemsBelowReorderThreshold() throws -> [InventoryItem] { [] }
}

private final class StubSeedContentRepository: SeedContentRepository, @unchecked Sendable {
    func currentSeedVersionState() throws -> SeedContentVersionState? { nil }
    func upsertSeedContent(_ bundle: SeedContentBundle, importedAt: Date) throws -> SeedImportOutcome {
        SeedImportOutcome(
            status: .skippedAlreadyCurrent,
            versionState: SeedContentVersionState(schemaVersion: 1, contentPackVersion: "1.0", appliedAt: Date()),
            chapterCount: 0, sectionCount: 0, quickCardCount: 0, checklistTemplateCount: 0
        )
    }
}

private final class StubNoteRepository: NoteRepository, @unchecked Sendable {
    func listNotes(type: NoteType?) throws -> [NoteRecord] { [] }
    func note(id: UUID) throws -> NoteRecord? { nil }
    func createNote(_ note: NoteRecord) throws {}
    func updateNote(_ note: NoteRecord) throws {}
    func deleteNote(id: UUID) throws {}
    func recentNotes(limit: Int) throws -> [NoteRecord] { [] }
    func notesLinkedToSection(id: UUID) throws -> [NoteRecord] { [] }
    func notesLinkedToInventoryItem(id: UUID) throws -> [NoteRecord] { [] }
}

private final class StubImportedKnowledgeRepository: ImportedKnowledgeRepository, @unchecked Sendable {
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

private final class StubPendingOperationRepository: PendingOperationRepository, @unchecked Sendable {
    func listOperations(status: OperationStatus?) throws -> [PendingOperation] { [] }
    func operation(id: UUID) throws -> PendingOperation? { nil }
    func createOperation(_ operation: PendingOperation) throws {}
    func updateOperation(_ operation: PendingOperation) throws {}
    func deleteOperation(id: UUID) throws {}
    func nextQueued() throws -> PendingOperation? { nil }
    func failedOperations(maxRetries: Int) throws -> [PendingOperation] { [] }
    func purgeCompleted() throws {}
}

private final class StubConnectivityService: ConnectivityService, @unchecked Sendable {
    @MainActor var currentState: ConnectivityState { .offline }
    @MainActor func stateStream() -> AsyncStream<ConnectivityState> {
        AsyncStream { $0.finish() }
    }
    func start() {}
    func stop() {}
    @MainActor func setSyncInProgress() {}
    @MainActor func clearSyncInProgress() {}
}

private final class StubTrustedSourceHTTPClient: TrustedSourceHTTPClient, @unchecked Sendable {
    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        throw TrustedSourceFetchError.offline
    }
}
