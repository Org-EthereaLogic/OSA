import XCTest

// MARK: - Shared Quick Card Labels

/// Single source of truth for seeded quick card titles used across all UI test suites.
enum SeedContent {
    static let quickCardLabels: [String] = [
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
}

// MARK: - XCUIApplication Navigation Helpers

extension XCUIApplication {

    /// Taps a tab bar button by name and waits for the UI to settle.
    @MainActor
    func tapTab(_ name: String) {
        let button = tabBars.firstMatch.buttons[name]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    /// Navigates into a More tab list item by label.
    @MainActor
    func navigateToMoreItem(_ label: String) {
        tapTab("More")

        let item = staticTexts[label]
        if item.waitForExistence(timeout: 3) {
            item.tap()
            return
        }

        let button = buttons[label]
        if button.waitForExistence(timeout: 2) {
            button.tap()
            return
        }

        let cell = cells.matching(
            NSPredicate(format: "label CONTAINS[c] %@", label)
        ).firstMatch
        if cell.waitForExistence(timeout: 2) {
            cell.tap()
        }
    }

    /// Opens a Library chapter by title. Returns `true` if the chapter was found and tapped.
    @MainActor
    func openLibraryChapter(named title: String) -> Bool {
        tapTab("Library")

        let chapter = staticTexts[title]
        guard scrollToElement(chapter, maxSwipes: 6) else {
            return false
        }

        chapter.tap()
        return true
    }

    /// Scrolls down (swipe up) until the element is visible or `maxSwipes` is exhausted.
    @MainActor
    func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        if element.waitForExistence(timeout: 1) {
            return true
        }

        for _ in 0..<maxSwipes {
            swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

    /// Scrolls Library back toward the top using swipe-down gestures.
    @MainActor
    func scrollToTop(swipes: Int = 3) {
        for _ in 0..<swipes {
            swipeDown()
        }
    }

    /// Taps the first back button in the navigation bar.
    @MainActor
    func navigateBack() {
        let backButton = navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
    }

    /// Dismisses a modal by tapping Cancel or swiping down.
    @MainActor
    func dismissModal() {
        let cancel = buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Cancel'")
        ).firstMatch
        if cancel.waitForExistence(timeout: 2) {
            cancel.tap()
        } else {
            swipeDown()
        }
    }

    /// Finds a button whose label contains the given text, checking navigation bars first.
    @MainActor
    func findButton(labelContaining text: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let navButton = navigationBars.buttons.matching(predicate).firstMatch
        if navButton.waitForExistence(timeout: 2) { return navButton }

        let toolbarButton = buttons.matching(predicate).firstMatch
        if toolbarButton.exists { return toolbarButton }

        return nil
    }

    /// Returns the first visible quick card button on the current screen, or `nil`.
    @MainActor
    func firstQuickCardButton() -> XCUIElement? {
        for label in SeedContent.quickCardLabels {
            let button = buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", label)
            ).firstMatch
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }
        return nil
    }

    /// Returns the label of the first visible quick card, or `nil`.
    @MainActor
    func firstVisibleQuickCardLabel() -> String? {
        for label in SeedContent.quickCardLabels {
            let match = buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", label)
            ).firstMatch
            if match.waitForExistence(timeout: 1) {
                return label
            }
        }
        return nil
    }

    /// Handles the iOS location permission alert if it appears.
    @MainActor
    func handleLocationPermissionIfNeeded() {
        let allowWhileUsing = buttons["Allow While Using App"]
        if allowWhileUsing.waitForExistence(timeout: 2) {
            allowWhileUsing.tap()
            return
        }

        let allowOnce = buttons["Allow Once"]
        if allowOnce.waitForExistence(timeout: 2) {
            allowOnce.tap()
        }
    }

    /// Opens the Map screen, handling both tab-bar and More-tab routing.
    @MainActor
    func openMapScreen() {
        tapTab("Map")
        if buttons["Save Visible Waypoint"].waitForExistence(timeout: 2) {
            return
        }
        if otherElements["Save visible waypoint"].waitForExistence(timeout: 2) {
            return
        }
        navigateToMoreItem("Map")
    }

    /// Submits a question on the Ask screen.
    @MainActor
    func submitAskQuestion(_ question: String) {
        let textField = textFields["Ask a question..."]
        guard textField.waitForExistence(timeout: 3) else { return }
        textField.tap()
        textField.typeText(question)

        let submitButton = buttons["Submit question"]
        if submitButton.exists {
            submitButton.tap()
            return
        }

        if keyboards.buttons["Return"].exists {
            keyboards.buttons["Return"].tap()
            return
        }

        if keyboards.buttons["return"].exists {
            keyboards.buttons["return"].tap()
        }
    }

    /// Opens the New Note composer from the Notes screen.
    @MainActor
    func openNewNoteComposer() {
        let createNoteButton = buttons["Create note"]
        if createNoteButton.waitForExistence(timeout: 3) {
            createNoteButton.tap()

            let newNoteAction = buttons["New Note"]
            if newNoteAction.waitForExistence(timeout: 3) {
                newNoteAction.tap()
                return
            }
        }

        let createFirstNoteButton = buttons["Create First Note"]
        if createFirstNoteButton.waitForExistence(timeout: 2) {
            createFirstNoteButton.tap()
        }
    }

    /// Returns the first hittable element from a query, or `nil`.
    @MainActor
    func firstHittableElement(in query: XCUIElementQuery) -> XCUIElement? {
        query.allElementsBoundByIndex.first(where: \.isHittable)
    }
}

// MARK: - Screenshot Convenience

extension XCTestCase {
    /// Captures a named screenshot attachment from the given app.
    @MainActor
    func screenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Brand Constants for Test Assertions

enum TestAppBrand {
    static let subtitle = "Offline Preparedness Guide"
}
