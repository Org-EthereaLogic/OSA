import AppIntents
import CoreSpotlight
import Foundation

/// App Entity representing a checklist template (not an active run),
/// discoverable through Siri, Shortcuts, and Spotlight.
struct ChecklistEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Checklist",
        numericFormat: "\(placeholder: .int) checklists"
    )

    static let defaultQuery = ChecklistEntityQuery()

    let id: UUID
    let title: String
    let category: String
    let itemCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(category) — \(itemCount) items"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = title
        attributes.contentDescription = "\(category) — \(itemCount) items"
        return attributes
    }

    init(id: UUID, title: String, category: String, itemCount: Int) {
        self.id = id
        self.title = title
        self.category = category
        self.itemCount = itemCount
    }

    init(from summary: ChecklistTemplateSummary) {
        self.id = summary.id
        self.title = summary.title
        self.category = summary.category
        self.itemCount = summary.itemCount
    }
}

// MARK: - Entity Query

struct ChecklistEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ChecklistEntity] {
        let resolver = EntityQueryResolver()
        return identifiers.compactMap { id in
            resolver.checklistTemplate(id: id).map(ChecklistEntity.init(from:))
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ChecklistEntity] {
        let resolver = EntityQueryResolver()
        return resolver.searchChecklistTemplates(query: string).map(ChecklistEntity.init(from:))
    }

    @MainActor
    func suggestedEntities() async throws -> [ChecklistEntity] {
        let resolver = EntityQueryResolver()
        return resolver.suggestedChecklistTemplates().map(ChecklistEntity.init(from:))
    }
}
