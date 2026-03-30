import Foundation
import XCTest
@testable import OSA

final class GPXExporterTests: XCTestCase {
    func testGPXStringContainsTrackMetadataAndPoints() {
        let track = makeTrack()

        let gpx = GPXExporter.gpxString(for: track)

        XCTAssertTrue(gpx.contains("<gpx version=\"1.1"))
        XCTAssertTrue(gpx.contains("River Route"))
        XCTAssertTrue(gpx.contains("<trkpt lat=\"45.515\" lon=\"-122.678\">"))
    }

    func testExportFileWritesGPX() throws {
        let track = makeTrack()
        let fileURL = try GPXExporter.exportFile(for: track)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("<trkseg>"))
        XCTAssertTrue(contents.contains("</gpx>"))
    }

    private func makeTrack() -> RecordedTrack {
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        return RecordedTrack(
            id: UUID(),
            title: "River Route",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(120),
            totalDistanceMeters: 340,
            points: [
                RecordedTrackPoint(
                    id: UUID(),
                    latitude: 45.515,
                    longitude: -122.678,
                    timestamp: startedAt,
                    horizontalAccuracy: 6
                ),
                RecordedTrackPoint(
                    id: UUID(),
                    latitude: 45.516,
                    longitude: -122.679,
                    timestamp: startedAt.addingTimeInterval(60),
                    horizontalAccuracy: 6
                )
            ]
        )
    }
}
