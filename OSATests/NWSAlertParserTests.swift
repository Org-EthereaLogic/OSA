import XCTest
@testable import OSA

final class NWSAlertParserTests: XCTestCase {

    // MARK: - Atom + CAP Parsing

    func testParsesNWSAtomFeedWithCAPElements() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
            <entry>
                <title>Flood Warning</title>
                <link rel="alternate" href="https://api.weather.gov/alerts/urn:oid:123"/>
                <summary>Heavy rain expected in the area.</summary>
                <cap:severity>Severe</cap:severity>
                <cap:areaDesc>Multnomah County, OR</cap:areaDesc>
                <cap:effective>2026-03-28T12:00:00Z</cap:effective>
                <cap:expires>2026-03-29T12:00:00Z</cap:expires>
            </entry>
        </feed>
        """
        let parser = NWSAlertParser(feedHost: "api.weather.gov")
        let alerts = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(alerts.count, 1)
        let alert = alerts[0]
        XCTAssertEqual(alert.title, "Flood Warning")
        XCTAssertEqual(alert.alertURL.absoluteString, "https://api.weather.gov/alerts/urn:oid:123")
        XCTAssertEqual(alert.severity, .severe)
        XCTAssertEqual(alert.areaDescription, "Multnomah County, OR")
        XCTAssertEqual(alert.summary, "Heavy rain expected in the area.")
        XCTAssertNotNil(alert.effectiveDate)
        XCTAssertNotNil(alert.expiresDate)
        XCTAssertEqual(alert.sourceHost, "api.weather.gov")
    }

    func testParsesMultipleAlerts() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
            <entry>
                <title>Winter Storm Warning</title>
                <link rel="alternate" href="https://api.weather.gov/alerts/1"/>
                <summary>Heavy snow expected.</summary>
                <cap:severity>Moderate</cap:severity>
                <cap:areaDesc>Cascades</cap:areaDesc>
            </entry>
            <entry>
                <title>Tsunami Warning</title>
                <link rel="alternate" href="https://api.weather.gov/alerts/2"/>
                <summary>Tsunami advisory.</summary>
                <cap:severity>Extreme</cap:severity>
                <cap:areaDesc>Oregon Coast</cap:areaDesc>
            </entry>
        </feed>
        """
        let parser = NWSAlertParser(feedHost: "api.weather.gov")
        let alerts = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(alerts.count, 2)
        XCTAssertEqual(alerts[0].severity, .moderate)
        XCTAssertEqual(alerts[1].severity, .extreme)
    }

    func testEmptyFeedReturnsNoAlerts() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom"></feed>
        """
        let parser = NWSAlertParser(feedHost: "api.weather.gov")
        let alerts = parser.parse(data: Data(xml.utf8))
        XCTAssertTrue(alerts.isEmpty)
    }

    func testMalformedXMLDoesNotCrash() {
        let xml = "not xml at all <><><>"
        let parser = NWSAlertParser(feedHost: "api.weather.gov")
        let alerts = parser.parse(data: Data(xml.utf8))
        XCTAssertTrue(alerts.isEmpty)
    }

    func testSeverityMappingFromCAP() {
        let severities = [
            ("Extreme", WeatherAlertSeverity.extreme),
            ("Severe", WeatherAlertSeverity.severe),
            ("Moderate", WeatherAlertSeverity.moderate),
            ("Minor", WeatherAlertSeverity.minor),
            ("Unknown", WeatherAlertSeverity.unknown),
            ("", WeatherAlertSeverity.unknown),
        ]
        for (raw, expected) in severities {
            let xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <feed xmlns="http://www.w3.org/2005/Atom" xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
                <entry>
                    <title>Test Alert</title>
                    <link rel="alternate" href="https://api.weather.gov/alerts/test"/>
                    <cap:severity>\(raw)</cap:severity>
                </entry>
            </feed>
            """
            let parser = NWSAlertParser(feedHost: "api.weather.gov")
            let alerts = parser.parse(data: Data(xml.utf8))
            XCTAssertEqual(alerts.first?.severity, expected, "Expected \(expected) for CAP severity '\(raw)'")
        }
    }

    func testRSSItemFormatParsing() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <item>
                    <title>Tsunami Information Statement</title>
                    <link>https://wcatwc.arh.noaa.gov/events/123</link>
                    <description>No threat to the coastline.</description>
                </item>
            </channel>
        </rss>
        """
        let parser = NWSAlertParser(feedHost: "wcatwc.arh.noaa.gov")
        let alerts = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts[0].title, "Tsunami Information Statement")
        XCTAssertEqual(alerts[0].sourceHost, "wcatwc.arh.noaa.gov")
    }
}
