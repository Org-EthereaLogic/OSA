import Foundation
import SwiftData

@Model
final class PersistedInventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRawValue: String
    var quantity: Int
    var unit: String
    var location: String
    var notes: String
    var expiryDate: Date?
    var reorderThreshold: Int?
    var tagsJSON: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: UUID,
        name: String,
        categoryRawValue: String,
        quantity: Int,
        unit: String,
        location: String,
        notes: String,
        expiryDate: Date?,
        reorderThreshold: Int?,
        tagsJSON: String,
        createdAt: Date,
        updatedAt: Date,
        isArchived: Bool
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.quantity = quantity
        self.unit = unit
        self.location = location
        self.notes = notes
        self.expiryDate = expiryDate
        self.reorderThreshold = reorderThreshold
        self.tagsJSON = tagsJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
