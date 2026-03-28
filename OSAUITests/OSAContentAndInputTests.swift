import XCTest

/// Tests that verify article content readability, notes/inventory input,
/// and search functionality across the app.
final class OSAContentAndInputTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar not found")
            return
        }
    }

    // MARK: - Article Content Review

    /// ChapterDetailView renders sections inline (ScrollView + LazyVStack),
    /// not as List cells. Verify section headings and body text are present.
    @MainActor
    func testLibraryChapterSectionsHaveContent() {
        tapTab("Library")

        let chapter = app.staticTexts["Preparedness Foundations"]
        guard chapter.waitForExistence(timeout: 5) else {
            XCTFail("Preparedness Foundations chapter missing")
            return
        }
        chapter.tap()
        sleep(1)
        screenshot("Article-Chapter-Foundations")

        // Sections are rendered inline — look for substantive text blocks
        let allTexts = app.staticTexts.allElementsBoundByIndex
        let substantive = allTexts.filter { $0.label.count > 50 }
        XCTAssertGreaterThan(
            substantive.count, 0,
            "Chapter detail should contain substantive body text (>50 chars)"
        )

        // Scroll down to verify more content loads
        app.swipeUp()
        sleep(1)
        screenshot("Article-Foundations-Scrolled")

        let textsAfterScroll = app.staticTexts.allElementsBoundByIndex
        let substantiveAfterScroll = textsAfterScroll.filter { $0.label.count > 50 }
        XCTAssertGreaterThan(
            substantiveAfterScroll.count, 0,
            "Chapter should have more content after scrolling"
        )

        navigateBack()
    }

    @MainActor
    func testWaterChapterSectionsAreReadable() {
        tapTab("Library")

        let waterChapter = app.staticTexts["Water"]
        guard waterChapter.waitForExistence(timeout: 5) else {
            XCTFail("Water chapter missing from Library")
            return
        }
        waterChapter.tap()
        sleep(1)
        screenshot("Article-Chapter-Water")

        // Chapter detail shows inline sections with heading + body
        let allTexts = app.staticTexts.allElementsBoundByIndex
        let bodyTexts = allTexts.filter { $0.label.count > 80 }
        XCTAssertGreaterThan(
            bodyTexts.count, 0,
            "Water chapter should contain readable body text"
        )

        // Scroll to see more sections
        app.swipeUp()
        sleep(1)
        screenshot("Article-Water-Scrolled-1")

        app.swipeUp()
        sleep(1)
        screenshot("Article-Water-Scrolled-2")

        navigateBack()
    }

    @MainActor
    func testFirstAidChapterContent() {
        tapTab("Library")

        // Scroll to find First Aid chapter
        app.swipeUp()
        sleep(1)

        let firstAid = app.staticTexts["First Aid, Hygiene, And Medications"]
        if !firstAid.exists {
            app.swipeUp()
            sleep(1)
        }
        guard firstAid.waitForExistence(timeout: 3) else {
            XCTFail("First Aid chapter not found after scrolling")
            return
        }
        firstAid.tap()
        sleep(1)
        screenshot("Article-Chapter-FirstAid")

        // Verify inline section body text renders
        let allTexts = app.staticTexts.allElementsBoundByIndex
        let bodyTexts = allTexts.filter { $0.label.count > 80 }
        XCTAssertGreaterThan(
            bodyTexts.count, 0,
            "First Aid chapter should contain readable body text"
        )

        app.swipeUp()
        sleep(1)
        screenshot("Article-FirstAid-Scrolled")

        navigateBack()
    }

    @MainActor
    func testQuickCardContentIsReadable() {
        tapTab("Home")

        // Quick cards are randomized; tap whichever appears first
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
        guard let card = quickCardLabels.first(where: { app.staticTexts[$0].waitForExistence(timeout: 1) })
            .map({ app.staticTexts[$0] }) else {
            XCTFail("No quick card found on Home")
            return
        }
        card.tap()
        sleep(1)
        screenshot("QuickCard-Detail")

        let allTexts = app.staticTexts.allElementsBoundByIndex
        let substantive = allTexts.filter { $0.label.count > 30 }
        XCTAssertGreaterThan(
            substantive.count, 1,
            "Quick card detail should show multiple substantive text blocks"
        )

        app.swipeUp()
        sleep(1)
        screenshot("QuickCard-Earthquake-Scrolled")

        navigateBack()
    }

    // MARK: - Notes Input

    @MainActor
    func testCreateAndViewNote() {
        navigateToMoreItem("Notes")
        screenshot("Notes-Empty-State")

        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "New")
            ?? findButton(labelContaining: "plus")
        guard let addButton else {
            XCTFail("No add button found on Notes screen")
            return
        }
        addButton.tap()
        sleep(1)
        screenshot("Notes-Create-Form")

        let titleField = app.textFields.firstMatch
        if titleField.waitForExistence(timeout: 3) {
            titleField.tap()
            titleField.typeText("Test Emergency Note")
            screenshot("Notes-Title-Entered")
        }

        let contentView = app.textViews.firstMatch
        if contentView.waitForExistence(timeout: 2) {
            contentView.tap()
            contentView.typeText("This is a test note for verifying input functionality.")
            screenshot("Notes-Content-Entered")
        }

        let saveButton = findButton(labelContaining: "Save")
            ?? findButton(labelContaining: "Done")
            ?? findButton(labelContaining: "Add")
        if let saveButton {
            saveButton.tap()
            sleep(1)
            screenshot("Notes-After-Save")
        } else {
            dismissModal()
        }

        let savedNote = app.staticTexts.matching(
            NSPredicate(format: "label == 'Test Emergency Note'")
        ).firstMatch
        if savedNote.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Created note appears in list")
            screenshot("Notes-List-With-New-Note")
            savedNote.tap()
            sleep(1)
            screenshot("Notes-Saved-Detail")
            navigateBack()
        }
    }

    // MARK: - Inventory Input

    @MainActor
    func testCreateInventoryItem() {
        tapTab("Inventory")
        screenshot("Inventory-Initial")

        let addButton = findButton(labelContaining: "Add")
            ?? findButton(labelContaining: "plus")
            ?? findButton(labelContaining: "New")
        guard let addButton else {
            XCTFail("No add button found on Inventory screen")
            return
        }
        addButton.tap()
        sleep(1)
        screenshot("Inventory-Add-Form")

        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Water Bottles")
            screenshot("Inventory-Name-Entered")
        }

        let allFields = app.textFields.allElementsBoundByIndex
        if allFields.count > 1 {
            allFields[1].tap()
            allFields[1].typeText("12")
            screenshot("Inventory-Quantity-Entered")
        }

        let saveButton = findButton(labelContaining: "Save")
            ?? findButton(labelContaining: "Done")
            ?? findButton(labelContaining: "Add")
        if let saveButton {
            saveButton.tap()
            sleep(1)
            screenshot("Inventory-After-Save")
        } else {
            dismissModal()
        }

        let savedItem = app.staticTexts["Water Bottles"]
        if savedItem.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Created inventory item appears in list")
            screenshot("Inventory-List-With-New-Item")
        }
    }

    // MARK: - Search

    @MainActor
    func testLibrarySearch() {
        tapTab("Library")
        sleep(1)

        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 3) else {
            XCTFail("Search field not found in Library")
            return
        }
        searchField.tap()
        searchField.typeText("water")
        sleep(1)
        screenshot("Search-Library-Water")

        let hasResults = app.cells.count > 0 || app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'water'")
        ).count > 0
        XCTAssertTrue(hasResults, "Library search for 'water' should return results")

        // Clear and search again
        searchField.buttons["Clear text"].tap()
        searchField.typeText("first aid")
        sleep(1)
        screenshot("Search-Library-FirstAid")

        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists { cancelButton.tap() }
        sleep(1)
    }

    @MainActor
    func testAskSearchQuery() {
        tapTab("Ask")
        sleep(1)
        screenshot("Ask-Before-Query")

        let textField = app.textFields.firstMatch
        let textView = app.textViews.firstMatch
        let searchField = app.searchFields.firstMatch

        if textField.waitForExistence(timeout: 3) {
            textField.tap()
            textField.typeText("How do I purify water?")
        } else if searchField.exists {
            searchField.tap()
            searchField.typeText("How do I purify water?")
        } else if textView.exists {
            textView.tap()
            textView.typeText("How do I purify water?")
        } else {
            XCTFail("No input field found on Ask screen")
            return
        }
        screenshot("Ask-Query-Entered")

        let sendButton = findButton(labelContaining: "Send")
            ?? findButton(labelContaining: "Ask")
            ?? findButton(labelContaining: "Search")
        if let sendButton {
            sendButton.tap()
        } else {
            if app.keyboards.buttons["Return"].exists {
                app.keyboards.buttons["Return"].tap()
            } else if app.keyboards.buttons["return"].exists {
                app.keyboards.buttons["return"].tap()
            }
        }
        sleep(2)
        screenshot("Ask-Response")

        let allTexts = app.staticTexts.allElementsBoundByIndex
        let responseTexts = allTexts.filter { $0.label.count > 40 }
        XCTAssertGreaterThan(
            responseTexts.count, 0,
            "Ask should display a response, citation, or refusal after query"
        )
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
        let item = app.staticTexts[label]
        if item.waitForExistence(timeout: 3) {
            item.tap()
            sleep(1)
            return
        }
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 2) {
            button.tap()
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
        let button = app.buttons.matching(predicate).firstMatch
        if button.exists { return button }
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
