import SwiftData
import XCTest
@testable import OSA

@MainActor
final class TrackRepositoryTests: XCTestCase {
    func testCreateUpdateAndDeleteTrack() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataRecordedTrackRepository(modelContext: container.mainContext)

        var track = makeTrack(title: "Morning Walk", pointCount: 2)
        try repository.createTrack(track)

        let created = try XCTUnwrap(repository.track(id: track.id))
        XCTAssertEqual(created.points.count, 2)
        XCTAssertEqual(created.title, "Morning Walk")

        track.title = "Morning Walk Revised"
        track.points.append(
            RecordedTrackPoint(
                id: UUID(),
                latitude: 45.517,
                longitude: -122.681,
                timestamp: Date(timeIntervalSince1970: 1_700_000_180),
                horizontalAccuracy: 8
            )
        )
        track.totalDistanceMeters = NavigationDistanceCalculator.cumulativeDistance(for: track.points)
        try repository.updateTrack(track)

        let updated = try XCTUnwrap(repository.track(id: track.id))
        XCTAssertEqual(updated.title, "Morning Walk Revised")
        XCTAssertEqual(updated.points.count, 3)
        XCTAssertGreaterThan(updated.totalDistanceMeters, 0)

        try repository.deleteTrack(id: track.id)
        XCTAssertTrue(try repository.listTracks().isEmpty)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistedRecordedTrack.self,
            PersistedRecordedTrackPoint.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeTrack(title: String, pointCount: Int) -> RecordedTrack {
        let baseTime = Date(timeIntervalSince1970: 1_700_000_000)
        let points = (0..<pointCount).map { index in
            RecordedTrackPoint(
                id: UUID(),
                latitude: 45.515 + (Double(index) * 0.001),
                longitude: -122.678 - (Double(index) * 0.001),
                timestamp: baseTime.addingTimeInterval(Double(index) * 60),
                horizontalAccuracy: 6
            )
        }

        return RecordedTrack(
            id: UUID(),
            title: title,
            startedAt: baseTime,
            endedAt: baseTime.addingTimeInterval(Double(pointCount - 1) * 60),
            totalDistanceMeters: NavigationDistanceCalculator.cumulativeDistance(for: points),
            points: points
        )
    }
}
