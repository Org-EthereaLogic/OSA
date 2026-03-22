import XCTest
@testable import OSA

final class OSAAppSmokeTests: XCTestCase {
    func testPrimaryTabsExposeExpectedTitles() {
        XCTAssertEqual(AppTab.home.title, "Home")
        XCTAssertEqual(AppTab.library.title, "Library")
        XCTAssertEqual(AppTab.ask.title, "Ask")
        XCTAssertEqual(AppTab.inventory.title, "Inventory")
    }
}
