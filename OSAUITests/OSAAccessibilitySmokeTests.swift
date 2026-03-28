import XCTest

final class OSAAccessibilitySmokeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments.append("UI-TESTING")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar not found")
            return
        }
    }

    @MainActor
    func testHomeEmergencyEntryIsAccessible() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Home should expose an Emergency Mode button")
        XCTAssertTrue(emergencyButton.isHittable, "Emergency Mode button should be hittable")
    }

    @MainActor
    func testAskInputAndSubmitControlsAreAccessible() {
        tapTab("Ask")

        let input = app.textFields["Ask a question..."]
        XCTAssertTrue(input.waitForExistence(timeout: 3), "Ask screen should expose an accessible question input")

        let submit = app.buttons["Submit question"]
        XCTAssertTrue(submit.exists, "Ask screen should expose an accessible submit button")
        XCTAssertTrue(submit.isHittable, "Submit question button should be hittable")
    }

    @MainActor
    func testEmergencyModeExitAndPrimaryActionAreAccessible() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Emergency Mode button missing")
        emergencyButton.tap()

        let exitButton = app.buttons["Exit Emergency Mode"]
        XCTAssertTrue(exitButton.waitForExistence(timeout: 3), "Emergency Mode should expose an explicit exit button")

        let callButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Call 911")).firstMatch
        XCTAssertTrue(callButton.exists, "Emergency Mode should expose the Call 911 action")
    }

    @MainActor
    func testQuickCardDetailPinControlIsAccessible() {
        navigateToMoreItem("Quick Cards")

        guard let cardButton = firstQuickCardButton() else {
            XCTFail("Quick Cards list should contain at least one quick card")
            return
        }
        cardButton.tap()

        let pinButton = app.buttons["Pin quick card"].firstMatch
        let unpinButton = app.buttons["Unpin quick card"].firstMatch
        XCTAssertTrue(
            pinButton.waitForExistence(timeout: 3) || unpinButton.waitForExistence(timeout: 3),
            "Quick card detail should expose an accessible pin control"
        )
    }

    @MainActor
    func testSettingsAccessibilityControlsExist() {
        navigateToMoreItem("Settings")

        let largePrintToggle = app.switches["Large print reading mode"]
        XCTAssertTrue(
            scrollToElement(largePrintToggle),
            "Settings should expose Large print reading mode toggle"
        )

        let addContact = app.buttons["Add Emergency Contact"]
        XCTAssertTrue(
            scrollToElement(addContact),
            "Settings should expose Add Emergency Contact"
        )

        let discoveryButton = app.buttons["Discover New Content"]
        XCTAssertTrue(
            scrollToElement(discoveryButton),
            "Settings should expose Discover New Content"
        )
    }

    @MainActor
    private func tapTab(_ name: String) {
        let button = app.tabBars.firstMatch.buttons[name]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    @MainActor
    private func navigateToMoreItem(_ label: String) {
        tapTab("More")

        let item = app.staticTexts[label]
        if item.waitForExistence(timeout: 3) {
            item.tap()
            return
        }

        let button = app.buttons[label]
        if button.waitForExistence(timeout: 2) {
            button.tap()
        }
    }

    @MainActor
    private func firstQuickCardButton() -> XCUIElement? {
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
            let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }

        return nil
    }

    @MainActor
    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        if element.waitForExistence(timeout: 1) {
            return true
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }
}
