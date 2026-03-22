import XCTest

final class OSAAppLaunchUITests: XCTestCase {
    func testAppLaunchesToHomeTab() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }
}
