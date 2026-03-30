import Foundation
import SwiftData

final class SwiftDataWaypointRepository: WaypointRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listWaypoints() throws -> [UserWaypoint] {
        var descriptor = FetchDescriptor<PersistedWaypoint>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func waypoint(id: UUID) throws -> UserWaypoint? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedWaypoint>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createWaypoint(_ waypoint: UserWaypoint) throws {
        modelContext.insert(PersistedWaypoint(from: waypoint))
        try modelContext.save()
    }

    func updateWaypoint(_ waypoint: UserWaypoint) throws {
        let targetID = waypoint.id
        let descriptor = FetchDescriptor<PersistedWaypoint>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: waypoint)
        try modelContext.save()
    }

    func deleteWaypoint(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedWaypoint>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }
}
