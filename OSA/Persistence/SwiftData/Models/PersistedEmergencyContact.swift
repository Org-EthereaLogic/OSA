import Foundation
import SwiftData

@Model
final class PersistedEmergencyContact {
    @Attribute(.unique) var id: UUID
    var name: String
    var relationship: String
    var phoneNumber: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        relationship: String,
        phoneNumber: String,
        notes: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
