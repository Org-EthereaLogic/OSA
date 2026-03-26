import Foundation

final class LocalSearchService: SearchService {
    private let store: SearchIndexStore

    init(store: SearchIndexStore) {
        self.store = store
    }

    static func makeDefault() throws -> LocalSearchService {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupport.appendingPathComponent("OSA", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let dbPath = directoryURL.appendingPathComponent("SearchIndex.sqlite").path
        let store = try SearchIndexStore(path: dbPath)
        return LocalSearchService(store: store)
    }

    func search(query: String, scopes: Set<SearchResultKind>?, limit: Int) throws -> [SearchResult] {
        let entries = try store.query(text: query, kindFilter: scopes, limit: limit)
        return entries.map { entry in
            SearchResult(
                id: entry.id,
                kind: entry.kind,
                title: entry.title,
                snippet: entry.snippet,
                score: entry.score,
                tags: []
            )
        }
    }

    func indexAllContent() throws {
        // This is called externally after seed import or index rebuild.
        // The caller passes content through per-entity index methods.
        // A full rebuild should call removeAll first, then index each entity.
        try store.removeAll()
    }

    func indexInventoryItem(_ item: InventoryItem) throws {
        try store.upsert(
            id: item.id,
            kind: .inventoryItem,
            title: item.name,
            body: [item.location, item.notes, item.category.rawValue].joined(separator: " "),
            tags: item.tags.joined(separator: " ")
        )
    }

    func indexChecklistTemplate(_ template: ChecklistTemplate) throws {
        let itemTexts = template.items.map(\.text).joined(separator: " ")
        try store.upsert(
            id: template.id,
            kind: .checklistTemplate,
            title: template.title,
            body: [template.description, template.category, itemTexts].joined(separator: " "),
            tags: template.tags.joined(separator: " ")
        )
    }

    func indexNote(_ note: NoteRecord) throws {
        try store.upsert(
            id: note.id,
            kind: .noteRecord,
            title: note.title,
            body: note.plainText,
            tags: note.tags.joined(separator: " ")
        )
    }

    func indexHandbookSection(_ section: HandbookSection, chapterTitle: String) throws {
        try store.upsert(
            id: section.id,
            kind: .handbookSection,
            title: section.heading,
            body: [chapterTitle, section.plainText].joined(separator: " "),
            tags: section.tags.joined(separator: " ")
        )
    }

    func indexQuickCard(_ card: QuickCard) throws {
        try store.upsert(
            id: card.id,
            kind: .quickCard,
            title: card.title,
            body: [card.summary, card.category].joined(separator: " "),
            tags: card.tags.joined(separator: " ")
        )
    }

    func indexImportedChunk(_ chunk: KnowledgeChunk, sourceTitle: String, publisherDomain: String) throws {
        let title = chunk.headingPath.isEmpty ? sourceTitle : "\(sourceTitle) — \(chunk.headingPath)"
        try store.upsert(
            id: chunk.id,
            kind: .importedKnowledge,
            title: title,
            body: chunk.plainText,
            tags: ([publisherDomain] + chunk.tags).joined(separator: " ")
        )
    }

    func removeFromIndex(id: UUID) throws {
        try store.removeEntry(id: id)
    }
}
