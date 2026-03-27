import XCTest

/// Full end-to-end visual walk-through of every tab and key drill-in screen.
/// Each test navigates to a surface and asserts that expected elements exist,
/// logging any missing content or broken navigation.
final class OSAFullE2EVisualTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("App did not present a tab bar — seed content may be missing")
            return
        }
    }

    // MARK: - Tab Navigation

    @MainActor
    func testAllTabsAccessible() {
        let tabBar = app.tabBars.firstMatch

        let expectedTabs = ["Home", "Library", "Ask", "Inventory", "More"]
        for tab in expectedTabs {
            let button = tabBar.buttons[tab]
            XCTAssertTrue(button.exists, "Tab '\(tab)' should exist in the tab bar")
        }
    }

    // MARK: - Home Tab

    @MainActor
    func testHomeScreenContent() {
        tapTab("Home")

        // Hero brand card — BrandWordmarkView renders as Image with accessibility label
        let brandImage = app.images["Lantern"]
        let brandLabel = app.otherElements.matching(
            NSPredicate(format: "label == 'Lantern'")
        ).firstMatch
        XCTAssertTrue(
            brandImage.waitForExistence(timeout: 5) || brandLabel.exists,
            "Lantern brand mark should appear on Home hero card"
        )

        // Quick Cards section
        XCTAssertTrue(
            app.staticTexts["Quick Cards"].exists,
            "Quick Cards section header should appear on Home"
        )

        // At least one quick card
        XCTAssertTrue(
            app.staticTexts["Earthquake Drop-Cover-Hold"].exists,
            "Earthquake quick card should appear on Home"
        )

        // Active Checklists section
        XCTAssertTrue(
            app.staticTexts["Active Checklists"].exists,
            "Active Checklists section header should appear on Home"
        )

        screenshot("Home-Tab")
    }

    @MainActor
    func testHomeTapQuickCard() {
        tapTab("Home")

        let card = app.staticTexts["Earthquake Drop-Cover-Hold"]
        guard card.waitForExistence(timeout: 3) else {
            XCTFail("Earthquake quick card not found on Home")
            return
        }
        card.tap()
        sleep(1)

        screenshot("Home-QuickCard-Detail")

        // Navigate back
        navigateBack()
    }

    @MainActor
    func testHomeScrollToBottom() {
        tapTab("Home")

        app.swipeUp()
        sleep(1)
        screenshot("Home-Scrolled-1")

        app.swipeUp()
        sleep(1)
        screenshot("Home-Scrolled-2")

        // Bottom sections may or may not have data — just verify no crash
    }

    // MARK: - Library Tab

    @MainActor
    func testLibraryScreenContent() {
        tapTab("Library")

        // Actual seed chapter titles from handbook-foundations-v1.json
        let firstChapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(
            firstChapter.waitForExistence(timeout: 5),
            "Preparedness Foundations chapter should appear in Library"
        )

        // Check a few more chapters are visible
        let waterChapter = app.staticTexts["Water"]
        XCTAssertTrue(waterChapter.exists, "Water chapter should appear in Library")

        screenshot("Library-Tab")
    }

    @MainActor
    func testLibraryDrillIntoChapter() {
        tapTab("Library")

        let chapter = app.staticTexts["Preparedness Foundations"]
        guard chapter.waitForExistence(timeout: 5) else {
            XCTFail("Preparedness Foundations chapter not found")
            return
        }
        chapter.tap()
        sleep(1)

        screenshot("Library-Chapter-Detail")

        // Should show sections — at least some text content
        let hasSections = app.cells.count > 0 || app.staticTexts.count > 2
        XCTAssertTrue(hasSections, "Chapter detail should show sections or content")

        // Tap into a section if available
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()
            sleep(1)
            screenshot("Library-Section-Detail")
            navigateBack()
        }

        navigateBack()
    }

    @MainActor
    func testLibraryScrollChapterList() {
        tapTab("Library")
        sleep(1)

        app.swipeUp()
        sleep(1)
        screenshot("Library-Scrolled")

        // Check a chapter further down the list
        let fireChapter = app.staticTexts["Fire And Lighting"]
        let goChapter = app.staticTexts["Go-Bags"]
        XCTAssertTrue(
            fireChapter.exists || goChapter.exists,
            "Later chapters should be visible after scrolling"
        )
    }

    // MARK: - Ask Tab

    @MainActor
    func testAskScreenContent() {
        tapTab("Ask")

        screenshot("Ask-Tab")

        // Ask screen should show some form of UI — text field, prompt, or scope controls
        let hasAskUI = app.textFields.count > 0
            || app.textViews.count > 0
            || app.searchFields.count > 0
            || app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ask'")).count > 0
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'question'")).count > 0
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Ask'")).count > 0
        XCTAssertTrue(hasAskUI, "Ask screen should present input or prompt UI")
    }

    // MARK: - Inventory Tab

    @MainActor
    func testInventoryScreenContent() {
        tapTab("Inventory")

        screenshot("Inventory-Tab")

        // May show empty state or category-grouped items
        // Just verify the screen loaded without crash
        let hasContent = app.staticTexts.count > 0 || app.cells.count > 0
        XCTAssertTrue(hasContent, "Inventory screen should render content or empty state")
    }

    @MainActor
    func testInventoryAddItem() {
        tapTab("Inventory")

        // Look for add button in nav bar or toolbar
        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "plus")
            ?? findButton(labelContaining: "New")

        guard let addButton else { return }  // No add button is OK

        addButton.tap()
        sleep(1)
        screenshot("Inventory-Add-Item")

        // Dismiss
        dismissModal()
    }

    // MARK: - More Tab > Checklists

    @MainActor
    func testChecklistsScreen() {
        navigateToMoreItem("Checklists")

        screenshot("Checklists-Screen")

        // Look for a seed checklist template
        let goChecklist = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Go-Bag' OR label CONTAINS[c] 'Go Bag'")
        ).firstMatch
        let anyChecklist = app.cells.firstMatch
        XCTAssertTrue(
            goChecklist.waitForExistence(timeout: 3) || anyChecklist.exists,
            "Checklists should show templates"
        )

        // Tap into a template if found
        if anyChecklist.exists {
            anyChecklist.tap()
            sleep(1)
            screenshot("Checklist-Template-Detail")
            navigateBack()
        }
    }

    // MARK: - More Tab > Quick Cards

    @MainActor
    func testQuickCardsScreen() {
        navigateToMoreItem("Quick Cards")

        screenshot("QuickCards-Screen")

        let firstCard = app.cells.firstMatch
        if firstCard.waitForExistence(timeout: 3) {
            firstCard.tap()
            sleep(1)
            screenshot("QuickCard-Detail-FromList")
            navigateBack()
        }
    }

    // MARK: - More Tab > Notes

    @MainActor
    func testNotesScreen() {
        navigateToMoreItem("Notes")

        screenshot("Notes-Screen")

        // Try add note
        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "New")
            ?? findButton(labelContaining: "plus")

        if let addButton {
            addButton.tap()
            sleep(1)
            screenshot("Notes-New-Note")
            dismissModal()
        }
    }

    // MARK: - More Tab > Settings

    @MainActor
    func testSettingsScreen() {
        navigateToMoreItem("Settings")

        screenshot("Settings-Screen")

        // Look for About section or Version label
        let aboutSection = app.staticTexts["About"]
        let versionLabel = app.staticTexts["Version"]
        let lanternLabel = app.staticTexts[AppBrand.subtitle]
        let anySettingsContent = aboutSection.waitForExistence(timeout: 3)
            || versionLabel.exists
            || lanternLabel.exists
            || app.switches.count > 0
        XCTAssertTrue(anySettingsContent, "Settings should show About, Version, or toggle controls")
    }

    // MARK: - Helpers

    @MainActor
    private func tapTab(_ name: String) {
        let tabBar = app.tabBars.firstMatch
        let button = tabBar.buttons[name]
        if button.waitForExistence(timeout: 3) {
            button.tap()
            sleep(1)
        }
    }

    @MainActor
    private func navigateToMoreItem(_ label: String) {
        tapTab("More")

        // On iPhone with sidebarAdaptable, "More" presents a list
        let item = app.staticTexts[label]
        if item.waitForExistence(timeout: 3) {
            item.tap()
            sleep(1)
            return
        }

        // Fallback — try buttons or cells
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 2) {
            button.tap()
            sleep(1)
            return
        }

        let cell = app.cells.matching(
            NSPredicate(format: "label CONTAINS[c] %@", label)
        ).firstMatch
        if cell.waitForExistence(timeout: 2) {
            cell.tap()
            sleep(1)
        }
    }

    @MainActor
    private func navigateBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
            sleep(1)
        }
    }

    @MainActor
    private func dismissModal() {
        let cancel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Cancel'")
        ).firstMatch
        if cancel.exists {
            cancel.tap()
            sleep(1)
        } else {
            app.swipeDown()
            sleep(1)
        }
    }

    @MainActor
    private func findButton(labelContaining text: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let navButton = app.navigationBars.buttons.matching(predicate).firstMatch
        if navButton.waitForExistence(timeout: 2) { return navButton }

        let toolbarButton = app.buttons.matching(predicate).firstMatch
        if toolbarButton.exists { return toolbarButton }

        return nil
    }

    @MainActor
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// Mirror AppBrand constants for test assertions
private enum AppBrand {
    static let subtitle = "Offline Preparedness Guide"
}
