import Foundation

enum InventoryCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case water
    case food
    case power
    case firstAid = "first-aid"
    case lighting
    case communication
    case shelter
    case tools
    case sanitation
    case documents
    case clothing
    case other
}

struct InventoryItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var category: InventoryCategory
    var quantity: Int
    var unit: String
    var location: String
    var notes: String
    var expiryDate: Date?
    var reorderThreshold: Int?
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
}
