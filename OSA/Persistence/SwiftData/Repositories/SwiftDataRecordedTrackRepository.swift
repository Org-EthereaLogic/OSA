import Foundation
import SwiftData

final class SwiftDataRecordedTrackRepository: RecordedTrackRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listTracks() throws -> [RecordedTrack] {
        var descriptor = FetchDescriptor<PersistedRecordedTrack>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func track(id: UUID) throws -> RecordedTrack? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedRecordedTrack>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createTrack(_ track: RecordedTrack) throws {
        let persistedTrack = PersistedRecordedTrack(from: track)
        persistedTrack.points = track.points.map { PersistedRecordedTrackPoint(from: $0, track: persistedTrack) }
        modelContext.insert(persistedTrack)
        try modelContext.save()
    }

    func updateTrack(_ track: RecordedTrack) throws {
        let targetID = track.id
        let descriptor = FetchDescriptor<PersistedRecordedTrack>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: track)
        existing.points.forEach(modelContext.delete)
        existing.points = track.points.map { PersistedRecordedTrackPoint(from: $0, track: existing) }
        try modelContext.save()
    }

    func deleteTrack(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedRecordedTrack>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }
}
