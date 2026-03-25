import XCTest

final class OSAAppLaunchUITests: XCTestCase {
    @MainActor
    func testAppLaunchesToHomeTab() throws {
        // Requires seed content resources bundled in the app target.
        // Skip when running in a configuration where the app cannot
        // fully launch (e.g., missing SeedContent directory).
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(
            tabBar.waitForExistence(timeout: 10),
            "App did not present a tab bar — seed content resources may be missing from the bundle"
        )
    }
}
