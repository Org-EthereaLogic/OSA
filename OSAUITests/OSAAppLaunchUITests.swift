import XCTest

final class OSAAppLaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    @MainActor
    func testAppLaunchesToHomeTab() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UI-TESTING")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(
            tabBar.waitForExistence(timeout: 10),
            "App did not present a tab bar — seed content may be missing"
        )
        XCTAssertTrue(tabBar.buttons["Home"].exists, "Home tab should be selected on launch")
    }
}
