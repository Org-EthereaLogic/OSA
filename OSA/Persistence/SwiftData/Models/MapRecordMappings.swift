import Foundation

extension PersistedWaypoint {
    convenience init(from waypoint: UserWaypoint) {
        self.init(
            id: waypoint.id,
            title: waypoint.title,
            note: waypoint.note,
            latitude: waypoint.latitude,
            longitude: waypoint.longitude,
            createdAt: waypoint.createdAt,
            categoryRawValue: waypoint.category.rawValue,
            symbolName: waypoint.symbolName
        )
    }

    func update(from waypoint: UserWaypoint) {
        title = waypoint.title
        note = waypoint.note
        latitude = waypoint.latitude
        longitude = waypoint.longitude
        categoryRawValue = waypoint.category.rawValue
        symbolName = waypoint.symbolName
    }

    func toDomain() -> UserWaypoint {
        UserWaypoint(
            id: id,
            title: title,
            note: note,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
            category: UserWaypointCategory(rawValue: categoryRawValue) ?? .general,
            symbolName: symbolName
        )
    }
}

extension PersistedRecordedTrack {
    convenience init(from track: RecordedTrack) {
        self.init(
            id: track.id,
            title: track.title,
            startedAt: track.startedAt,
            endedAt: track.endedAt,
            totalDistanceMeters: track.totalDistanceMeters
        )
    }

    func update(from track: RecordedTrack) {
        title = track.title
        startedAt = track.startedAt
        endedAt = track.endedAt
        totalDistanceMeters = track.totalDistanceMeters
    }

    func toDomain() -> RecordedTrack {
        RecordedTrack(
            id: id,
            title: title,
            startedAt: startedAt,
            endedAt: endedAt,
            totalDistanceMeters: totalDistanceMeters,
            points: points
                .sorted { $0.timestamp < $1.timestamp }
                .map { $0.toDomain() }
        )
    }
}

extension PersistedRecordedTrackPoint {
    convenience init(from point: RecordedTrackPoint, track: PersistedRecordedTrack? = nil) {
        self.init(
            id: point.id,
            trackID: track?.id ?? UUID(),
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.timestamp,
            horizontalAccuracy: point.horizontalAccuracy,
            track: track
        )
    }

    func toDomain() -> RecordedTrackPoint {
        RecordedTrackPoint(
            id: id,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            horizontalAccuracy: horizontalAccuracy
        )
    }
}
