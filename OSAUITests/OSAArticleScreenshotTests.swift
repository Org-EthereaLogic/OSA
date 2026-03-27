import XCTest

/// Quick screenshot captures of article content for visual review.
final class OSAArticleScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureWaterArticleScreenshots() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else { return }

        tabBar.buttons["Library"].tap()
        sleep(1)

        let water = app.staticTexts["Water"]
        guard water.waitForExistence(timeout: 5) else {
            XCTFail("Water chapter not found")
            return
        }
        water.tap()
        sleep(2)

        // Capture multiple scroll positions to review all content
        for i in 0..<6 {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "Water-Article-Page-\(i)"
            shot.lifetime = .keepAlways
            add(shot)

            if i < 5 { app.swipeUp(); sleep(1) }
        }
    }

    @MainActor
    func testCaptureQuickCardScreenshots() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else { return }

        tabBar.buttons["Home"].tap()
        sleep(1)

        let card = app.staticTexts["Earthquake Drop-Cover-Hold"]
        guard card.waitForExistence(timeout: 3) else { return }
        card.tap()
        sleep(1)

        for i in 0..<3 {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "QuickCard-Earthquake-Page-\(i)"
            shot.lifetime = .keepAlways
            add(shot)

            if i < 2 { app.swipeUp(); sleep(1) }
        }
    }
}
