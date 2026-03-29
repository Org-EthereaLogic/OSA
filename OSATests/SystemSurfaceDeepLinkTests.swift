import XCTest
@testable import OSA

final class SystemSurfaceDeepLinkTests: XCTestCase {
    func testEmergencyModeRoundTripsThroughURL() {
        let deepLink = SystemSurfaceDeepLink.emergencyMode

        XCTAssertEqual(SystemSurfaceDeepLink(url: deepLink.url), deepLink)
    }

    func testQuickCardRoundTripsThroughURL() {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let deepLink = SystemSurfaceDeepLink.quickCard(id)

        XCTAssertEqual(SystemSurfaceDeepLink(url: deepLink.url), deepLink)
    }

    func testChecklistRunRoundTripsThroughURL() {
        let id = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        let deepLink = SystemSurfaceDeepLink.checklistRun(id)

        XCTAssertEqual(SystemSurfaceDeepLink(url: deepLink.url), deepLink)
    }

    func testRejectsUnknownHost() {
        let url = URL(string: "lantern://unknown")!

        XCTAssertNil(SystemSurfaceDeepLink(url: url))
    }

    func testRejectsMalformedQuickCardIdentifier() {
        let url = URL(string: "lantern://quick-card/not-a-uuid")!

        XCTAssertNil(SystemSurfaceDeepLink(url: url))
    }
}
