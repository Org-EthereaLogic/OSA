import XCTest

final class OSAAppLaunchUITests: XCTestCase {
    @MainActor
    func testAppLaunchesToHomeTab() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }
}
