import Foundation

protocol SupplyTemplateRepository: Sendable {
    func listTemplates() -> [SupplyTemplate]
    func template(for scenario: HazardScenario) -> SupplyTemplate?
}
