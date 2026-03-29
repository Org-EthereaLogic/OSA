import Foundation

final class SearchIndexedInventoryRepository: InventoryRepository {
    private let base: any InventoryRepository
    private let searchService: any SearchService

    init(base: any InventoryRepository, searchService: any SearchService) {
        self.base = base
        self.searchService = searchService
    }

    func listItems(includeArchived: Bool) throws -> [InventoryItem] {
        try base.listItems(includeArchived: includeArchived)
    }

    func item(id: UUID) throws -> InventoryItem? {
        try base.item(id: id)
    }

    func createItem(_ item: InventoryItem) throws {
        try base.createItem(item)
        try? searchService.indexInventoryItem(item)
    }

    func updateItem(_ item: InventoryItem) throws {
        try base.updateItem(item)
        try? searchService.indexInventoryItem(item)
    }

    func archiveItem(id: UUID) throws {
        try base.archiveItem(id: id)
        try? searchService.removeFromIndex(id: id)
    }

    func deleteItem(id: UUID) throws {
        try base.deleteItem(id: id)
        try? searchService.removeFromIndex(id: id)
    }

    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] {
        try base.itemsExpiringSoon(within: days)
    }

    func itemsBelowReorderThreshold() throws -> [InventoryItem] {
        try base.itemsBelowReorderThreshold()
    }
}
