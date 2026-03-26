import Foundation

protocol SearchService {
    func search(query: String, scopes: Set<SearchResultKind>?, limit: Int) throws -> [SearchResult]
    func indexAllContent() throws
    func indexInventoryItem(_ item: InventoryItem) throws
    func indexChecklistTemplate(_ template: ChecklistTemplate) throws
    func indexNote(_ note: NoteRecord) throws
    func indexHandbookSection(_ section: HandbookSection, chapterTitle: String) throws
    func indexQuickCard(_ card: QuickCard) throws
    func indexImportedChunk(_ chunk: KnowledgeChunk, sourceTitle: String, publisherDomain: String) throws
    func removeFromIndex(id: UUID) throws
}
