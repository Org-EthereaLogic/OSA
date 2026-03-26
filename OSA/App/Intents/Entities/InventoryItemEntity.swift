import AppIntents
import CoreSpotlight
import Foundation

/// App Entity representing a non-archived inventory item, discoverable
/// through Siri, Shortcuts, and Spotlight.
///
/// Privacy rules:
/// - Archived items are excluded from all query results and suggestions.
/// - Free-form `notes` text is never exposed in display or Spotlight metadata.
struct InventoryItemEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Inventory Item",
        numericFormat: "\(placeholder: .int) inventory items"
    )

    static let defaultQuery = InventoryItemEntityQuery()

    let id: UUID
    let name: String
    let category: String
    let quantity: Int
    let unit: String

    var displayRepresentation: DisplayRepresentation {
        let subtitle = "\(category) — \(quantity) \(unit)"
        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(subtitle)"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = name
        attributes.contentDescription = "\(category) — \(quantity) \(unit)"
        return attributes
    }

    init(id: UUID, name: String, category: String, quantity: Int, unit: String) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
    }

    init(from item: InventoryItem) {
        self.id = item.id
        self.name = item.name
        self.category = item.category.rawValue
        self.quantity = item.quantity
        self.unit = item.unit
    }
}

// MARK: - Entity Query

struct InventoryItemEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [InventoryItemEntity] {
        let resolver = EntityQueryResolver()
        return identifiers.compactMap { id in
            resolver.inventoryItem(id: id).map(InventoryItemEntity.init(from:))
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [InventoryItemEntity] {
        let resolver = EntityQueryResolver()
        return resolver.searchInventoryItems(query: string).map(InventoryItemEntity.init(from:))
    }

    @MainActor
    func suggestedEntities() async throws -> [InventoryItemEntity] {
        let resolver = EntityQueryResolver()
        return resolver.suggestedInventoryItems().map(InventoryItemEntity.init(from:))
    }
}
