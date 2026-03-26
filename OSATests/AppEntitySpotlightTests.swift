import XCTest
@testable import OSA

final class AppEntitySpotlightTests: XCTestCase {

    // MARK: - Handbook Section Display

    func testHandbookSectionEntityIncludesChapterInDisplay() {
        let entity = HandbookSectionEntity(
            id: UUID(),
            heading: "Water Purification Methods",
            chapterTitle: "Water Safety"
        )
        // Verify chapter context is in the entity's stored fields for display
        XCTAssertEqual(entity.heading, "Water Purification Methods")
        XCTAssertEqual(entity.chapterTitle, "Water Safety")
        // attributeSet is the Spotlight-facing representation
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Water Purification Methods")
        XCTAssertEqual(attrs.contentDescription, "Water Safety")
    }

    func testHandbookSectionAttributeSetIncludesChapterTitle() {
        let entity = HandbookSectionEntity(
            id: UUID(),
            heading: "Shelter Construction",
            chapterTitle: "Shelter"
        )
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Shelter Construction")
        XCTAssertEqual(attrs.contentDescription, "Shelter")
    }

    // MARK: - Quick Card Display

    func testQuickCardEntityDisplayShowsCategory() {
        let entity = QuickCardEntity(
            id: UUID(),
            title: "Boil Water Advisory",
            category: "Water"
        )
        XCTAssertEqual(entity.title, "Boil Water Advisory")
        XCTAssertEqual(entity.category, "Water")
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Boil Water Advisory")
        XCTAssertEqual(attrs.contentDescription, "Water")
    }

    func testQuickCardAttributeSet() {
        let entity = QuickCardEntity(
            id: UUID(),
            title: "Boil Water",
            category: "Water"
        )
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Boil Water")
        XCTAssertEqual(attrs.contentDescription, "Water")
    }

    // MARK: - Checklist Display

    func testChecklistEntityDisplayShowsCategoryAndCount() {
        let entity = ChecklistEntity(
            id: UUID(),
            title: "72-Hour Kit",
            category: "Emergency",
            itemCount: 15
        )
        XCTAssertEqual(entity.title, "72-Hour Kit")
        XCTAssertEqual(entity.category, "Emergency")
        XCTAssertEqual(entity.itemCount, 15)
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "72-Hour Kit")
        XCTAssertTrue(attrs.contentDescription?.contains("Emergency") == true)
    }

    func testChecklistAttributeSet() {
        let entity = ChecklistEntity(
            id: UUID(),
            title: "Go Bag",
            category: "Emergency",
            itemCount: 8
        )
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Go Bag")
        XCTAssertTrue(attrs.contentDescription?.contains("Emergency") == true)
        XCTAssertTrue(attrs.contentDescription?.contains("8") == true)
    }

    // MARK: - Inventory Display Does Not Include Notes

    func testInventoryEntityDisplayDoesNotExposeNotes() {
        let now = Date()
        let item = InventoryItem(
            id: UUID(), name: "Water Jug", category: .water,
            quantity: 5, unit: "gallons", location: "Garage",
            notes: "This is a secret note that should not appear",
            expiryDate: nil, reorderThreshold: nil, tags: [],
            createdAt: now, updatedAt: now, isArchived: false
        )
        let entity = InventoryItemEntity(from: item)

        // Display representation
        let display = entity.displayRepresentation
        let titleString = display.title.key
        let subtitleString = display.subtitle.map { "\($0)" } ?? ""
        XCTAssertFalse(titleString.contains("secret"), "Notes should not appear in display title")
        XCTAssertFalse(subtitleString.contains("secret"), "Notes should not appear in display subtitle")

        // Spotlight attribute set
        let attrs = entity.attributeSet
        XCTAssertFalse(attrs.displayName?.contains("secret") == true, "Notes should not appear in Spotlight displayName")
        XCTAssertFalse(attrs.contentDescription?.contains("secret") == true, "Notes should not appear in Spotlight contentDescription")
    }

    func testInventoryEntityDoesNotStoreNotesField() {
        let now = Date()
        let item = InventoryItem(
            id: UUID(), name: "Flashlight", category: .lighting,
            quantity: 2, unit: "each", location: "Kit",
            notes: "Private detail about flashlight batteries",
            expiryDate: nil, reorderThreshold: nil, tags: [],
            createdAt: now, updatedAt: now, isArchived: false
        )
        let entity = InventoryItemEntity(from: item)

        // The entity struct itself has no notes property
        XCTAssertEqual(entity.name, "Flashlight")
        XCTAssertEqual(entity.category, "lighting")
        XCTAssertEqual(entity.quantity, 2)
        XCTAssertEqual(entity.unit, "each")
    }

    func testInventoryAttributeSet() {
        let entity = InventoryItemEntity(
            id: UUID(),
            name: "Water Jug",
            category: "water",
            quantity: 5,
            unit: "gallons"
        )
        let attrs = entity.attributeSet
        XCTAssertEqual(attrs.displayName, "Water Jug")
        XCTAssertTrue(attrs.contentDescription?.contains("water") == true)
        XCTAssertTrue(attrs.contentDescription?.contains("5") == true)
    }
}
