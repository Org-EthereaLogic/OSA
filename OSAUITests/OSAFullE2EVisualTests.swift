import XCTest

/// Full end-to-end visual walk-through of every tab and key drill-in screen.
/// Each test navigates to a surface and asserts that expected elements exist,
/// logging any missing content or broken navigation.
final class OSAFullE2EVisualTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments.append("UI-TESTING")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("App did not present a tab bar — seed content may be missing")
            return
        }
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
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
        app.tapTab("Home")

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

        // At least one quick card (randomized on each launch)
        let anyCardVisible = SeedContent.quickCardLabels.contains { app.staticTexts[$0].exists }
        XCTAssertTrue(anyCardVisible, "At least one quick card should appear on Home")

        // Active Checklists section
        XCTAssertTrue(
            app.staticTexts["Active Checklists"].exists,
            "Active Checklists section header should appear on Home"
        )

        screenshot("Home-Tab", app: app)
    }

    @MainActor
    func testHomeTapQuickCard() {
        app.tapTab("Home")

        guard let cardLabel = app.firstVisibleQuickCardLabel() else {
            XCTFail("No quick card found on Home")
            return
        }
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardLabel)).firstMatch
        card.tap()

        // Wait for detail to load instead of sleeping
        let detailLoaded = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
            || app.staticTexts["Stored locally"].waitForExistence(timeout: 3)
        XCTAssertTrue(detailLoaded, "Quick card detail should load after tap")

        screenshot("Home-QuickCard-Detail", app: app)

        app.navigateBack()
    }

    @MainActor
    func testHomeSpotlightFeedTab() {
        app.tapTab("Home")

        // Segmented picker should have "Feed" segment
        let feedSegment = app.buttons["Feed"]
        guard feedSegment.waitForExistence(timeout: 3) else {
            XCTFail("Feed segment should appear in Spotlight picker on Home")
            return
        }
        feedSegment.tap()

        // Wait for feed content to resolve instead of sleeping 3s
        let anyArticle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Read more'")
        ).firstMatch
        let emptyState = app.staticTexts["No articles available. Connect to the internet to fetch feeds."]
        let failedState = app.staticTexts["Feed service unavailable."]
        let loadingState = app.staticTexts["Fetching latest articles..."]

        // Give feed time to load — check periodically
        let feedResolved = anyArticle.waitForExistence(timeout: 5)
            || emptyState.waitForExistence(timeout: 2)
            || failedState.waitForExistence(timeout: 2)
            || loadingState.exists
        XCTAssertTrue(feedResolved, "Feed tab should show articles, empty state, or loading indicator")

        screenshot("Home-Spotlight-Feed", app: app)

        // Switch back to Quick Cards to verify toggle works
        let quickCardsSegment = app.buttons["Quick Cards"]
        if quickCardsSegment.exists {
            quickCardsSegment.tap()
            screenshot("Home-Spotlight-QuickCards", app: app)
        }
    }

    @MainActor
    func testHomeScrollToBottom() {
        app.tapTab("Home")

        app.swipeUp()
        screenshot("Home-Scrolled-1", app: app)

        app.swipeUp()
        screenshot("Home-Scrolled-2", app: app)

        // Bottom sections may or may not have data — just verify no crash
    }

    // MARK: - Library Tab

    @MainActor
    func testLibraryScreenContent() {
        app.tapTab("Library")

        let fieldReferences = app.staticTexts["Field References"]
        XCTAssertTrue(
            fieldReferences.waitForExistence(timeout: 5),
            "Field References should appear in Library"
        )

        let firstChapter = app.staticTexts["Preparedness Foundations"]
        XCTAssertTrue(
            app.scrollToElement(firstChapter, maxSwipes: 6),
            "Preparedness Foundations chapter should remain reachable in Library"
        )

        let waterChapter = app.staticTexts["Water"]
        XCTAssertTrue(
            waterChapter.exists || app.scrollToElement(waterChapter, maxSwipes: 2),
            "Water chapter should appear in Library"
        )

        screenshot("Library-Tab", app: app)
    }

    @MainActor
    func testLibraryDrillIntoChapter() {
        guard app.openLibraryChapter(named: "Preparedness Foundations") else {
            XCTFail("Preparedness Foundations chapter not found")
            return
        }

        // Wait for chapter detail to load
        XCTAssertTrue(
            app.navigationBars["Preparedness Foundations"].waitForExistence(timeout: 3),
            "Chapter detail should show navigation title"
        )

        screenshot("Library-Chapter-Detail", app: app)

        // Should show sections — at least some text content
        let hasSections = app.cells.count > 0 || app.staticTexts.count > 2
        XCTAssertTrue(hasSections, "Chapter detail should show sections or content")

        let section = app.staticTexts["Start With The Risks You Actually Face"]
        if section.waitForExistence(timeout: 2) {
            section.tap()

            // Wait for section detail to load
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
            screenshot("Library-Section-Detail", app: app)
            app.navigateBack()
        }

        if !app.staticTexts["Recently Viewed"].exists {
            app.navigateBack()
        }
        app.scrollToTop()

        XCTAssertTrue(
            app.scrollToElement(app.staticTexts["Recently Viewed"], maxSwipes: 2),
            "Library should show Recently Viewed after opening a handbook section"
        )
        screenshot("Library-Recently-Viewed", app: app)
    }

    @MainActor
    func testLibraryScrollChapterList() {
        app.tapTab("Library")
        _ = app.staticTexts["Field References"].waitForExistence(timeout: 3)

        app.swipeUp()
        app.swipeUp()
        screenshot("Library-Scrolled", app: app)

        // Check a chapter further down the list
        let fireChapter = app.staticTexts["Fire And Lighting"]
        let goChapter = app.staticTexts["Go-Bags"]
        XCTAssertTrue(
            fireChapter.exists
                || goChapter.exists
                || app.scrollToElement(fireChapter, maxSwipes: 4)
                || app.scrollToElement(goChapter, maxSwipes: 4),
            "Later chapters should remain reachable after scrolling"
        )
    }

    // MARK: - Ask Tab

    @MainActor
    func testAskScreenContent() {
        app.tapTab("Ask")

        screenshot("Ask-Tab", app: app)

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
        app.tapTab("Inventory")

        screenshot("Inventory-Tab", app: app)

        // May show empty state or category-grouped items
        // Just verify the screen loaded without crash
        let hasContent = app.staticTexts.count > 0 || app.cells.count > 0
        XCTAssertTrue(hasContent, "Inventory screen should render content or empty state")
    }

    @MainActor
    func testInventoryAddItem() {
        app.tapTab("Inventory")

        // Look for add button in nav bar or toolbar
        let addButton = app.findButton(labelContaining: "Add")
            ?? app.findButton(labelContaining: "plus")
            ?? app.findButton(labelContaining: "New")

        guard let addButton else { return }  // No add button is OK

        addButton.tap()

        // Wait for form to appear instead of sleeping
        _ = app.textFields.firstMatch.waitForExistence(timeout: 3)
        screenshot("Inventory-Add-Item", app: app)

        app.dismissModal()
    }

    // MARK: - More Tab > Checklists

    @MainActor
    func testChecklistsScreen() {
        app.navigateToMoreItem("Checklists")

        screenshot("Checklists-Screen", app: app)

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

            // Wait for detail to load
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
            screenshot("Checklist-Template-Detail", app: app)
            app.navigateBack()
        }
    }

    // MARK: - More Tab > Quick Cards

    @MainActor
    func testQuickCardsScreen() {
        app.navigateToMoreItem("Quick Cards")

        screenshot("QuickCards-Screen", app: app)

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("water")

            // Wait for search results
            _ = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Water'")
            ).firstMatch.waitForExistence(timeout: 3)
            screenshot("QuickCards-Search", app: app)
        }

        let firstCard = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Quick' OR label CONTAINS[c] 'Water' OR label CONTAINS[c] 'Power'")
        ).firstMatch
        if firstCard.waitForExistence(timeout: 3) {
            firstCard.tap()

            // Wait for detail to load
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
            screenshot("QuickCard-Detail-FromList", app: app)
            app.navigateBack()
        }
    }

    // MARK: - More Tab > Tools

    @MainActor
    func testToolsScreen() {
        app.navigateToMoreItem("Tools")

        screenshot("Tools-Screen", app: app)

        let morseSection = app.staticTexts["Morse Signal"]
        let timerSection = app.staticTexts["Timer / Stopwatch"]
        let converterSection = app.staticTexts["Unit Converter"]
        let declinationSection = app.staticTexts["Declination"]

        XCTAssertTrue(
            morseSection.waitForExistence(timeout: 3),
            "Tools should show the Morse section"
        )
        XCTAssertTrue(
            timerSection.exists || app.buttons["Start Stopwatch"].exists,
            "Tools should show timer controls"
        )

        if !converterSection.exists {
            app.swipeUp()
        }

        XCTAssertTrue(
            converterSection.exists || declinationSection.exists,
            "Tools should show converter and declination references after scrolling"
        )
    }

    // MARK: - More Tab > Notes

    @MainActor
    func testNotesScreen() {
        app.navigateToMoreItem("Notes")

        screenshot("Notes-Screen", app: app)

        // Try add note
        let addButton = app.findButton(labelContaining: "Add")
            ?? app.findButton(labelContaining: "New")
            ?? app.findButton(labelContaining: "plus")

        if let addButton {
            addButton.tap()

            // Wait for composer to appear
            _ = app.textFields.firstMatch.waitForExistence(timeout: 3)
            screenshot("Notes-New-Note", app: app)
            app.dismissModal()
        }
    }

    // MARK: - More Tab > Settings

    @MainActor
    func testSettingsScreen() {
        app.navigateToMoreItem("Settings")

        screenshot("Settings-Screen", app: app)

        // Look for reorganized setup and status sections plus About/Version fallback
        let emergencyContacts = app.staticTexts["Emergency Contacts"]
        let accessibilitySection = app.staticTexts["Accessibility & Feedback"]
        let safeShortcutCopy = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "I'm Safe"))
            .firstMatch
        let aboutSection = app.staticTexts["About"]
        let versionLabel = app.staticTexts["Version"]
        let lanternLabel = app.staticTexts[TestAppBrand.subtitle]
        let anySettingsContent = emergencyContacts.waitForExistence(timeout: 3)
            || accessibilitySection.exists
            || safeShortcutCopy.exists
            || aboutSection.exists
            || versionLabel.exists
            || lanternLabel.exists
            || app.switches.count > 0
        XCTAssertTrue(anySettingsContent, "Settings should show About, Version, or toggle controls")
    }
}
