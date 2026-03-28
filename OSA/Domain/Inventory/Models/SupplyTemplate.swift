import Foundation

struct SupplyTemplateItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let inventoryCategory: InventoryCategory
    let targetQuantity: Int
    let unit: String
    let matchKeywords: [String]
    let isCritical: Bool
    let scalesWithHouseholdSize: Bool
}

struct SupplyTemplate: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let slug: String
    let scenario: HazardScenario
    let summary: String
    let items: [SupplyTemplateItem]
}

struct SupplyReadinessSnapshot: Equatable, Sendable {
    let title: String
    let scenario: HazardScenario
    let readinessPercent: Int
    let missingCriticalCount: Int
    let nearExpiryCount: Int
}
