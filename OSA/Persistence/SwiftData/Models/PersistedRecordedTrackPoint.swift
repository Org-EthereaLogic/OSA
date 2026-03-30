import Foundation
import SwiftData

@Model
final class PersistedRecordedTrackPoint {
    @Attribute(.unique) var id: UUID
    var trackID: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var horizontalAccuracy: Double
    var track: PersistedRecordedTrack?

    init(
        id: UUID,
        trackID: UUID,
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        horizontalAccuracy: Double,
        track: PersistedRecordedTrack? = nil
    ) {
        self.id = id
        self.trackID = trackID
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.track = track
    }
}
