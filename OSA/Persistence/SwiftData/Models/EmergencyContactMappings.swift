import Foundation

extension PersistedEmergencyContact {
    convenience init(from contact: EmergencyContact) {
        self.init(
            id: contact.id,
            name: contact.name,
            relationship: contact.relationship,
            phoneNumber: contact.phoneNumber,
            notes: contact.notes,
            createdAt: contact.createdAt,
            updatedAt: contact.updatedAt
        )
    }

    func update(from contact: EmergencyContact) {
        name = contact.name
        relationship = contact.relationship
        phoneNumber = contact.phoneNumber
        notes = contact.notes
        updatedAt = contact.updatedAt
    }

    func toDomain() -> EmergencyContact {
        EmergencyContact(
            id: id,
            name: name,
            relationship: relationship,
            phoneNumber: phoneNumber,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
