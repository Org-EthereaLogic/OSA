import SwiftData
import XCTest
@testable import OSA

@MainActor
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

final class RecentLibraryHistorySettingsTests: XCTestCase {
    func testRecordedPlacesNewestIDFirstAndDeduplicates() {
        let first = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let second = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let third = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

        var rawValue = RecentLibraryHistorySettings.encode(ids: [first, second])
        rawValue = RecentLibraryHistorySettings.recorded(third, rawValue: rawValue)
        rawValue = RecentLibraryHistorySettings.recorded(second, rawValue: rawValue)

        XCTAssertEqual(
            RecentLibraryHistorySettings.ids(from: rawValue),
            [second, third, first]
        )
    }

    func testRecordedHonorsConfiguredLimit() {
        let ids = (0..<8).map { index in
            UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!
        }

        let rawValue = ids.reduce(RecentLibraryHistorySettings.encode(ids: [])) { partial, id in
            RecentLibraryHistorySettings.recorded(id, rawValue: partial, limit: 4)
        }

        XCTAssertEqual(RecentLibraryHistorySettings.ids(from: rawValue), Array(ids.suffix(4).reversed()))
    }

    func testIDsReturnsEmptyArrayForInvalidRawValue() {
        XCTAssertTrue(RecentLibraryHistorySettings.ids(from: "not-json").isEmpty)
    }

    func testPruneRemovesUnresolvableIDsButPreservesOrder() {
        let first = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let second = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let third = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let rawValue = RecentLibraryHistorySettings.encode(ids: [first, second, third])
        let pruned = RecentLibraryHistorySettings.prune(rawValue: rawValue, keeping: [third, first])

        XCTAssertEqual(RecentLibraryHistorySettings.ids(from: pruned), [first, third])
    }
}
