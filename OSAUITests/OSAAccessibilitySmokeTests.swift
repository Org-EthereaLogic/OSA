import XCTest

@MainActor
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

    func testHomeEmergencyEntryIsAccessible() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Home should expose an Emergency Mode button")
        XCTAssertTrue(emergencyButton.isHittable, "Emergency Mode button should be hittable")
    }

    func testAskInputAndSubmitControlsAreAccessible() {
        tapTab("Ask")

        let input = app.textFields["Ask a question..."]
        XCTAssertTrue(input.waitForExistence(timeout: 3), "Ask screen should expose an accessible question input")

        let submit = app.buttons["Submit question"]
        XCTAssertTrue(submit.exists, "Ask screen should expose an accessible submit button")
        XCTAssertTrue(submit.isHittable, "Submit question button should be hittable")
    }

    func testInventoryExportActionIsAccessible() {
        tapTab("Inventory")

        let exportButton = app.buttons["Export inventory"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Inventory should expose an export action")
        XCTAssertTrue(exportButton.isHittable, "Inventory export action should be hittable")
    }

    func testEmergencyModeExitAndPrimaryActionAreAccessible() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Emergency Mode button missing")
        emergencyButton.tap()

        let exitButton = app.buttons["Exit Emergency Mode"]
        XCTAssertTrue(exitButton.waitForExistence(timeout: 3), "Emergency Mode should expose an explicit exit button")

        let callButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Call 911")).firstMatch
        XCTAssertTrue(callButton.exists, "Emergency Mode should expose the Call 911 action")

        let nightVisionButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Night Vision")).firstMatch
        XCTAssertTrue(nightVisionButton.exists, "Emergency Mode should expose a night vision control")

        let sosButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "SOS")).firstMatch
        XCTAssertTrue(sosButton.exists, "Emergency Mode should expose an SOS alert control")
    }

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

    func testQuickCardAndHandbookShareControlsAreAccessible() {
        navigateToMoreItem("Quick Cards")

        guard let quickCard = firstQuickCardButton() else {
            XCTFail("Quick Cards list should contain at least one seeded card")
            return
        }
        quickCard.tap()

        let quickCardShare = app.buttons["Share quick card"]
        XCTAssertTrue(quickCardShare.waitForExistence(timeout: 3), "Quick card detail should expose a share action")
        XCTAssertTrue(quickCardShare.isHittable, "Quick card share action should be hittable")

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 2), "Quick card detail should expose a back button")
        backButton.tap()

        tapTab("Library")
        let chapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5), "Preparedness Foundations chapter missing")
        chapter.tap()

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing")
        section.tap()

        let handbookShare = app.buttons["Share handbook section"]
        XCTAssertTrue(handbookShare.waitForExistence(timeout: 3), "Handbook detail should expose a share action")
        XCTAssertTrue(handbookShare.isHittable, "Handbook share action should be hittable")
    }

    func testEmergencyModeSurvivalToolsShortcutIsAccessible() {
        tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Emergency Mode button missing")
        emergencyButton.tap()

        let toolsButton = app.buttons["Open Survival Tools"]
        XCTAssertTrue(
            toolsButton.waitForExistence(timeout: 3),
            "Emergency Mode should expose an accessible Survival Tools shortcut"
        )
        XCTAssertTrue(toolsButton.isHittable, "Survival Tools shortcut should be hittable")
    }

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

        let safeShortcutCopy = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "I'm Safe"))
            .firstMatch
        XCTAssertTrue(
            scrollToElement(safeShortcutCopy),
            "Settings should explain how emergency contacts support the I'm Safe shortcut"
        )

        let criticalHapticsToggle = app.switches["Critical haptics"]
        XCTAssertTrue(
            scrollToElement(criticalHapticsToggle),
            "Settings should expose Critical haptics"
        )

        let discoveryButton = app.buttons["Discover New Content"]
        XCTAssertTrue(
            scrollToElement(discoveryButton),
            "Settings should expose Discover New Content"
        )

        let inventoryAlertsToggle = app.switches["Local expiry reminders"]
        XCTAssertTrue(
            scrollToElement(inventoryAlertsToggle),
            "Settings should expose local expiry reminder controls"
        )
    }

    func testLibraryContentTypeFiltersAreAccessible() {
        tapTab("Library")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Library should expose a search field")
        searchField.tap()
        searchField.typeText("water")

        let quickCardsChip = app.buttons["Quick Cards"]
        XCTAssertTrue(quickCardsChip.waitForExistence(timeout: 3), "Library search should expose a Quick Cards filter chip")
        XCTAssertTrue(quickCardsChip.isHittable, "Quick Cards filter chip should be hittable")

        quickCardsChip.tap()

        let summary = app.staticTexts["Content Type: Quick Cards"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3), "Library should expose the active content-type summary")
    }

    private func tapTab(_ name: String) {
        let button = app.tabBars.firstMatch.buttons[name]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

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
