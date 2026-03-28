import Foundation

final class LocalSearchService: SearchService {
    private let store: SearchIndexStore
    private let userDefaults: UserDefaults
    private let recentQueriesKey = "search.recentQueries"

    init(store: SearchIndexStore, userDefaults: UserDefaults = .standard) {
        self.store = store
        self.userDefaults = userDefaults
    }

    static func makeDefault() throws -> LocalSearchService {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupport.appendingPathComponent("OSA", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let dbPath = directoryURL.appendingPathComponent("SearchIndex.sqlite").path
        let store = try SearchIndexStore(path: dbPath)
        return LocalSearchService(store: store)
    }

    func search(
        query: String,
        scopes: Set<SearchResultKind>?,
        requiredTags: Set<String>,
        limit: Int
    ) throws -> [SearchResult] {
        let entries = try store.query(text: query, kindFilter: scopes, limit: limit)
        let results = entries.map { entry in
            SearchResult(
                id: entry.id,
                kind: entry.kind,
                title: entry.title,
                snippet: entry.snippet,
                score: entry.score,
                tags: entry.tags
            )
        }

        guard !requiredTags.isEmpty else { return results }
        return results.filter { result in
            !requiredTags.isDisjoint(with: Set(result.tags))
        }
    }

    func suggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let localSuggestions = try store.suggestions(prefix: prefix, limit: limit)
        let recent = recentQueries()
            .filter { $0.localizedCaseInsensitiveContains(prefix) || $0.lowercased().hasPrefix(prefix.lowercased()) }
            .map { SearchSuggestion(text: $0, source: .recent) }

        var seen = Set<String>()
        return (recent + localSuggestions).filter { suggestion in
            let key = suggestion.text.lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
        .prefix(limit)
        .map { $0 }
    }

    func recordSuccessfulQuery(_ query: String) throws {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var values = recentQueries()
        values.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        values.insert(trimmed, at: 0)
        userDefaults.set(Array(values.prefix(10)), forKey: recentQueriesKey)
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

    private func recentQueries() -> [String] {
        userDefaults.stringArray(forKey: recentQueriesKey) ?? []
    }
}
