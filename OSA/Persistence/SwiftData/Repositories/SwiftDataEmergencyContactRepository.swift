import Foundation
import SwiftData

final class SwiftDataEmergencyContactRepository: EmergencyContactRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listContacts() throws -> [EmergencyContact] {
        var descriptor = FetchDescriptor<PersistedEmergencyContact>(
            sortBy: [
                SortDescriptor(\.relationship),
                SortDescriptor(\.name)
            ]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func contact(id: UUID) throws -> EmergencyContact? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedEmergencyContact>(
            predicate: #Predicate { $0.id == targetID }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createContact(_ contact: EmergencyContact) throws {
        modelContext.insert(PersistedEmergencyContact(from: contact))
        try modelContext.save()
    }

    func updateContact(_ contact: EmergencyContact) throws {
        let targetID = contact.id
        let descriptor = FetchDescriptor<PersistedEmergencyContact>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: contact)
        try modelContext.save()
    }

    func deleteContact(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedEmergencyContact>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }
}
