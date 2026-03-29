import XCTest
@testable import OSA

final class SurvivalToolKitTests: XCTestCase {

    func testEncodeMorseIgnoresUnsupportedCharacters() {
        let encoding = SurvivalToolKit.encodeMorse("Go!")

        XCTAssertEqual(encoding.rendered, "--. ---")
        XCTAssertEqual(
            encoding.tokens,
            [.dash, .dash, .dot, .letterGap, .dash, .dash, .dash]
        )
    }

    func testEncodeMorseForSOSProducesStablePulseSequence() {
        let pulses = SurvivalToolKit.signalPulses(for: SurvivalToolKit.encodeMorse("SOS").tokens)

        XCTAssertEqual(
            pulses,
            [
                .signal(units: 1), .pause(units: 1),
                .signal(units: 1), .pause(units: 1),
                .signal(units: 1), .pause(units: 3),
                .signal(units: 3), .pause(units: 1),
                .signal(units: 3), .pause(units: 1),
                .signal(units: 3), .pause(units: 3),
                .signal(units: 1), .pause(units: 1),
                .signal(units: 1), .pause(units: 1),
                .signal(units: 1)
            ]
        )
    }

    func testUnitConversionsMatchRepresentativeValues() {
        XCTAssertEqual(
            SurvivalToolKit.convert(
                value: 0,
                kind: .temperature,
                direction: .forward
            ),
            32,
            accuracy: 0.001
        )
        XCTAssertEqual(
            SurvivalToolKit.convert(
                value: 5,
                kind: .distance,
                direction: .forward
            ),
            8.04672,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            SurvivalToolKit.convert(
                value: 10,
                kind: .gallons,
                direction: .forward
            ),
            37.85411784,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            SurvivalToolKit.convert(
                value: 1_000,
                kind: .ounces,
                direction: .reverse
            ),
            33.8140227,
            accuracy: 0.0001
        )
    }

    func testDeclinationEstimateIsBoundedToSupportedCoverage() {
        let seattleEstimate = SurvivalToolKit.estimateDeclination(latitude: 47.61, longitude: -122.33)
        let unsupportedEstimate = SurvivalToolKit.estimateDeclination(latitude: 35, longitude: -90)

        XCTAssertNotNil(seattleEstimate)
        XCTAssertNil(unsupportedEstimate)
        XCTAssertEqual(seattleEstimate?.formattedValue, "15.6° E")
        XCTAssertEqual(seattleEstimate?.guidance, "Add east, subtract west.")
    }

    func testRadioReferenceEntriesRemainStaticAndCautioned() {
        XCTAssertEqual(SurvivalToolKit.radioReferenceEntries.count, 5)
        XCTAssertTrue(
            SurvivalToolKit.radioReferenceEntries.contains { $0.title == "NOAA Weather Radio" }
        )
        XCTAssertTrue(
            SurvivalToolKit.radioReferenceEntries.contains {
                $0.title == "2 m Amateur Calling Frequency"
                    && $0.caution.contains("legally authorized")
            }
        )
        XCTAssertTrue(SurvivalToolKit.radioDisclaimer.contains("Reference only"))
    }
}
