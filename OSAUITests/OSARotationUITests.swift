import UIKit
import XCTest

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
        tapTab("Home")
        XCTAssertTrue(app.staticTexts["Quick Cards"].waitForExistence(timeout: 3), "Home should render quick cards in portrait")

        rotate(to: .landscapeLeft)
        XCTAssertTrue(app.buttons["Emergency Mode"].waitForExistence(timeout: 3), "Home emergency action should remain visible in landscape")

        tapTab("Library")
        XCTAssertTrue(app.staticTexts["Preparedness Foundations"].waitForExistence(timeout: 5), "Library should remain readable in landscape")

        tapTab("Ask")
        XCTAssertTrue(app.textFields["Ask a question..."].waitForExistence(timeout: 3), "Ask input should remain accessible in landscape")

        tapTab("Inventory")
        let inventoryLoaded = app.navigationBars["Inventory"].waitForExistence(timeout: 3)
            || app.staticTexts["No Items Yet"].waitForExistence(timeout: 3)
            || app.staticTexts["Unable to Load"].waitForExistence(timeout: 3)
        XCTAssertTrue(inventoryLoaded, "Inventory should remain accessible in landscape")

        rotate(to: .portrait)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 3), "Tab bar should remain available after rotating back to portrait")
    }

    @MainActor
    func testEmergencyAndQuickCardFlowsRemainUsableAcrossRotation() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Emergency Mode should be available from Home")

        rotate(to: .landscapeRight)
        emergencyButton.tap()

        XCTAssertTrue(app.buttons["Exit Emergency Mode"].waitForExistence(timeout: 5), "Emergency mode should open in landscape")
        XCTAssertTrue(app.staticTexts["Protocols"].exists, "Emergency mode should show protocol action cards in landscape")

        rotate(to: .portrait)
        app.buttons["Exit Emergency Mode"].tap()

        let quickCard = firstVisibleQuickCardButton()
        XCTAssertTrue(quickCard.waitForExistence(timeout: 3), "A Home quick card should remain tappable after rotation")
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
    private func tapTab(_ name: String) {
        let tabBar = app.tabBars.firstMatch
        let button = tabBar.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Tab '\(name)' should exist")
        button.tap()
        waitForUIToSettle()
    }

    @MainActor
    private func rotate(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        waitForUIToSettle()
    }

    @MainActor
    private func firstVisibleQuickCardButton() -> XCUIElement {
        let quickCardLabels = [
            "Earthquake Drop-Cover-Hold",
            "First Hour Power Outage Check",
            "Boil Water Advisory Steps",
            "Gas Leak Response",
            "Go-Bag Grab List",
            "Family Meeting Point Reminder",
            "Severe Weather Shelter Steps",
            "Refrigerator Food Safety Timer",
            "Water Rotation Check",
            "Home Medication Check",
            "Smoke And CO Detector Check",
            "Vehicle Breakdown Safety Steps",
            "Utility Shutoff Quick Reference",
            "Winter Storm Home Preparation"
        ]

        for label in quickCardLabels {
            let candidate = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if candidate.waitForExistence(timeout: 1) {
                return candidate
            }
        }

        return app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quick Card'")).firstMatch
    }

    @MainActor
    private func waitForUIToSettle() {
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
        sleep(1)
    }
}
