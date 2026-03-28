import Foundation

final class BundledSupplyTemplateRepository: SupplyTemplateRepository {
    private let templates: [SupplyTemplate]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "supply-templates-core-v1", withExtension: "json", subdirectory: "SeedContent"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SupplyTemplateSeedPack.self, from: data)
        else {
            self.templates = []
            return
        }

        self.templates = decoded.templates.map(\.toDomain)
    }

    func listTemplates() -> [SupplyTemplate] {
        templates.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func template(for scenario: HazardScenario) -> SupplyTemplate? {
        templates.first { $0.scenario == scenario }
    }
}

private struct SupplyTemplateSeedPack: Decodable {
    let templates: [SupplyTemplateFile]
}

private struct SupplyTemplateFile: Decodable {
    let id: UUID
    let title: String
    let slug: String
    let scenario: HazardScenario
    let summary: String
    let items: [SupplyTemplateItemFile]

    var toDomain: SupplyTemplate {
        SupplyTemplate(
            id: id,
            title: title,
            slug: slug,
            scenario: scenario,
            summary: summary,
            items: items.map(\.toDomain)
        )
    }
}

private struct SupplyTemplateItemFile: Decodable {
    let id: UUID
    let title: String
    let inventoryCategory: InventoryCategory
    let targetQuantity: Int
    let unit: String
    let matchKeywords: [String]
    let isCritical: Bool
    let scalesWithHouseholdSize: Bool?

    var toDomain: SupplyTemplateItem {
        SupplyTemplateItem(
            id: id,
            title: title,
            inventoryCategory: inventoryCategory,
            targetQuantity: targetQuantity,
            unit: unit,
            matchKeywords: matchKeywords,
            isCritical: isCritical,
            scalesWithHouseholdSize: scalesWithHouseholdSize ?? false
        )
    }
}
