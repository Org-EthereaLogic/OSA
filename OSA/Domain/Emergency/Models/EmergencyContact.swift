import Foundation

struct EmergencyContact: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var relationship: String
    var phoneNumber: String
    var notes: String
    let createdAt: Date
    var updatedAt: Date
}
