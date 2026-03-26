import AppIntents
import CoreSpotlight
import Foundation

/// App Entity representing a quick card, discoverable through
/// Siri, Shortcuts, and Spotlight.
struct QuickCardEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Quick Card",
        numericFormat: "\(placeholder: .int) quick cards"
    )

    static let defaultQuery = QuickCardEntityQuery()

    let id: UUID
    let title: String
    let category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(category)"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = title
        attributes.contentDescription = category
        return attributes
    }

    init(id: UUID, title: String, category: String) {
        self.id = id
        self.title = title
        self.category = category
    }

    init(from card: QuickCard) {
        self.id = card.id
        self.title = card.title
        self.category = card.category
    }
}

// MARK: - Entity Query

struct QuickCardEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [QuickCardEntity] {
        let resolver = EntityQueryResolver()
        return identifiers.compactMap { id in
            resolver.quickCard(id: id).map(QuickCardEntity.init(from:))
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [QuickCardEntity] {
        let resolver = EntityQueryResolver()
        return resolver.searchQuickCards(query: string).map(QuickCardEntity.init(from:))
    }

    @MainActor
    func suggestedEntities() async throws -> [QuickCardEntity] {
        let resolver = EntityQueryResolver()
        return resolver.suggestedQuickCards().map(QuickCardEntity.init(from:))
    }
}
