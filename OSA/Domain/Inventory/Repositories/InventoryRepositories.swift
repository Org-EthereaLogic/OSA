import Foundation

protocol InventoryRepository {
    func listItems(includeArchived: Bool) throws -> [InventoryItem]
    func item(id: UUID) throws -> InventoryItem?
    func createItem(_ item: InventoryItem) throws
    func updateItem(_ item: InventoryItem) throws
    func archiveItem(id: UUID) throws
    func deleteItem(id: UUID) throws
    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem]
    func itemsBelowReorderThreshold() throws -> [InventoryItem]
}
