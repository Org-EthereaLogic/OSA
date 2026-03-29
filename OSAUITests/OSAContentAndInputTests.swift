import XCTest

/// Focused smoke tests for content and input surfaces.
/// Visual coverage lives in `OSAFullE2EVisualTests`; this suite keeps interactions
/// shallow so the UI runner stays stable in CI and local simulator runs.
final class OSAContentAndInputTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments.append("UI-TESTING")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar not found")
            return
        }
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    @MainActor
    func testLibraryChapterSectionsHaveContent() {
        tapTab("Library")

        let chapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5), "Preparedness Foundations chapter missing")
        chapter.tap()

        XCTAssertTrue(
            app.navigationBars["Preparedness Foundations"].waitForExistence(timeout: 3),
            "Chapter detail should open with the chapter title"
        )
        XCTAssertTrue(
            app.staticTexts["Curated"].exists || app.cells.firstMatch.waitForExistence(timeout: 3),
            "Chapter detail should show curated metadata or section rows"
        )
    }

    @MainActor
    func testWaterChapterSectionsAreReadable() {
        tapTab("Library")

        let waterChapter = app.staticTexts["Water"]
        XCTAssertTrue(waterChapter.waitForExistence(timeout: 5), "Water chapter missing from Library")
        waterChapter.tap()

        XCTAssertTrue(
            app.navigationBars["Water"].waitForExistence(timeout: 3),
            "Water chapter detail should open"
        )
        XCTAssertTrue(
            app.cells.firstMatch.waitForExistence(timeout: 3),
            "Water chapter should show section rows"
        )
    }

    @MainActor
    func testQuickCardContentIsReadable() {
        tapTab("Home")

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

        guard let cardLabel = quickCardLabels.first(where: {
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", $0)).firstMatch.waitForExistence(timeout: 1)
        }) else {
            XCTFail("No quick card found on Home")
            return
        }

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardLabel)).firstMatch
        let cardTitle = cardLabel
        card.tap()

        XCTAssertTrue(
            app.navigationBars[cardTitle].waitForExistence(timeout: 3)
                || app.staticTexts["Stored locally"].waitForExistence(timeout: 3),
            "Quick card detail should open"
        )
    }

    @MainActor
    func testCreateAndViewNote() {
        navigateToMoreItem("Notes")

        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "New")
            ?? findButton(labelContaining: "plus")
        XCTAssertNotNil(addButton, "Notes screen should provide an add button")

        addButton?.tap()

        XCTAssertTrue(
            app.textFields.firstMatch.waitForExistence(timeout: 3),
            "Note composer should show a title field"
        )

        dismissModal()
    }

    @MainActor
    func testCreateInventoryItem() {
        tapTab("Inventory")

        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "plus")
            ?? findButton(labelContaining: "New")
        XCTAssertNotNil(addButton, "Inventory screen should provide an add button")

        addButton?.tap()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 3) || app.textFields.firstMatch.exists,
            "Inventory form should show a name field"
        )

        dismissModal()
    }

    @MainActor
    func testQuickCardsSearch() {
        navigateToMoreItem("Quick Cards")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Quick Cards search field should appear")

        searchField.tap()
        searchField.typeText("water")

        XCTAssertTrue(
            app.staticTexts["Water Rotation Check"].waitForExistence(timeout: 3),
            "Quick Cards search for 'water' should show the water card"
        )
    }

    @MainActor
    func testLibrarySearch() {
        tapTab("Library")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field not found in Library")

        searchField.tap()
        searchField.typeText("water")

        XCTAssertTrue(
            app.staticTexts["Water"].waitForExistence(timeout: 3)
                || app.cells.firstMatch.waitForExistence(timeout: 3),
            "Library search for 'water' should show results"
        )
    }

    @MainActor
    func testLibraryShowsRecentlyViewedAfterOpeningSection() {
        tapTab("Library")

        let chapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5), "Preparedness Foundations chapter missing")
        chapter.tap()

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing from Preparedness Foundations")
        section.tap()

        XCTAssertTrue(
            app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 3),
            "Section detail should allow navigation back"
        )

        navigateBack()
        if !app.staticTexts["Recently Viewed"].exists {
            navigateBack()
        }

        XCTAssertTrue(
            app.staticTexts["Recently Viewed"].waitForExistence(timeout: 3),
            "Library should show Recently Viewed after opening a handbook section"
        )
    }

    @MainActor
    func testAskInputBarAcceptsQuery() {
        tapTab("Ask")

        let textField = app.textFields["Ask a question..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "Ask screen should show a query field")

        textField.tap()
        textField.typeText("How do I purify water?")

        XCTAssertTrue(
            app.buttons["Submit question"].exists || app.keyboards.buttons["Return"].exists || app.keyboards.buttons["return"].exists,
            "Ask screen should expose a submit action after entering a query"
        )
    }

    @MainActor
    private func tapTab(_ name: String) {
        let tabBar = app.tabBars.firstMatch
        let button = tabBar.buttons[name]
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
    private func dismissModal() {
        let cancel = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel'")).firstMatch
        if cancel.waitForExistence(timeout: 2) {
            cancel.tap()
            return
        }

        app.swipeDown()
    }

    @MainActor
    private func navigateBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
    }

    @MainActor
    private func findButton(labelContaining text: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let navButton = app.navigationBars.buttons.matching(predicate).firstMatch
        if navButton.waitForExistence(timeout: 2) { return navButton }

        let button = app.buttons.matching(predicate).firstMatch
        if button.exists { return button }

        return nil
    }
}
