import Foundation
import SwiftData

final class SwiftDataKnowledgePackInstallStateRepository: KnowledgePackInstallStateRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listStates() throws -> [KnowledgePackInstallState] {
        var descriptor = FetchDescriptor<PersistedKnowledgePackInstallState>(
            sortBy: [SortDescriptor(\.title)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func state(packIdentifier: String) throws -> KnowledgePackInstallState? {
        let targetIdentifier = packIdentifier
        let descriptor = FetchDescriptor<PersistedKnowledgePackInstallState>(
            predicate: #Predicate { $0.packIdentifier == targetIdentifier }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func saveState(_ state: KnowledgePackInstallState) throws {
        let targetIdentifier = state.packIdentifier
        let descriptor = FetchDescriptor<PersistedKnowledgePackInstallState>(
            predicate: #Predicate { $0.packIdentifier == targetIdentifier }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: state)
        } else {
            modelContext.insert(PersistedKnowledgePackInstallState(from: state))
        }

        try modelContext.save()
    }
}
