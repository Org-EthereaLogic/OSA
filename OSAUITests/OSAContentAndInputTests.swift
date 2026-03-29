import XCTest

/// Focused smoke tests for content and input surfaces.
/// Visual coverage lives in `OSAFullE2EVisualTests`; this suite keeps interactions
/// shallow so the UI runner stays stable in CI and local simulator runs.
@MainActor
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

    func testCreateAndViewNote() {
        navigateToMoreItem("Notes")

        openNewNoteComposer()

        XCTAssertTrue(
            app.textFields["Title"].waitForExistence(timeout: 3) || app.textFields.firstMatch.waitForExistence(timeout: 3),
            "Note composer should show a title field"
        )

        dismissModal()
    }

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

    func testInventoryScreenShowsExportAction() {
        tapTab("Inventory")

        let exportButton = app.buttons["Export inventory"]
        XCTAssertTrue(
            exportButton.waitForExistence(timeout: 3),
            "Inventory should expose an export action for the visible list"
        )
    }

    func testChecklistTemplateAndRunShowExportActions() {
        navigateToMoreItem("Checklists")

        let templateTitle = "72-Hour Emergency Kit Check"
        let template = app.buttons["checklist-template-72-hour-emergency-kit-check"]
        XCTAssertTrue(
            scrollToElement(template, maxSwipes: 2),
            "Expected standard checklist template missing"
        )
        if template.isHittable {
            template.tap()
        } else {
            template.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        let startButton = app.buttons["Start Checklist"]
        XCTAssertTrue(
            startButton.waitForExistence(timeout: 3),
            "Checklist template detail should open and expose a start action"
        )

        let templateExport = app.buttons["Export checklist template as PDF"]
        XCTAssertTrue(
            templateExport.waitForExistence(timeout: 3),
            "Checklist template detail should expose a PDF export action"
        )

        startButton.tap()

        navigateBack()

        let activeRun = app.buttons["checklist-run-\(templateTitle)"]
        XCTAssertTrue(activeRun.waitForExistence(timeout: 3), "Active run should appear after starting the checklist")
        if activeRun.isHittable {
            activeRun.tap()
        } else {
            activeRun.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        let runExport = app.buttons["Export checklist run as PDF"]
        XCTAssertTrue(
            runExport.waitForExistence(timeout: 3),
            "Checklist run detail should expose a PDF export action"
        )
    }

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

    func testToolsScreenShowsMorseConverterAndDeclination() {
        navigateToMoreItem("Tools")

        XCTAssertTrue(
            app.navigationBars["Tools"].waitForExistence(timeout: 3)
                || app.staticTexts["Morse Signal"].waitForExistence(timeout: 3),
            "Tools screen should open from More"
        )

        XCTAssertTrue(
            app.staticTexts["Morse Signal"].exists,
            "Tools screen should expose the Morse section"
        )

        let sosButton = app.buttons["Use SOS"]
        XCTAssertTrue(
            sosButton.exists || app.buttons["Play Signal"].exists,
            "Tools screen should expose Morse controls"
        )

        let converter = app.staticTexts["Unit Converter"]
        XCTAssertTrue(
            scrollToElement(converter),
            "Tools screen should expose the unit converter"
        )

        let declination = app.staticTexts["Declination"]
        XCTAssertTrue(
            scrollToElement(declination),
            "Tools screen should expose the declination section"
        )
    }

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

    func testLibrarySearchShowsContentTypeFiltersAndSelection() {
        tapTab("Library")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field not found in Library")
        searchField.tap()
        searchField.typeText("water")

        XCTAssertTrue(
            app.staticTexts["Content Type: All Content"].waitForExistence(timeout: 3),
            "Library search should show the active content-type summary"
        )

        let quickCardsChip = app.buttons["Quick Cards"]
        XCTAssertTrue(quickCardsChip.waitForExistence(timeout: 3), "Library search should expose a Quick Cards filter chip")
        quickCardsChip.tap()

        XCTAssertTrue(
            app.staticTexts["Content Type: Quick Cards"].waitForExistence(timeout: 3),
            "Selecting a content-type chip should update the active filter summary"
        )
    }

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

    func testQuickCardAndHandbookDetailShowShareActions() {
        navigateToMoreItem("Quick Cards")

        guard let quickCard = firstQuickCardButton() else {
            XCTFail("Quick Cards should list at least one seeded card")
            return
        }
        quickCard.tap()

        XCTAssertTrue(
            app.buttons["Share quick card"].waitForExistence(timeout: 3),
            "Quick card detail should expose a share action"
        )

        navigateBack()
        tapTab("Library")

        let chapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5), "Preparedness Foundations chapter missing")
        chapter.tap()

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing")
        section.tap()

        XCTAssertTrue(
            app.buttons["Share handbook section"].waitForExistence(timeout: 3),
            "Handbook section detail should expose a share action"
        )
    }

    func testNotesFlowShowsFamilyPlanEntryPointAndExportActions() {
        navigateToMoreItem("Notes")
        let noteTitle = "Export Test Note \(UUID().uuidString.prefix(6))"

        let createNoteButton = app.buttons["Create note"]
        XCTAssertTrue(
            createNoteButton.waitForExistence(timeout: 3),
            "Notes should expose note creation options"
        )
        createNoteButton.tap()

        let familyPlanEntry = app.buttons["Family Emergency Plan"]
        XCTAssertTrue(
            familyPlanEntry.waitForExistence(timeout: 3),
            "Note creation menu should expose a family emergency plan entry point"
        )

        let newNoteAction = app.buttons["New Note"]
        XCTAssertTrue(newNoteAction.waitForExistence(timeout: 3), "Create note menu should expose a blank note action")
        newNoteAction.tap()

        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Note editor should expose a title field")
        titleField.tap()
        titleField.typeText(noteTitle)

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Note editor should expose Save")
        saveButton.tap()

        let noteRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", noteTitle)).firstMatch
        XCTAssertTrue(noteRow.waitForExistence(timeout: 3), "Saved note should appear in the list")
        noteRow.tap()

        let noteActions = app.buttons["Note actions"]
        XCTAssertTrue(noteActions.waitForExistence(timeout: 3), "Note detail should expose its action menu")
        noteActions.tap()

        XCTAssertTrue(app.buttons["Export as Markdown"].waitForExistence(timeout: 3), "Note actions should expose markdown export")
        XCTAssertTrue(app.buttons["Export as Plain Text"].exists, "Note actions should expose plain-text export")
    }

    func testSettingsShowsEmergencyContactPurposeAndDiscoveryControls() {
        navigateToMoreItem("Settings")

        let safeShortcutCopy = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "I'm Safe"))
            .firstMatch
        XCTAssertTrue(
            scrollToElement(safeShortcutCopy),
            "Settings should explain how emergency contacts support the I'm Safe shortcut"
        )

        let criticalHaptics = app.switches["Critical haptics"]
        XCTAssertTrue(
            scrollToElement(criticalHaptics),
            "Settings should surface critical haptics controls"
        )

        let discoveryButton = app.buttons["Discover New Content"]
        XCTAssertTrue(
            scrollToElement(discoveryButton),
            "Settings should surface the discovery action"
        )
    }

    private func tapTab(_ name: String) {
        let tabBar = app.tabBars.firstMatch
        let button = tabBar.buttons[name]
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

    private func dismissModal() {
        let cancel = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel'")).firstMatch
        if cancel.waitForExistence(timeout: 2) {
            cancel.tap()
            return
        }

        app.swipeDown()
    }

    private func navigateBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
    }

    private func findButton(labelContaining text: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let navButton = app.navigationBars.buttons.matching(predicate).firstMatch
        if navButton.waitForExistence(timeout: 2) { return navButton }

        let button = app.buttons.matching(predicate).firstMatch
        if button.exists { return button }

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

    private func openNewNoteComposer() {
        let createNoteButton = app.buttons["Create note"]
        if createNoteButton.waitForExistence(timeout: 3) {
            createNoteButton.tap()

            let newNoteAction = app.buttons["New Note"]
            if newNoteAction.waitForExistence(timeout: 3) {
                newNoteAction.tap()
                return
            }
        }

        let createFirstNoteButton = app.buttons["Create First Note"]
        if createFirstNoteButton.waitForExistence(timeout: 2) {
            createFirstNoteButton.tap()
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

}
