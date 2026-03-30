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
        app.tapTab("Home")

        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 3), "Home should expose an Emergency Mode button")
        XCTAssertTrue(emergencyButton.isHittable, "Emergency Mode button should be hittable")
    }

    func testAskInputAndSubmitControlsAreAccessible() {
        app.tapTab("Ask")

        let input = app.textFields["Ask a question..."]
        XCTAssertTrue(input.waitForExistence(timeout: 3), "Ask screen should expose an accessible question input")

        let submit = app.buttons["Submit question"]
        XCTAssertTrue(submit.exists, "Ask screen should expose an accessible submit button")
        XCTAssertTrue(submit.isHittable, "Submit question button should be hittable")
    }

    func testInventoryExportActionIsAccessible() {
        app.tapTab("Inventory")

        let exportButton = app.buttons["Export inventory"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Inventory should expose an export action")
        XCTAssertTrue(exportButton.isHittable, "Inventory export action should be hittable")
    }

    func testEmergencyModeExitAndPrimaryActionAreAccessible() {
        app.tapTab("Home")

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
        app.navigateToMoreItem("Quick Cards")

        guard let cardButton = app.firstQuickCardButton() else {
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
        app.navigateToMoreItem("Quick Cards")

        guard let quickCard = app.firstQuickCardButton() else {
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

        XCTAssertTrue(
            app.openLibraryChapter(named: "Preparedness Foundations"),
            "Preparedness Foundations chapter missing from Library"
        )

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing")
        section.tap()

        let handbookShare = app.buttons["Share handbook section"]
        XCTAssertTrue(handbookShare.waitForExistence(timeout: 3), "Handbook detail should expose a share action")
        XCTAssertTrue(handbookShare.isHittable, "Handbook share action should be hittable")
    }

    func testEmergencyModeSurvivalToolsShortcutIsAccessible() {
        app.tapTab("Home")

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
        app.navigateToMoreItem("Settings")

        let extendedSettingsScrollDepth = 12

        let largePrintToggle = app.switches["Large print reading mode"]
        XCTAssertTrue(
            app.scrollToElement(largePrintToggle),
            "Settings should expose Large print reading mode toggle"
        )

        let languagePicker = app.segmentedControls["settings-app-language-picker"]
        XCTAssertTrue(
            app.scrollToElement(languagePicker),
            "Settings should expose the app language picker"
        )

        let highContrastToggle = app.switches["settings-high-contrast-toggle"]
        XCTAssertTrue(
            app.scrollToElement(highContrastToggle),
            "Settings should expose High contrast mode"
        )

        let addContact = app.buttons["Add Emergency Contact"]
        XCTAssertTrue(
            app.scrollToElement(addContact, maxSwipes: extendedSettingsScrollDepth),
            "Settings should expose Add Emergency Contact"
        )

        let safeShortcutCopy = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "I'm Safe"))
            .firstMatch
        XCTAssertTrue(
            app.scrollToElement(safeShortcutCopy, maxSwipes: extendedSettingsScrollDepth),
            "Settings should explain how emergency contacts support the I'm Safe shortcut"
        )

        let criticalHapticsToggle = app.switches["Critical haptics"]
        XCTAssertTrue(
            app.scrollToElement(criticalHapticsToggle, maxSwipes: extendedSettingsScrollDepth),
            "Settings should expose Critical haptics"
        )

        let inventoryAlertsToggle = app.switches["Local expiry reminders"]
        XCTAssertTrue(
            app.scrollToElement(inventoryAlertsToggle, maxSwipes: extendedSettingsScrollDepth),
            "Settings should expose local expiry reminder controls"
        )

        let discoveryButton = app.buttons["Discover New Content"]
        XCTAssertTrue(
            app.scrollToElement(discoveryButton, maxSwipes: extendedSettingsScrollDepth),
            "Settings should expose Discover New Content"
        )
    }

    func testLibraryContentTypeFiltersAreAccessible() {
        app.tapTab("Library")

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
}
