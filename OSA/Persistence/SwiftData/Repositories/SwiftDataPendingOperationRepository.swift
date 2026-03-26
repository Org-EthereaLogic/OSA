import Foundation
import SwiftData

final class SwiftDataPendingOperationRepository: PendingOperationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listOperations(status: OperationStatus?) throws -> [PendingOperation] {
        var descriptor: FetchDescriptor<PersistedPendingOperation>

        if let status {
            let rawValue = status.rawValue
            descriptor = FetchDescriptor<PersistedPendingOperation>(
                predicate: #Predicate { $0.statusRawValue == rawValue },
                sortBy: [SortDescriptor(\.createdAt)]
            )
        } else {
            descriptor = FetchDescriptor<PersistedPendingOperation>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        }

        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func operation(id: UUID) throws -> PendingOperation? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createOperation(_ operation: PendingOperation) throws {
        modelContext.insert(PersistedPendingOperation(from: operation))
        try modelContext.save()
    }

    func updateOperation(_ operation: PendingOperation) throws {
        let targetID = operation.id
        let descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: operation)
        try modelContext.save()
    }

    func deleteOperation(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func nextQueued() throws -> PendingOperation? {
        let queuedRawValue = OperationStatus.queued.rawValue
        var descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.statusRawValue == queuedRawValue },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func failedOperations(maxRetries: Int) throws -> [PendingOperation] {
        let failedRawValue = OperationStatus.failed.rawValue
        var descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.statusRawValue == failedRawValue && $0.retryCount < maxRetries },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func purgeCompleted() throws {
        let completedRawValue = OperationStatus.completed.rawValue
        var descriptor = FetchDescriptor<PersistedPendingOperation>(
            predicate: #Predicate { $0.statusRawValue == completedRawValue }
        )
        descriptor.includePendingChanges = true

        let completed = try modelContext.fetch(descriptor)
        for operation in completed {
            modelContext.delete(operation)
        }
        try modelContext.save()
    }
}
