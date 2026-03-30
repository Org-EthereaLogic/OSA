import XCTest
import UIKit

final class OSARotationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments.append("UI-TESTING")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("App did not present a tab bar")
            return
        }
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    @MainActor
    func testCoreTabsRemainUsableAfterRotatingToLandscape() {
        app.tapTab("Home")
        XCTAssertTrue(app.staticTexts["Quick Cards"].waitForExistence(timeout: 3), "Home should render quick cards in portrait")

        rotate(to: .landscapeLeft)
        XCTAssertTrue(app.buttons["Emergency Mode"].waitForExistence(timeout: 3), "Home emergency action should remain visible in landscape")

        app.tapTab("Library")
        let libraryLoaded = app.staticTexts["Field References"].waitForExistence(timeout: 3)
            || app.scrollToElement(app.staticTexts["Preparedness Foundations"], maxSwipes: 6)
        XCTAssertTrue(
            libraryLoaded,
            "Library should remain readable in landscape"
        )

        app.tapTab("Ask")
        XCTAssertTrue(app.textFields["Ask a question..."].waitForExistence(timeout: 3), "Ask input should remain accessible in landscape")

        app.tapTab("Inventory")
        let inventoryLoaded = app.navigationBars["Inventory"].waitForExistence(timeout: 3)
            || app.staticTexts["No Items Yet"].waitForExistence(timeout: 3)
            || app.staticTexts["Unable to Load"].waitForExistence(timeout: 3)
        XCTAssertTrue(inventoryLoaded, "Inventory should remain accessible in landscape")

        rotate(to: .portrait)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 3), "Tab bar should remain available after rotating back to portrait")
    }

    @MainActor
    func testEmergencyAndQuickCardFlowsRemainUsableAcrossRotation() {
        app.tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Emergency Mode should be available from Home")

        rotate(to: .landscapeRight)
        emergencyButton.tap()

        XCTAssertTrue(app.buttons["Exit Emergency Mode"].waitForExistence(timeout: 5), "Emergency mode should open in landscape")
        XCTAssertTrue(app.staticTexts["Protocols"].exists, "Emergency mode should show protocol action cards in landscape")

        rotate(to: .portrait)
        app.buttons["Exit Emergency Mode"].tap()

        guard let quickCard = app.firstQuickCardButton() else {
            XCTFail("A Home quick card should be visible after exiting emergency mode")
            return
        }
        quickCard.tap()

        let detailLoaded = app.staticTexts["Stored locally"].waitForExistence(timeout: 3)
            || app.navigationBars.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(detailLoaded, "Quick card detail should open in portrait")

        rotate(to: .landscapeLeft)
        let landscapeDetailLoaded = app.staticTexts["Stored locally"].waitForExistence(timeout: 3)
            || app.navigationBars.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(landscapeDetailLoaded, "Quick card detail should remain visible in landscape")
    }

    @MainActor
    private func rotate(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        // Wait for layout to settle after rotation
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
    }
}
