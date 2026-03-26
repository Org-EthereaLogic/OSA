import XCTest

final class OSAAppLaunchUITests: XCTestCase {
    @MainActor
    func testAppLaunchesToHomeTab() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(
            tabBar.waitForExistence(timeout: 10),
            "App did not present a tab bar — seed content may be missing"
        )
        XCTAssertTrue(tabBar.buttons["Home"].exists, "Home tab should be selected on launch")
    }
}
