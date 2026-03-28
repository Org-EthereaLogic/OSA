import XCTest
@testable import OSA

final class WeatherAlertServiceTests: XCTestCase {

    func testLiveServiceUsesRegistryFeeds() {
        // Verify that the weather feed entries exist in the registry
        let weatherFeeds = RSSFeedRegistry.allFeedEntries
            .filter { $0.host == "api.weather.gov" || $0.host == "wcatwc.arh.noaa.gov" }
        XCTAssertFalse(weatherFeeds.isEmpty, "Weather feeds should be registered")
        XCTAssertEqual(weatherFeeds.filter { $0.host == "api.weather.gov" }.count, 2)
        XCTAssertEqual(weatherFeeds.filter { $0.host == "wcatwc.arh.noaa.gov" }.count, 1)
    }

    func testWeatherAlertSeverityRawValues() {
        XCTAssertEqual(WeatherAlertSeverity(rawValue: "extreme"), .extreme)
        XCTAssertEqual(WeatherAlertSeverity(rawValue: "severe"), .severe)
        XCTAssertEqual(WeatherAlertSeverity(rawValue: "moderate"), .moderate)
        XCTAssertEqual(WeatherAlertSeverity(rawValue: "minor"), .minor)
        XCTAssertEqual(WeatherAlertSeverity(rawValue: "unknown"), .unknown)
        XCTAssertNil(WeatherAlertSeverity(rawValue: "invalid"))
    }

    func testForecastCacheInfoStaleness() {
        let fresh = ForecastCacheInfo(fetchedAt: Date(), isStale: false)
        XCTAssertFalse(fresh.isStale)

        let stale = ForecastCacheInfo(fetchedAt: Date().addingTimeInterval(-7200), isStale: true)
        XCTAssertTrue(stale.isStale)
        XCTAssertFalse(stale.stalenessDescription.isEmpty)
    }
}
