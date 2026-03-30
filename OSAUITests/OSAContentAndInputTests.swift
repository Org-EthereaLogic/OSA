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
        XCTAssertTrue(
            app.openLibraryChapter(named: "Preparedness Foundations"),
            "Preparedness Foundations chapter missing from Library"
        )

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
        XCTAssertTrue(
            app.openLibraryChapter(named: "Water"),
            "Water chapter missing from Library"
        )

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
        app.tapTab("Home")

        guard let cardLabel = app.firstVisibleQuickCardLabel() else {
            XCTFail("No quick card found on Home")
            return
        }

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardLabel)).firstMatch
        card.tap()

        XCTAssertTrue(
            app.navigationBars[cardLabel].waitForExistence(timeout: 3)
                || app.staticTexts["Stored locally"].waitForExistence(timeout: 3),
            "Quick card detail should open"
        )
    }

    func testSettingsLanguagePickerCanSwitchToSpanish() {
        app.navigateToMoreItem("Settings")

        let languagePicker = app.segmentedControls["settings-app-language-picker"]
        XCTAssertTrue(
            app.scrollToElement(languagePicker),
            "Settings should expose the app language picker"
        )

        let spanishButton = languagePicker.buttons["Espanol"]
        XCTAssertTrue(spanishButton.waitForExistence(timeout: 3), "Spanish segment should be visible")
        spanishButton.tap()

        XCTAssertTrue(
            app.staticTexts["Modo de alto contraste"].waitForExistence(timeout: 3)
                || app.staticTexts["Idioma de la app"].waitForExistence(timeout: 3),
            "Switching to Spanish should update visible Settings copy"
        )
    }

    func testQuickCardDetailLoadsWithLargePrintEnabled() {
        app.navigateToMoreItem("Settings")

        let largePrintToggle = app.switches["settings-large-print-toggle"]
        XCTAssertTrue(
            app.scrollToElement(largePrintToggle),
            "Settings should expose the large print toggle"
        )
        if "\(largePrintToggle.value)" == "0" {
            largePrintToggle.tap()
        }

        app.navigateToMoreItem("Quick Cards")

        guard let cardLabel = app.firstVisibleQuickCardLabel() else {
            XCTFail("Expected seeded quick card missing")
            return
        }

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardLabel)).firstMatch
        card.tap()

        XCTAssertTrue(
            app.navigationBars[cardLabel].waitForExistence(timeout: 3)
                || app.staticTexts["Stored locally"].waitForExistence(timeout: 3),
            "Quick card detail should still load with large print enabled"
        )
    }

    func testCreateAndViewNote() {
        app.navigateToMoreItem("Notes")

        app.openNewNoteComposer()

        XCTAssertTrue(
            app.textFields["Title"].waitForExistence(timeout: 3) || app.textFields.firstMatch.waitForExistence(timeout: 3),
            "Note composer should show a title field"
        )

        app.dismissModal()
    }

    func testCreateInventoryItem() {
        app.tapTab("Inventory")

        let addButton = app.findButton(labelContaining: "Add")
            ?? app.findButton(labelContaining: "plus")
            ?? app.findButton(labelContaining: "New")
        XCTAssertNotNil(addButton, "Inventory screen should provide an add button")

        addButton?.tap()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 3) || app.textFields.firstMatch.exists,
            "Inventory form should show a name field"
        )

        app.dismissModal()
    }

    func testInventoryFormShowsSprint11CaptureAffordances() {
        app.tapTab("Inventory")

        let addButton = app.findButton(labelContaining: "Add")
            ?? app.findButton(labelContaining: "plus")
            ?? app.findButton(labelContaining: "New")
        XCTAssertNotNil(addButton, "Inventory screen should provide an add button")
        addButton?.tap()

        XCTAssertTrue(
            app.buttons["inventory-form-scan-code"].waitForExistence(timeout: 3),
            "Inventory form should show a scan action"
        )
        XCTAssertTrue(
            app.buttons["inventory-form-capture-photo"].waitForExistence(timeout: 3),
            "Inventory form should show a camera capture action"
        )
        XCTAssertTrue(
            app.buttons["inventory-form-import-photo"].waitForExistence(timeout: 3),
            "Inventory form should show a photo import action"
        )
        XCTAssertTrue(
            app.buttons["inventory-form-recognize-label"].waitForExistence(timeout: 3),
            "Inventory form should show a local OCR action"
        )

        app.dismissModal()
    }

    func testInventoryScreenShowsExportAction() {
        app.tapTab("Inventory")

        let exportButton = app.buttons["Export inventory"]
        XCTAssertTrue(
            exportButton.waitForExistence(timeout: 3),
            "Inventory should expose an export action for the visible list"
        )
    }

    func testChecklistTemplateAndRunShowExportActions() {
        app.navigateToMoreItem("Checklists")

        let template = app.buttons["checklist-template-72-hour-emergency-kit-check"]
        guard app.scrollToElement(template, maxSwipes: 10) else {
            XCTFail("Expected standard checklist template missing")
            return
        }
        if template.isHittable {
            template.tap()
        } else {
            template.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        // Confirm navigation succeeded — toolbar export button appears before the list scrolls
        let templateExport = app.buttons["Export checklist template as PDF"]
        XCTAssertTrue(
            templateExport.waitForExistence(timeout: 5),
            "Checklist template detail should open and expose a PDF export action"
        )

        // "Start Checklist" is in the last list section and may be off-screen on first render
        let startButton = app.buttons["Start Checklist"]
        guard app.scrollToElement(startButton, maxSwipes: 3) else {
            XCTFail("Checklist template detail should expose a start action")
            return
        }

        let templateTitle = "72-Hour Emergency Kit Check"
        startButton.tap()

        app.tapTab("Home")

        let activeRunQuery = app.buttons.matching(identifier: "home-checklist-run-\(templateTitle)")
        var activeRun = app.firstHittableElement(in: activeRunQuery)
        for _ in 0..<6 where activeRun == nil {
            app.swipeUp()
            activeRun = app.firstHittableElement(in: activeRunQuery)
        }

        guard let activeRun else {
            XCTFail("Active run should appear on Home after starting the checklist")
            return
        }
        activeRun.tap()

        let runExport = app.buttons["Export checklist run as PDF"]
        let runActions = app.buttons["Checklist actions"]
        XCTAssertTrue(
            runExport.waitForExistence(timeout: 5) || runActions.waitForExistence(timeout: 5),
            "Checklist run detail should open and expose its toolbar actions"
        )
    }

    func testQuickCardsSearch() {
        app.navigateToMoreItem("Quick Cards")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Quick Cards search field should appear")

        searchField.tap()
        searchField.typeText("rotation")

        XCTAssertTrue(
            app.staticTexts["Water Rotation Check"].waitForExistence(timeout: 3),
            "Quick Cards search for 'rotation' should show the water rotation card"
        )
    }

    func testHomeWeeklyDrillOpensPracticeReadyQuickCard() {
        app.tapTab("Home")

        let weeklyDrill = app.buttons["home-weekly-drill-card"]
        XCTAssertTrue(
            app.scrollToElement(weeklyDrill, maxSwipes: 3),
            "Home should expose the weekly drill card"
        )

        weeklyDrill.tap()

        XCTAssertTrue(
            app.buttons["quick-card-start-quiz"].waitForExistence(timeout: 3)
                || app.staticTexts["Practice Quiz"].waitForExistence(timeout: 3),
            "Weekly drill detail should expose the local quiz entry point"
        )
    }

    func testLibraryShowsRopeAndKnotsReferenceQuizEntry() {
        app.tapTab("Library")

        let categoryCell = app.cells.containing(.staticText, identifier: "Rope And Knots").firstMatch
        XCTAssertTrue(
            app.scrollToElement(categoryCell, maxSwipes: 6),
            "Library should show the Rope And Knots field reference category"
        )
        categoryCell.tap()

        let entryCell = app.cells.containing(.staticText, identifier: "Bowline Reference").firstMatch
        XCTAssertTrue(
            app.scrollToElement(entryCell, maxSwipes: 4),
            "Bowline Reference should appear in the Rope And Knots category"
        )
        entryCell.tap()

        XCTAssertTrue(
            app.buttons["field-reference-start-quiz"].waitForExistence(timeout: 3)
                || app.staticTexts["Practice Quiz"].waitForExistence(timeout: 3),
            "Bowline field reference detail should expose the local quiz entry point"
        )
    }

    func testToolsScreenShowsMorseConverterAndDeclination() {
        app.navigateToMoreItem("Tools")

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
            app.scrollToElement(converter),
            "Tools screen should expose the unit converter"
        )

        let declination = app.staticTexts["Declination"]
        XCTAssertTrue(
            app.scrollToElement(declination),
            "Tools screen should expose the declination section"
        )
    }

    func testLibrarySearch() {
        app.tapTab("Library")

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
        app.tapTab("Library")

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
        XCTAssertTrue(
            app.openLibraryChapter(named: "Preparedness Foundations"),
            "Preparedness Foundations chapter missing from Library"
        )

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing from Preparedness Foundations")
        section.tap()

        XCTAssertTrue(
            app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 3),
            "Section detail should allow navigation back"
        )

        app.navigateBack()
        if !app.staticTexts["Recently Viewed"].exists {
            app.navigateBack()
        }
        app.scrollToTop()

        XCTAssertTrue(
            app.scrollToElement(app.staticTexts["Recently Viewed"], maxSwipes: 2),
            "Library should show Recently Viewed after opening a handbook section"
        )
    }

    func testAskInputBarAcceptsQuery() {
        app.tapTab("Ask")

        let textField = app.textFields["Ask a question..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "Ask screen should show a query field")

        textField.tap()
        textField.typeText("How do I purify water?")

        XCTAssertTrue(
            app.buttons["Submit question"].exists || app.keyboards.buttons["Return"].exists || app.keyboards.buttons["return"].exists,
            "Ask screen should expose a submit action after entering a query"
        )
    }

    func testAskShowsRecentQuestionsAndStudyGuideActionAfterAnswer() {
        app.tapTab("Ask")

        app.submitAskQuestion("Boil Water Advisory Steps")

        XCTAssertTrue(
            app.staticTexts["Recent Questions"].waitForExistence(timeout: 8),
            "Ask should show recent questions after a successful answer"
        )
        XCTAssertTrue(
            app.buttons["Save Study Guide"].waitForExistence(timeout: 8),
            "Ask should expose a study-guide action after a grounded answer"
        )
    }

    func testAskRecentQuestionCanBeTappedToRerun() {
        app.tapTab("Ask")

        let question = "Boil Water Advisory Steps"
        app.submitAskQuestion(question)

        let textField = app.textFields["Ask a question..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "Ask screen should keep its input visible")
        textField.tap()
        textField.typeText(" later")

        let recentQuestion = app.buttons.matching(identifier: "recent-question").firstMatch
        XCTAssertTrue(
            recentQuestion.waitForExistence(timeout: 5),
            "Ask should show the previous question as a recent-question shortcut"
        )
        recentQuestion.tap()

        XCTAssertEqual(
            textField.value as? String,
            question,
            "Tapping a recent question should restore that question for a fresh local search"
        )
        XCTAssertTrue(
            app.buttons["Save Study Guide"].waitForExistence(timeout: 8),
            "Rerunning a recent question should return to an answered state"
        )
    }

    func testQuickCardAndHandbookDetailShowShareActions() {
        app.navigateToMoreItem("Quick Cards")

        guard let quickCard = app.firstQuickCardButton() else {
            XCTFail("Quick Cards should list at least one seeded card")
            return
        }
        quickCard.tap()

        XCTAssertTrue(
            app.buttons["Share quick card"].waitForExistence(timeout: 3),
            "Quick card detail should expose a share action"
        )

        app.navigateBack()
        XCTAssertTrue(
            app.openLibraryChapter(named: "Preparedness Foundations"),
            "Preparedness Foundations chapter missing from Library"
        )

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected handbook section missing")
        section.tap()

        XCTAssertTrue(
            app.buttons["Share handbook section"].waitForExistence(timeout: 3),
            "Handbook section detail should expose a share action"
        )
    }

    func testNotesFlowShowsFamilyPlanEntryPointAndExportActions() {
        app.navigateToMoreItem("Notes")
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
        app.navigateToMoreItem("Settings")

        let extendedSettingsScrollDepth = 12

        let safeShortcutCopy = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "I'm Safe"))
            .firstMatch
        XCTAssertTrue(
            app.scrollToElement(safeShortcutCopy, maxSwipes: extendedSettingsScrollDepth),
            "Settings should explain how emergency contacts support the I'm Safe shortcut"
        )

        let criticalHaptics = app.switches["Critical haptics"]
        XCTAssertTrue(
            app.scrollToElement(criticalHaptics, maxSwipes: extendedSettingsScrollDepth),
            "Settings should surface critical haptics controls"
        )

        let discoveryButton = app.buttons["Discover New Content"]
        XCTAssertTrue(
            app.scrollToElement(discoveryButton, maxSwipes: extendedSettingsScrollDepth),
            "Settings should surface the discovery action"
        )
    }

    func testDocumentVaultOpensInLockedState() {
        app.navigateToMoreItem("Document Vault")

        XCTAssertTrue(
            app.staticTexts["Vault Locked"].waitForExistence(timeout: 3)
                || app.buttons["document-vault-unlock"].waitForExistence(timeout: 3),
            "Document Vault should require an explicit local unlock"
        )
    }

    func testSettingsExposeKnowledgePackManagement() {
        app.navigateToMoreItem("Settings")

        let knowledgePackLink = app.otherElements["settings-knowledge-packs"]
        let knowledgePackText = app.staticTexts["Knowledge Packs"]
        XCTAssertTrue(
            app.scrollToElement(knowledgePackLink, maxSwipes: 10) || app.scrollToElement(knowledgePackText, maxSwipes: 10),
            "Settings should expose Knowledge Packs inside the knowledge-discovery area"
        )

        if knowledgePackLink.exists {
            knowledgePackLink.tap()
        } else {
            knowledgePackText.tap()
        }

        XCTAssertTrue(
            app.navigationBars["Knowledge Packs"].waitForExistence(timeout: 3)
                || app.buttons["knowledge-pack-refresh"].waitForExistence(timeout: 3),
            "Knowledge-pack management screen should open"
        )

        let waterPackAction = app.buttons["knowledge-pack-action-water-readiness"]
        XCTAssertTrue(
            app.scrollToElement(waterPackAction, maxSwipes: 4),
            "Bundled knowledge packs should be visible in Settings"
        )
        XCTAssertEqual(
            waterPackAction.label,
            "Installed",
            "Bundled knowledge packs should already be installed on launch"
        )
    }

    func testMapScreenCanSaveWaypoint() {
        app.openMapScreen()
        app.handleLocationPermissionIfNeeded()

        let saveWaypointButton = app.buttons["Save Visible Waypoint"]
        if app.scrollToElement(saveWaypointButton, maxSwipes: 2) {
            saveWaypointButton.tap()
        } else {
            let saveWaypointTile = app.otherElements["Save visible waypoint"]
            XCTAssertTrue(
                app.scrollToElement(saveWaypointTile, maxSwipes: 2),
                "Map should expose a visible-waypoint save action"
            )
            saveWaypointTile.tap()
        }

        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Waypoint editor should expose a title field")
        titleField.tap()
        let waypointTitle = "Test Waypoint \(UUID().uuidString.prefix(4))"
        titleField.typeText(waypointTitle)

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Waypoint editor should expose Save")
        saveButton.tap()

        let waypointRow = app.staticTexts[waypointTitle]
        XCTAssertTrue(
            app.scrollToElement(waypointRow, maxSwipes: 4),
            "Saved waypoint should appear in the Map screen waypoint list"
        )
    }
}
