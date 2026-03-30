import CoreLocation
import Foundation
import XCTest
@testable import OSA

final class SunCompassCalculatorTests: XCTestCase {
    func testSunAzimuthMovesWestAsDayAdvances() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let calendar = Calendar(identifier: .gregorian)

        let morning = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    timeZone: timeZone,
                    year: 2026,
                    month: 6,
                    day: 21,
                    hour: 9,
                    minute: 0
                )
            )
        )

        let afternoon = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    timeZone: timeZone,
                    year: 2026,
                    month: 6,
                    day: 21,
                    hour: 15,
                    minute: 0
                )
            )
        )

        let morningAzimuth = try XCTUnwrap(
            SunCompassCalculator.azimuth(at: morning, coordinate: coordinate, timeZone: timeZone)
        )
        let afternoonAzimuth = try XCTUnwrap(
            SunCompassCalculator.azimuth(at: afternoon, coordinate: coordinate, timeZone: timeZone)
        )

        XCTAssertTrue(0...360 ~= morningAzimuth)
        XCTAssertTrue(0...360 ~= afternoonAzimuth)
        XCTAssertLessThan(morningAzimuth, afternoonAzimuth)
    }

    func testSunCompassReadingIncludesGuidance() {
        let coordinate = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let reading = SunCompassCalculator.reading(
            at: Date(timeIntervalSince1970: 1_718_989_200),
            coordinate: coordinate,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        XCTAssertNotNil(reading)
        XCTAssertFalse(reading?.guidance.isEmpty ?? true)
    }
}
