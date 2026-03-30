import Foundation
import SwiftData

final class SwiftDataDocumentVaultRepository: DocumentVaultRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listEntries() throws -> [DocumentVaultEntry] {
        var descriptor = FetchDescriptor<PersistedDocumentVaultEntry>(
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func entry(id: UUID) throws -> DocumentVaultEntry? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedDocumentVaultEntry>(
            predicate: #Predicate { $0.id == targetID }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createEntry(_ entry: DocumentVaultEntry) throws {
        modelContext.insert(PersistedDocumentVaultEntry(from: entry))
        try modelContext.save()
    }

    func updateEntry(_ entry: DocumentVaultEntry) throws {
        let targetID = entry.id
        let descriptor = FetchDescriptor<PersistedDocumentVaultEntry>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: entry)
        try modelContext.save()
    }

    func deleteEntry(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedDocumentVaultEntry>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }
}
