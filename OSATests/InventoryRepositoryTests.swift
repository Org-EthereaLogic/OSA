import SwiftData
import XCTest
@testable import OSA

final class InventoryRepositoryTests: XCTestCase {
    func testCreateAndListItems() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let item = makeItem(name: "Water Jug", category: .water, quantity: 4, unit: "gallons")
        try repository.createItem(item)

        let items = try repository.listItems(includeArchived: false)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Water Jug")
        XCTAssertEqual(items.first?.category, .water)
        XCTAssertEqual(items.first?.quantity, 4)
        XCTAssertEqual(items.first?.unit, "gallons")
    }

    func testItemByID() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let item = makeItem(name: "Flashlight", category: .lighting)
        try repository.createItem(item)

        let fetched = try XCTUnwrap(repository.item(id: item.id))
        XCTAssertEqual(fetched.name, "Flashlight")
        XCTAssertEqual(fetched.category, .lighting)
    }

    func testItemByIDReturnsNilForUnknownID() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let result = try repository.item(id: UUID())
        XCTAssertNil(result)
    }

    func testUpdateItem() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        var item = makeItem(name: "Canned Beans", category: .food, quantity: 6)
        try repository.createItem(item)

        item.quantity = 10
        item.notes = "Rotated stock"
        item.updatedAt = Date()
        try repository.updateItem(item)

        let fetched = try XCTUnwrap(repository.item(id: item.id))
        XCTAssertEqual(fetched.quantity, 10)
        XCTAssertEqual(fetched.notes, "Rotated stock")
    }

    func testArchiveItem() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let item = makeItem(name: "Old Batteries", category: .power)
        try repository.createItem(item)

        try repository.archiveItem(id: item.id)

        let activeItems = try repository.listItems(includeArchived: false)
        XCTAssertTrue(activeItems.isEmpty)

        let allItems = try repository.listItems(includeArchived: true)
        XCTAssertEqual(allItems.count, 1)
        XCTAssertTrue(allItems.first?.isArchived == true)
    }

    func testDeleteItem() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let item = makeItem(name: "Expired MRE", category: .food)
        try repository.createItem(item)

        try repository.deleteItem(id: item.id)

        let items = try repository.listItems(includeArchived: true)
        XCTAssertTrue(items.isEmpty)
    }

    func testItemsExpiringSoon() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let soon = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let later = Calendar.current.date(byAdding: .day, value: 90, to: Date())!

        let expiringSoonItem = makeItem(name: "Water Pouches", category: .water, expiryDate: soon)
        let freshItem = makeItem(name: "Canned Soup", category: .food, expiryDate: later)

        try repository.createItem(expiringSoonItem)
        try repository.createItem(freshItem)

        let expiring = try repository.itemsExpiringSoon(within: 30)
        XCTAssertEqual(expiring.count, 1)
        XCTAssertEqual(expiring.first?.name, "Water Pouches")
    }

    func testItemsBelowReorderThreshold() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let lowItem = makeItem(name: "Batteries", category: .power, quantity: 2, reorderThreshold: 5)
        let okItem = makeItem(name: "Candles", category: .lighting, quantity: 20, reorderThreshold: 5)

        try repository.createItem(lowItem)
        try repository.createItem(okItem)

        let low = try repository.itemsBelowReorderThreshold()
        XCTAssertEqual(low.count, 1)
        XCTAssertEqual(low.first?.name, "Batteries")
    }

    func testListExcludesArchivedByDefault() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataInventoryRepository(modelContext: container.mainContext)

        let active = makeItem(name: "Active Item", category: .tools)
        var archived = makeItem(name: "Archived Item", category: .tools)
        archived.isArchived = true

        try repository.createItem(active)
        try repository.createItem(archived)

        let activeOnly = try repository.listItems(includeArchived: false)
        XCTAssertEqual(activeOnly.count, 1)
        XCTAssertEqual(activeOnly.first?.name, "Active Item")

        let all = try repository.listItems(includeArchived: true)
        XCTAssertEqual(all.count, 2)
    }

    // MARK: - Helpers

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([PersistedInventoryItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeItem(
        name: String,
        category: InventoryCategory,
        quantity: Int = 1,
        unit: String = "units",
        expiryDate: Date? = nil,
        reorderThreshold: Int? = nil
    ) -> InventoryItem {
        let now = Date()
        return InventoryItem(
            id: UUID(),
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            location: "",
            notes: "",
            expiryDate: expiryDate,
            reorderThreshold: reorderThreshold,
            tags: [],
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
    }
}
