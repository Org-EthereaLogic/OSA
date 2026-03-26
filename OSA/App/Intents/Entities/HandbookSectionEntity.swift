import AppIntents
import CoreSpotlight
import Foundation

/// App Entity representing a handbook section, discoverable through
/// Siri, Shortcuts, and Spotlight.
struct HandbookSectionEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Handbook Section",
        numericFormat: "\(placeholder: .int) handbook sections"
    )

    static let defaultQuery = HandbookSectionEntityQuery()

    let id: UUID
    let heading: String
    let chapterTitle: String

    var displayRepresentation: DisplayRepresentation {
        let subtitle = chapterTitle.isEmpty ? nil : chapterTitle
        return DisplayRepresentation(
            title: "\(heading)",
            subtitle: subtitle.map { LocalizedStringResource(stringLiteral: $0) }
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = heading
        if !chapterTitle.isEmpty {
            attributes.contentDescription = chapterTitle
        }
        return attributes
    }

    init(id: UUID, heading: String, chapterTitle: String) {
        self.id = id
        self.heading = heading
        self.chapterTitle = chapterTitle
    }

    init(from hydrated: EntityQueryResolver.HydratedSection) {
        self.id = hydrated.section.id
        self.heading = hydrated.section.heading
        self.chapterTitle = hydrated.chapterTitle
    }
}

// MARK: - Entity Query

struct HandbookSectionEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [HandbookSectionEntity] {
        let resolver = EntityQueryResolver()
        return identifiers.compactMap { id in
            resolver.handbookSection(id: id).map(HandbookSectionEntity.init(from:))
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [HandbookSectionEntity] {
        let resolver = EntityQueryResolver()
        return resolver.searchHandbookSections(query: string).map(HandbookSectionEntity.init(from:))
    }

    @MainActor
    func suggestedEntities() async throws -> [HandbookSectionEntity] {
        let resolver = EntityQueryResolver()
        return resolver.suggestedHandbookSections().map(HandbookSectionEntity.init(from:))
    }
}
