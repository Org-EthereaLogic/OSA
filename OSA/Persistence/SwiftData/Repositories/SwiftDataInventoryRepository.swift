import Foundation
import SwiftData

final class SwiftDataInventoryRepository: InventoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listItems(includeArchived: Bool) throws -> [InventoryItem] {
        var descriptor: FetchDescriptor<PersistedInventoryItem>

        if includeArchived {
            descriptor = FetchDescriptor<PersistedInventoryItem>(
                sortBy: [
                    SortDescriptor(\.categoryRawValue),
                    SortDescriptor(\.name)
                ]
            )
        } else {
            descriptor = FetchDescriptor<PersistedInventoryItem>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [
                    SortDescriptor(\.categoryRawValue),
                    SortDescriptor(\.name)
                ]
            )
        }

        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func item(id: UUID) throws -> InventoryItem? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createItem(_ item: InventoryItem) throws {
        modelContext.insert(PersistedInventoryItem(from: item))
        try modelContext.save()
    }

    func updateItem(_ item: InventoryItem) throws {
        let targetID = item.id
        let descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: item)
        try modelContext.save()
    }

    func archiveItem(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.isArchived = true
        existing.updatedAt = Date()
        try modelContext.save()
    }

    func deleteItem(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        var descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate {
                $0.expiryDate != nil && !$0.isArchived
            },
            sortBy: [SortDescriptor(\.expiryDate)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .filter { record in
                guard let expiry = record.expiryDate else { return false }
                return expiry <= cutoff
            }
            .map { $0.toDomain() }
    }

    func itemsBelowReorderThreshold() throws -> [InventoryItem] {
        var descriptor = FetchDescriptor<PersistedInventoryItem>(
            predicate: #Predicate {
                $0.reorderThreshold != nil && !$0.isArchived
            },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .filter { record in
                guard let threshold = record.reorderThreshold else { return false }
                return record.quantity <= threshold
            }
            .map { $0.toDomain() }
    }
}
