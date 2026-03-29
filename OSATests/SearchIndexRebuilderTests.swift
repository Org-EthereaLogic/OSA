import XCTest
@testable import OSA

final class SearchIndexRebuilderTests: XCTestCase {
    func testRebuildIndexesCurrentLocalContentAndClearsStaleEntries() throws {
        let searchService = try makeSearchService()
        try searchService.indexNote(
            NoteRecord(
                id: UUID(),
                title: "Stale Entry",
                bodyMarkdown: "orphaned",
                plainText: "orphaned",
                noteType: .personal,
                tags: [],
                linkedSectionIDs: [],
                linkedInventoryItemIDs: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        let chapterID = UUID()
        let section = HandbookSection(
            id: UUID(),
            chapterID: chapterID,
            parentSectionID: nil,
            heading: "Water Storage Basics",
            bodyMarkdown: "riverline reserves",
            plainText: "riverline reserves help households plan stored water.",
            sortOrder: 0,
            tags: ["water"],
            safetyLevel: .normal,
            chunkGroupID: "group-1",
            version: 1,
            lastReviewedAt: nil
        )
        let chapter = HandbookChapter(
            id: chapterID,
            slug: "preparedness-foundations",
            title: "Preparedness Foundations",
            summary: "Core basics",
            sortOrder: 0,
            tags: ["water"],
            version: 1,
            isSeeded: true,
            lastReviewedAt: nil,
            sections: [section]
        )
        let quickCard = QuickCard(
            id: UUID(),
            title: "Boil Water Advisory Steps",
            slug: "boil-water-advisory-steps",
            category: "water",
            summary: "advisory-step coverage for drinking water safety",
            bodyMarkdown: "Bring water to a rolling boil.",
            priority: 10,
            relatedSectionIDs: [section.id],
            tags: ["scenario:water-contamination"],
            lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
        let inventoryItem = InventoryItem(
            id: UUID(),
            name: "N95 Respirator",
            category: .other,
            quantity: 4,
            unit: "count",
            location: "garage bin",
            notes: "respirator filters smoke and dust",
            expiryDate: nil,
            reorderThreshold: nil,
            tags: ["wildfire"],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
        let checklistTemplateID = UUID()
        let checklistTemplate = ChecklistTemplate(
            id: checklistTemplateID,
            title: "Power Outage Starter",
            slug: "power-outage-starter",
            category: "power",
            description: "headlamp staging and device charging steps",
            estimatedMinutes: 15,
            tags: ["power"],
            sourceType: .seeded,
            presentationStyle: .standard,
            timerProfile: nil,
            lastReviewedAt: nil,
            items: [
                ChecklistTemplateItem(
                    id: UUID(),
                    templateID: checklistTemplateID,
                    text: "Place headlamp by the bed",
                    detail: nil,
                    sortOrder: 0,
                    isOptional: false,
                    riskLevel: nil
                )
            ]
        )
        let note = NoteRecord(
            id: UUID(),
            title: "Family Briefing",
            bodyMarkdown: "familycodeword delta",
            plainText: "familycodeword delta",
            noteType: .localReference,
            tags: ["study-guide"],
            linkedSectionIDs: [section.id],
            linkedInventoryItemIDs: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        let source = SourceRecord(
            id: UUID(),
            sourceTitle: "County Bulletin",
            sourceURL: "https://example.gov/bulletin",
            publisherDomain: "example.gov",
            publisherName: "Example County",
            fetchedAt: Date(),
            lastReviewedAt: Date(),
            contentHash: "hash",
            trustLevel: .curated,
            tags: [],
            localChunkIDs: [],
            reviewStatus: .approved,
            licenseSummary: nil,
            isActive: true,
            staleAfter: Date().addingTimeInterval(86_400)
        )
        let document = ImportedKnowledgeDocument(
            id: UUID(),
            sourceID: source.id,
            title: "Shelter Map",
            normalizedMarkdown: "watersystem shelter-map guidance",
            plainText: "watersystem shelter-map guidance",
            documentType: .reference,
            versionHash: "doc-hash",
            importedAt: Date(),
            supersedesDocumentID: nil
        )
        let chunk = KnowledgeChunk(
            id: UUID(),
            documentID: document.id,
            localChunkID: UUID(),
            headingPath: "Shelter Map",
            plainText: "watersystem shelter-map guidance",
            sortOrder: 0,
            tokenEstimate: 20,
            tags: [],
            trustLevel: .curated,
            contentHash: "chunk-hash",
            isSearchable: true
        )

        try SearchIndexRebuilder(
            searchService: searchService,
            handbookRepository: StubHandbookRepository(chapters: [chapter]),
            quickCardRepository: StubQuickCardRepository(cards: [quickCard]),
            inventoryRepository: InMemoryInventoryRepository(items: [inventoryItem]),
            checklistRepository: StubChecklistRepository(templates: [checklistTemplate]),
            noteRepository: InMemoryNoteRepository(notes: [note]),
            importedKnowledgeRepository: StubImportedKnowledgeRepository(
                sources: [source],
                documents: [document],
                chunks: [chunk]
            )
        )
        .rebuild()

        XCTAssertTrue(try searchService.search(query: "orphaned", scopes: nil, limit: 5).isEmpty)
        XCTAssertEqual(
            try searchService.search(query: "riverline", scopes: [.handbookSection], limit: 5).first?.kind,
            .handbookSection
        )
        XCTAssertEqual(
            try searchService.search(query: "advisory", scopes: [.quickCard], limit: 5).first?.kind,
            .quickCard
        )
        XCTAssertEqual(
            try searchService.search(query: "respirator", scopes: [.inventoryItem], limit: 5).first?.kind,
            .inventoryItem
        )
        XCTAssertEqual(
            try searchService.search(query: "headlamp", scopes: [.checklistTemplate], limit: 5).first?.kind,
            .checklistTemplate
        )
        XCTAssertEqual(
            try searchService.search(query: "familycodeword", scopes: [.noteRecord], limit: 5).first?.kind,
            .noteRecord
        )
        XCTAssertEqual(
            try searchService.search(query: "watersystem", scopes: [.importedKnowledge], limit: 5).first?.kind,
            .importedKnowledge
        )
    }

    func testIndexedNoteAndInventoryRepositoriesKeepSearchFresh() throws {
        let searchService = try makeSearchService()
        let baseNotes = InMemoryNoteRepository()
        let baseInventory = InMemoryInventoryRepository()
        let noteRepository = SearchIndexedNoteRepository(base: baseNotes, searchService: searchService)
        let inventoryRepository = SearchIndexedInventoryRepository(base: baseInventory, searchService: searchService)

        var note = NoteRecord(
            id: UUID(),
            title: "Study Guide",
            bodyMarkdown: "rallypoint alpha",
            plainText: "rallypoint alpha",
            noteType: .localReference,
            tags: ["study-guide"],
            linkedSectionIDs: [],
            linkedInventoryItemIDs: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        try noteRepository.createNote(note)
        XCTAssertEqual(
            try searchService.search(query: "rallypoint", scopes: [.noteRecord], limit: 5).first?.id,
            note.id
        )

        note.plainText = "rallypoint bravo"
        note.bodyMarkdown = "rallypoint bravo"
        note.updatedAt = Date()
        try noteRepository.updateNote(note)
        XCTAssertTrue(try searchService.search(query: "alpha", scopes: [.noteRecord], limit: 5).isEmpty)
        XCTAssertEqual(
            try searchService.search(query: "bravo", scopes: [.noteRecord], limit: 5).first?.id,
            note.id
        )

        try noteRepository.deleteNote(id: note.id)
        XCTAssertTrue(try searchService.search(query: "bravo", scopes: [.noteRecord], limit: 5).isEmpty)

        let item = InventoryItem(
            id: UUID(),
            name: "Water Tote",
            category: .water,
            quantity: 2,
            unit: "containers",
            location: "hall closet",
            notes: "closet tote",
            expiryDate: nil,
            reorderThreshold: nil,
            tags: ["water"],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )

        try inventoryRepository.createItem(item)
        XCTAssertEqual(
            try searchService.search(query: "closet", scopes: [.inventoryItem], limit: 5).first?.id,
            item.id
        )

        try inventoryRepository.archiveItem(id: item.id)
        XCTAssertTrue(try searchService.search(query: "closet", scopes: [.inventoryItem], limit: 5).isEmpty)
    }

    private func makeSearchService() throws -> LocalSearchService {
        let suiteName = "SearchIndexRebuilderTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return LocalSearchService(store: try SearchIndexStore(), userDefaults: userDefaults)
    }
}

private final class StubHandbookRepository: HandbookRepository {
    private let chaptersByID: [UUID: HandbookChapter]
    private let chaptersBySlug: [String: HandbookChapter]

    init(chapters: [HandbookChapter]) {
        self.chaptersByID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        self.chaptersBySlug = Dictionary(uniqueKeysWithValues: chapters.map { ($0.slug, $0) })
    }

    func listChapters() throws -> [HandbookChapterSummary] {
        chaptersByID.values.map(\.summaryValue)
    }

    func chapter(slug: String) throws -> HandbookChapter? {
        chaptersBySlug[slug]
    }

    func chapter(id: UUID) throws -> HandbookChapter? {
        chaptersByID[id]
    }

    func section(id: UUID) throws -> HandbookSection? {
        chaptersByID.values
            .flatMap(\.sections)
            .first(where: { $0.id == id })
    }
}

private final class StubQuickCardRepository: QuickCardRepository {
    private let cardsByID: [UUID: QuickCard]
    private let cardsBySlug: [String: QuickCard]

    init(cards: [QuickCard]) {
        self.cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
        self.cardsBySlug = Dictionary(uniqueKeysWithValues: cards.map { ($0.slug, $0) })
    }

    func listQuickCards() throws -> [QuickCard] {
        Array(cardsByID.values)
    }

    func quickCard(slug: String) throws -> QuickCard? {
        cardsBySlug[slug]
    }

    func quickCard(id: UUID) throws -> QuickCard? {
        cardsByID[id]
    }
}

private final class StubChecklistRepository: ChecklistRepository {
    private var templatesByID: [UUID: ChecklistTemplate]

    init(templates: [ChecklistTemplate] = []) {
        self.templatesByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }

    func listTemplates() throws -> [ChecklistTemplateSummary] {
        templatesByID.values.map(\.summaryValue)
    }

    func template(slug: String) throws -> ChecklistTemplate? {
        templatesByID.values.first(where: { $0.slug == slug })
    }

    func template(id: UUID) throws -> ChecklistTemplate? {
        templatesByID[id]
    }

    func listRuns(status: ChecklistRunStatus?) throws -> [ChecklistRun] {
        []
    }

    func run(id: UUID) throws -> ChecklistRun? {
        nil
    }

    func createRun(_ run: ChecklistRun) throws {}
    func updateRun(_ run: ChecklistRun) throws {}
    func deleteRun(id: UUID) throws {}

    func startRun(from templateID: UUID, title: String, contextNote: String?) throws -> ChecklistRun {
        throw ChecklistRepositoryError.templateNotFound(templateID)
    }

    func activeRuns() throws -> [ChecklistRun] {
        []
    }
}

private final class InMemoryInventoryRepository: InventoryRepository {
    private var itemsByID: [UUID: InventoryItem]

    init(items: [InventoryItem] = []) {
        self.itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    func listItems(includeArchived: Bool) throws -> [InventoryItem] {
        itemsByID.values
            .filter { includeArchived || !$0.isArchived }
    }

    func item(id: UUID) throws -> InventoryItem? {
        itemsByID[id]
    }

    func createItem(_ item: InventoryItem) throws {
        itemsByID[item.id] = item
    }

    func updateItem(_ item: InventoryItem) throws {
        itemsByID[item.id] = item
    }

    func archiveItem(id: UUID) throws {
        guard var item = itemsByID[id] else { return }
        item.isArchived = true
        itemsByID[id] = item
    }

    func deleteItem(id: UUID) throws {
        itemsByID.removeValue(forKey: id)
    }

    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] {
        []
    }

    func itemsBelowReorderThreshold() throws -> [InventoryItem] {
        []
    }
}

private final class InMemoryNoteRepository: NoteRepository {
    private var notesByID: [UUID: NoteRecord]

    init(notes: [NoteRecord] = []) {
        self.notesByID = Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
    }

    func listNotes(type: NoteType?) throws -> [NoteRecord] {
        notesByID.values.filter { note in
            guard let type else { return true }
            return note.noteType == type
        }
    }

    func note(id: UUID) throws -> NoteRecord? {
        notesByID[id]
    }

    func createNote(_ note: NoteRecord) throws {
        notesByID[note.id] = note
    }

    func updateNote(_ note: NoteRecord) throws {
        notesByID[note.id] = note
    }

    func deleteNote(id: UUID) throws {
        notesByID.removeValue(forKey: id)
    }

    func recentNotes(limit: Int) throws -> [NoteRecord] {
        Array(notesByID.values.prefix(limit))
    }

    func notesLinkedToSection(id: UUID) throws -> [NoteRecord] {
        notesByID.values.filter { $0.linkedSectionIDs.contains(id) }
    }

    func notesLinkedToInventoryItem(id: UUID) throws -> [NoteRecord] {
        notesByID.values.filter { $0.linkedInventoryItemIDs.contains(id) }
    }
}

private final class StubImportedKnowledgeRepository: ImportedKnowledgeRepository {
    private let sourcesByID: [UUID: SourceRecord]
    private let documentsByID: [UUID: ImportedKnowledgeDocument]
    private let chunksByID: [UUID: KnowledgeChunk]

    init(
        sources: [SourceRecord] = [],
        documents: [ImportedKnowledgeDocument] = [],
        chunks: [KnowledgeChunk] = []
    ) {
        self.sourcesByID = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
        self.documentsByID = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })
        self.chunksByID = Dictionary(uniqueKeysWithValues: chunks.map { ($0.id, $0) })
    }

    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord] {
        sourcesByID.values.filter { source in
            guard let trustLevel else { return true }
            return source.trustLevel == trustLevel
        }
    }

    func source(id: UUID) throws -> SourceRecord? { sourcesByID[id] }
    func source(url: String) throws -> SourceRecord? { sourcesByID.values.first(where: { $0.sourceURL == url }) }
    func createSource(_ source: SourceRecord) throws {}
    func updateSource(_ source: SourceRecord) throws {}
    func deleteSource(id: UUID) throws {}

    func activeSources() throws -> [SourceRecord] {
        sourcesByID.values.filter(\.isActive)
    }

    func staleSources(asOf date: Date) throws -> [SourceRecord] {
        sourcesByID.values.filter { $0.staleAfter <= date }
    }

    func listDocuments(sourceID: UUID) throws -> [ImportedKnowledgeDocument] {
        documentsByID.values.filter { $0.sourceID == sourceID }
    }

    func document(id: UUID) throws -> ImportedKnowledgeDocument? { documentsByID[id] }
    func createDocument(_ document: ImportedKnowledgeDocument) throws {}
    func updateDocument(_ document: ImportedKnowledgeDocument) throws {}
    func deleteDocument(id: UUID) throws {}

    func listChunks(documentID: UUID) throws -> [KnowledgeChunk] {
        chunksByID.values.filter { $0.documentID == documentID }
    }

    func chunk(id: UUID) throws -> KnowledgeChunk? { chunksByID[id] }
    func createChunk(_ chunk: KnowledgeChunk) throws {}
    func createChunks(_ chunks: [KnowledgeChunk]) throws {}
    func deleteChunks(documentID: UUID) throws {}

    func searchableChunks() throws -> [KnowledgeChunk] {
        chunksByID.values.filter(\.isSearchable)
    }
}
