import Foundation

/// Thin App Intents-facing resolver that bridges `SearchService` ranking
/// with repository hydration to produce typed entity results.
///
/// All entity query types share this helper so search, ranking, deduplication,
/// and stale-hit handling are implemented once.
@MainActor
struct EntityQueryResolver {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = SharedRuntime.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Handbook Sections

    struct HydratedSection: Sendable {
        let section: HandbookSection
        let chapterTitle: String
    }

    func searchHandbookSections(query: String, limit: Int = 10) -> [HydratedSection] {
        guard let searchService = dependencies.searchService else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let hits = (try? searchService.search(
            query: trimmed,
            scopes: [.handbookSection],
            limit: limit
        )) ?? []

        return hydrateHandbookSections(hits)
    }

    func handbookSection(id: UUID) -> HydratedSection? {
        guard let section = try? dependencies.handbookRepository.section(id: id) else { return nil }
        let chapterTitle = (try? dependencies.handbookRepository.chapter(id: section.chapterID))?.title ?? ""
        return HydratedSection(section: section, chapterTitle: chapterTitle)
    }

    func suggestedHandbookSections(limit: Int = 5) -> [HydratedSection] {
        guard let chapters = try? dependencies.handbookRepository.listChapters() else { return [] }
        var results: [HydratedSection] = []
        for chapter in chapters.prefix(limit) {
            guard let full = try? dependencies.handbookRepository.chapter(id: chapter.id) else { continue }
            for section in full.sections.prefix(2) {
                results.append(HydratedSection(section: section, chapterTitle: full.title))
                if results.count >= limit { return results }
            }
        }
        return results
    }

    // MARK: - Quick Cards

    func searchQuickCards(query: String, limit: Int = 10) -> [QuickCard] {
        guard let searchService = dependencies.searchService else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let hits = (try? searchService.search(
            query: trimmed,
            scopes: [.quickCard],
            limit: limit
        )) ?? []

        return hydrateQuickCards(hits)
    }

    func quickCard(id: UUID) -> QuickCard? {
        try? dependencies.quickCardRepository.quickCard(id: id)
    }

    func suggestedQuickCards(limit: Int = 5) -> [QuickCard] {
        let all = (try? dependencies.quickCardRepository.listQuickCards()) ?? []
        return Array(all.prefix(limit))
    }

    // MARK: - Checklist Templates

    func searchChecklistTemplates(query: String, limit: Int = 10) -> [ChecklistTemplateSummary] {
        guard let searchService = dependencies.searchService else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let hits = (try? searchService.search(
            query: trimmed,
            scopes: [.checklistTemplate],
            limit: limit
        )) ?? []

        return hydrateChecklistTemplates(hits)
    }

    func checklistTemplate(id: UUID) -> ChecklistTemplateSummary? {
        guard let template = try? dependencies.checklistRepository.template(id: id) else { return nil }
        return template.summaryValue
    }

    func suggestedChecklistTemplates(limit: Int = 5) -> [ChecklistTemplateSummary] {
        let all = (try? dependencies.checklistRepository.listTemplates()) ?? []
        return Array(all.prefix(limit))
    }

    // MARK: - Inventory Items

    func searchInventoryItems(query: String, limit: Int = 10) -> [InventoryItem] {
        guard let searchService = dependencies.searchService else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let hits = (try? searchService.search(
            query: trimmed,
            scopes: [.inventoryItem],
            limit: limit
        )) ?? []

        return hydrateInventoryItems(hits)
    }

    func inventoryItem(id: UUID) -> InventoryItem? {
        guard let item = try? dependencies.inventoryRepository.item(id: id) else { return nil }
        guard !item.isArchived else { return nil }
        return item
    }

    func suggestedInventoryItems(limit: Int = 5) -> [InventoryItem] {
        let all = (try? dependencies.inventoryRepository.listItems(includeArchived: false)) ?? []
        return Array(all.prefix(limit))
    }

    // MARK: - Private Hydration

    private func hydrateHandbookSections(_ hits: [SearchResult]) -> [HydratedSection] {
        var seen = Set<UUID>()
        var results: [HydratedSection] = []
        for hit in hits where hit.kind == .handbookSection {
            guard seen.insert(hit.id).inserted else { continue }
            guard let hydrated = handbookSection(id: hit.id) else { continue }
            results.append(hydrated)
        }
        return results
    }

    private func hydrateQuickCards(_ hits: [SearchResult]) -> [QuickCard] {
        var seen = Set<UUID>()
        var results: [QuickCard] = []
        for hit in hits where hit.kind == .quickCard {
            guard seen.insert(hit.id).inserted else { continue }
            guard let card = try? dependencies.quickCardRepository.quickCard(id: hit.id) else { continue }
            results.append(card)
        }
        return results
    }

    private func hydrateChecklistTemplates(_ hits: [SearchResult]) -> [ChecklistTemplateSummary] {
        var seen = Set<UUID>()
        var results: [ChecklistTemplateSummary] = []
        for hit in hits where hit.kind == .checklistTemplate {
            guard seen.insert(hit.id).inserted else { continue }
            guard let template = try? dependencies.checklistRepository.template(id: hit.id) else { continue }
            results.append(template.summaryValue)
        }
        return results
    }

    private func hydrateInventoryItems(_ hits: [SearchResult]) -> [InventoryItem] {
        var seen = Set<UUID>()
        var results: [InventoryItem] = []
        for hit in hits where hit.kind == .inventoryItem {
            guard seen.insert(hit.id).inserted else { continue }
            guard let item = try? dependencies.inventoryRepository.item(id: hit.id),
                  !item.isArchived else { continue }
            results.append(item)
        }
        return results
    }
}
