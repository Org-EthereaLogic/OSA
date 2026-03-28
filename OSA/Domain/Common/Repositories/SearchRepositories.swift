import Foundation

protocol SearchService {
    func search(
        query: String,
        scopes: Set<SearchResultKind>?,
        requiredTags: Set<String>,
        limit: Int
    ) throws -> [SearchResult]
    func suggestions(prefix: String, limit: Int) throws -> [SearchSuggestion]
    func recordSuccessfulQuery(_ query: String) throws
    func indexAllContent() throws
    func indexInventoryItem(_ item: InventoryItem) throws
    func indexChecklistTemplate(_ template: ChecklistTemplate) throws
    func indexNote(_ note: NoteRecord) throws
    func indexHandbookSection(_ section: HandbookSection, chapterTitle: String) throws
    func indexQuickCard(_ card: QuickCard) throws
    func indexImportedChunk(_ chunk: KnowledgeChunk, sourceTitle: String, publisherDomain: String) throws
    func removeFromIndex(id: UUID) throws
}

extension SearchService {
    func search(query: String, scopes: Set<SearchResultKind>?, limit: Int) throws -> [SearchResult] {
        try search(
            query: query,
            scopes: scopes,
            requiredTags: [],
            limit: limit
        )
    }
}
