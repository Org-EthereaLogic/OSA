import XCTest
@testable import OSA

final class AccessibilitySettingsTests: XCTestCase {
    func testAppLanguageDefaultsToEnglishForUnknownValue() {
        XCTAssertEqual(AccessibilitySettings.appLanguage(from: "unknown"), .english)
    }

    func testAppLanguageRoundTripsStoredSpanishValue() {
        XCTAssertEqual(AccessibilitySettings.appLanguage(from: AppLanguage.spanish.rawValue), .spanish)
    }
}
