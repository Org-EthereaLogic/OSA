import Foundation
import SwiftData

@Model
final class PersistedWaypoint {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String?
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var categoryRawValue: String
    var symbolName: String?

    init(
        id: UUID,
        title: String,
        note: String?,
        latitude: Double,
        longitude: Double,
        createdAt: Date,
        categoryRawValue: String,
        symbolName: String?
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.categoryRawValue = categoryRawValue
        self.symbolName = symbolName
    }
}
