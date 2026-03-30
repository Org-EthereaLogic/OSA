import Foundation
import SwiftData

@Model
final class PersistedRecordedTrack {
    @Attribute(.unique) var id: UUID
    var title: String
    var startedAt: Date
    var endedAt: Date?
    var totalDistanceMeters: Double
    @Relationship(deleteRule: .cascade, inverse: \PersistedRecordedTrackPoint.track)
    var points: [PersistedRecordedTrackPoint]

    init(
        id: UUID,
        title: String,
        startedAt: Date,
        endedAt: Date?,
        totalDistanceMeters: Double,
        points: [PersistedRecordedTrackPoint] = []
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.totalDistanceMeters = totalDistanceMeters
        self.points = points
    }
}
