import CoreLocation
import XCTest
@testable import OSA

final class CoordinateFormatterTests: XCTestCase {
    func testDegreesDecimalMinutesFormatting() {
        let coordinate = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let formatted = RescueCoordinateFormatter.degreesDecimalMinutesString(from: coordinate)

        XCTAssertEqual(formatted, "45° 30.912' N, 122° 40.704' W")
    }

    func testDecimalDegreesFormatting() {
        let coordinate = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let formatted = RescueCoordinateFormatter.decimalDegreesString(from: coordinate)

        XCTAssertEqual(formatted, "45.51520, -122.67840")
    }
}
