import XCTest
import UIKit

@MainActor
final class OSAWeekInLifeSimulationTests: XCTestCase, SimulationTestSupport {
    var app: XCUIApplication!
    var reporter: WeekSimulationReporter!
    var pinnedQuickCardTitle: String = "Boil Water Advisory Steps"

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        reporter = WeekSimulationReporter()
    }

    override func tearDown() {
        app?.terminate()
        XCUIDevice.shared.orientation = .portrait
        reporter?.writeArtifacts()
        super.tearDown()
    }

    func testPreparednessPlannerWeek() {
        reporter.recordEvent(message: "Starting seven-day preparedness persona simulation.")

        do {
            try runDay1()
            try runDay2()
            try runDay3()
            try runDay4()
            try runDay5()
            try runDay6()
            try runDay7()
        } catch {
            reporter.recordEvent(
                message: "Week simulation aborted: \(error.localizedDescription)",
                severity: .releaseBlocker
            )
        }

        let blockers = reporter.steps.filter { $0.severity == .releaseBlocker }
        let risks = reporter.steps.filter { $0.severity == .releaseRisk }
        let unverified = reporter.steps.filter { $0.severity == .unverified }
        reporter.recordEvent(
            message: "Week simulation finished with \(blockers.count) blockers, \(risks.count) risks, and \(unverified.count) unverified checks."
        )
        reporter.writeArtifacts()

        if let blocker = blockers.first {
            XCTFail("Week simulation recorded a release blocker on day \(blocker.day): \(blocker.actualResult)")
        } else if let risk = risks.first {
            XCTFail("Week simulation recorded a release risk on day \(risk.day): \(risk.actualResult)")
        }
    }

    private func runDay1() throws {
        launch(dayIndex: 0, connectivity: .offline, resetState: true)
        reporter.recordEvent(day: 1, message: "Day 1 launched offline with a clean scenario state.")

        try requireStep(
            day: 1,
            feature: "Settings",
            action: "Create an emergency contact",
            expectedResult: "The contact is saved locally and visible in Settings.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day1-emergency-contact"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            let addContactButton = app.buttons["Add Emergency Contact"]
            guard app.scrollToElement(addContactButton, maxSwipes: 12) else {
                throw SimulationFailure(message: "Add Emergency Contact action was not reachable.")
            }

            addContactButton.tap()
            app.clearAndTypeText(WeekSimulationPersona.emergencyContactName, into: app.textFields["Name"])
            app.clearAndTypeText("Spouse", into: app.textFields["Relationship"])
            app.clearAndTypeText("5550100", into: app.textFields["Phone Number"])
            app.clearAndTypeText("Primary SMS contact for check-ins.", into: app.textFields["Contact notes"])
            app.navigationBars.buttons["Save"].tap()

            guard app.staticTexts[WeekSimulationPersona.emergencyContactName].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Saved emergency contact was not listed after returning to Settings.")
            }

            return "Saved \(WeekSimulationPersona.emergencyContactName) as a local emergency contact."
        }

        try requireStep(
            day: 1,
            feature: "Notes",
            action: "Create a family-plan note",
            expectedResult: "The family emergency plan note is saved locally with the meetup phrase.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day1-family-plan-note"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            let createNoteButton = app.buttons["Create note"]
            if createNoteButton.waitForExistence(timeout: 3) {
                createNoteButton.tap()
                let familyPlanAction = app.buttons["Family Emergency Plan"]
                guard familyPlanAction.waitForExistence(timeout: 3) else {
                    throw SimulationFailure(message: "Family Emergency Plan menu action did not appear.")
                }
                familyPlanAction.tap()
            } else {
                let zeroStateAction = app.buttons["Create Family Emergency Plan"]
                guard zeroStateAction.waitForExistence(timeout: 3) else {
                    throw SimulationFailure(message: "Family Emergency Plan creation action was not available.")
                }
                zeroStateAction.tap()
            }

            let bodyField = app.textViews["Note content"]
            guard bodyField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Family plan editor did not expose the note body field.")
            }

            app.appendText(
                "\n\n\(WeekSimulationPersona.familyMeetupPhrase)\nPrimary communication: text first.\n",
                into: bodyField
            )
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: WeekSimulationPersona.familyPlanTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Saved family-plan note did not appear in Notes.")
            }

            return "Created a local family plan note with the meetup phrase stored in the body."
        }

        try requireStep(
            day: 1,
            feature: "Inventory",
            action: "Create the household starter inventory",
            expectedResult: "Four inventory items are saved with locations, one expiry toggle, and one low-stock reminder.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day1-inventory-created"
        ) {
            for fixture in WeekSimulationPersona.inventoryItems {
                try addInventoryItem(fixture)
            }

            guard app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Inventory list did not show the saved starter items.")
            }

            return "Saved \(WeekSimulationPersona.inventoryItems.count) inventory items with local-only details."
        }

        try requireStep(
            day: 1,
            feature: "Quick Cards",
            action: "Pin a quick card for one-tap access",
            expectedResult: "The selected quick card becomes pinned on Home after relaunch.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day1-pinned-quick-card"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Quick Cards")

            guard let cardTitle = app.firstVisibleQuickCardLabel() else {
                throw SimulationFailure(message: "Quick Cards list did not expose a seeded card to pin.")
            }

            pinnedQuickCardTitle = cardTitle
            let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardTitle)).firstMatch
            card.tap()

            let pinButton = app.buttons["Pin quick card"].firstMatch
            guard pinButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Quick card detail did not expose the pin action.")
            }

            pinButton.tap()
            guard app.buttons["Unpin quick card"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Quick card did not switch into the pinned state.")
            }

            app.navigateBack()
            return "Pinned quick card \"\(cardTitle)\" for Home access."
        }

        relaunch(dayIndex: 0, connectivity: .offline)

        try requireStep(
            day: 1,
            feature: "Home",
            action: "Verify the first-day state after relaunch",
            expectedResult: "Pinned content, recent notes, and at least one inventory reminder are visible after relaunch.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day1-home-after-relaunch"
        ) {
            app.tapTab("Home")

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card did not appear on Home after relaunch.")
            }

            guard app.scrollToElement(app.anyElement(containing: WeekSimulationPersona.familyPlanTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Recent Notes on Home did not show the family-plan note after relaunch.")
            }

            guard app.scrollToElement(app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name), maxSwipes: 6) else {
                throw SimulationFailure(message: "Home inventory reminders did not surface the low-stock starter item.")
            }

            return "Home reflected the pinned quick card, family note, and inventory reminder after relaunch."
        }
    }

    private func runDay2() throws {
        launch(dayIndex: 1, connectivity: .offline)
        reporter.recordEvent(day: 2, message: "Day 2 launched offline for Library and Ask workflows.")

        try requireStep(
            day: 2,
            feature: "Library",
            action: "Search water content, open a handbook section, and open a field reference",
            expectedResult: "Water search results appear, a handbook section opens, and a field reference detail opens.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day2-library-research"
        ) {
            app.tapTab("Library")

            let searchField = app.searchFields.firstMatch
            guard searchField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Library search field was not visible.")
            }

            app.clearAndTypeText("water", into: searchField)
            dismissKeyboardIfPresent()

            let handbookFilter = app.buttons["Handbook"]
            guard handbookFilter.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Library search did not expose the Handbook content-type filter.")
            }
            tapElement(handbookFilter)

            let handbookResult = app.buttons.matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
                    "Safe water storage",
                    "Curated"
                )
            ).firstMatch
            guard app.scrollToElement(handbookResult, maxSwipes: 6) else {
                throw SimulationFailure(message: "Water handbook result did not appear in Library search.")
            }

            // After the Handbook filter is active, the result list should contain the
            // section card rather than mixed content cards that also match "water".
            let handbookResultLabel = String(describing: handbookResult.label)
            guard handbookResultLabel.localizedCaseInsensitiveContains("safe water storage") else {
                throw SimulationFailure(message: "Library search surfaced an unexpected handbook result for the water query.")
            }

            tapElement(handbookResult)
            guard app.navigationBars["Water"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Handbook section detail did not open from Library search.")
            }

            guard app.anyElement(containing: "Store Drinking Water Safely").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Opened handbook detail did not expose the expected water-storage content block.")
            }

            app.navigateBack()
            let cancelSearch = app.buttons["Cancel"]
            if cancelSearch.waitForExistence(timeout: 2) {
                cancelSearch.tap()
            } else {
                app.clearSearchField(searchField)
            }

            let waterTreatmentCategory = app.staticTexts["Water Treatment"]
            guard app.scrollToElement(waterTreatmentCategory, maxSwipes: 6) else {
                throw SimulationFailure(message: "Water Treatment field-reference category was not reachable.")
            }

            waterTreatmentCategory.tap()
            let fieldReference = app.staticTexts["Household Water Treatment Reference"]
            guard fieldReference.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Water field reference was not visible inside the category view.")
            }

            fieldReference.tap()
            guard app.navigationBars["Household Water Treatment Reference"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Field reference detail did not open.")
            }

            return "Library search surfaced water content, and both handbook and field-reference details opened."
        }

        try requireStep(
            day: 2,
            feature: "Ask",
            action: "Ask a supported water-storage question and save a study guide",
            expectedResult: "Ask returns a grounded answer with citations and saves a local study-guide note.",
            releaseCriterion: .groundingAndCitations,
            failureSeverity: .releaseBlocker,
            screenshotName: "day2-ask-supported"
        ) {
            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.studyGuideQuery)

            let answerCard = app.otherElements["ask-answer-card"]
            guard answerCard.waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not return an answer card for the supported water question.")
            }

            guard app.staticTexts["Sources"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Supported Ask answer did not expose citations.")
            }

            let saveStudyGuideButton = app.buttons["Save Study Guide"]
            guard saveStudyGuideButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Ask answer did not expose the Save Study Guide action.")
            }

            saveStudyGuideButton.tap()
            let savedMessage = app.anyElement(containing: WeekSimulationPersona.studyGuideTitle)
            guard savedMessage.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Study guide save confirmation was not shown.")
            }

            return "Ask answered the water question with citations and saved the study guide locally."
        }

        try requireStep(
            day: 2,
            feature: "Ask",
            action: "Exercise not-found and bounded out-of-scope Ask responses",
            expectedResult: "Ask shows a not-found response for unsupported local evidence and a bounded refusal for out-of-scope requests.",
            releaseCriterion: .askScopeBoundaries,
            screenshotName: "day2-ask-refusals"
        ) {
            submitAskQuestion(WeekSimulationPersona.notFoundQuestion)
            guard app.staticTexts["Not Found Locally"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not show the not-found state for the unsupported local query.")
            }

            submitAskQuestion(WeekSimulationPersona.outOfScopeQuestion)
            guard app.staticTexts["Not Supported"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not show the bounded out-of-scope response.")
            }

            return "Ask produced both the not-found and bounded out-of-scope states."
        }

        try requireStep(
            day: 2,
            feature: "Ask",
            action: "Verify recent-question history",
            expectedResult: "The recent-questions section contains the supported water-storage question.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day2-ask-recent-history"
        ) {
            let recentQuestion = app.buttons.matching(
                NSPredicate(format: "identifier == 'recent-question' AND label CONTAINS[c] %@", WeekSimulationPersona.studyGuideQuery)
            ).firstMatch
            guard recentQuestion.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Recent Ask history did not retain the supported study-guide question.")
            }

            return "Recent questions retained the water-storage prompt on device."
        }
    }

    private func runDay3() throws {
        launch(dayIndex: 2, connectivity: .offline)
        reporter.recordEvent(day: 3, message: "Day 3 launched offline for organizer and weekly-drill flows.")

        try requireStep(
            day: 3,
            feature: "Inventory",
            action: "Edit one inventory item",
            expectedResult: "The edited item shows the updated storage location.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day3-inventory-edit"
        ) {
            app.tapTab("Inventory")
            let waterBrick = app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name)
            guard app.scrollToElement(waterBrick, maxSwipes: 4) else {
                throw SimulationFailure(message: "Water Brick was not visible in Inventory.")
            }

            waterBrick.tap()
            app.buttons["Inventory item actions"].tap()
            let editAction = app.buttons["Edit"]
            guard editAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory item actions did not expose Edit.")
            }

            editAction.tap()
            let locationField = app.textFields["Where is this stored?"]
            guard locationField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory edit form did not expose the storage-location field.")
            }

            app.clearAndTypeText("Garage shelf west wall", into: locationField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: "Garage shelf west wall").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Updated inventory location was not visible after saving.")
            }

            app.navigateBack()
            return "Updated the Water Brick storage location."
        }

        try requireStep(
            day: 3,
            feature: "Inventory",
            action: "Archive one inventory item",
            expectedResult: "The item enters the archived state and exposes the unarchive action.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day3-inventory-archive"
        ) {
            app.tapTab("Inventory")
            let trailMix = app.anyElement(containing: WeekSimulationPersona.inventoryItems[1].name)
            guard app.scrollToElement(trailMix, maxSwipes: 4) else {
                throw SimulationFailure(message: "Trail Mix Bin was not visible in Inventory.")
            }

            trailMix.tap()
            app.buttons["Inventory item actions"].tap()
            let archiveAction = app.buttons["Archive"]
            guard archiveAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory item actions did not expose Archive.")
            }

            archiveAction.tap()
            app.buttons["Inventory item actions"].tap()
            guard app.buttons["Unarchive"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Archived inventory item did not expose the Unarchive action.")
            }

            app.navigateBack()
            return "Archived Trail Mix Bin and confirmed the item can be unarchived."
        }

        try requireStep(
            day: 3,
            feature: "Checklists",
            action: "Start the emergency-kit checklist and complete part of the run",
            expectedResult: "The checklist run starts and the first two items become complete.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day3-checklist-run"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")

            let template = app.buttons["checklist-template-72-hour-emergency-kit-check"]
            guard app.scrollToElement(template, maxSwipes: 10) else {
                throw SimulationFailure(message: "72-Hour Emergency Kit Check template was not reachable.")
            }

            if template.isHittable {
                template.tap()
            } else {
                template.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }

            let startButton = app.buttons["Start Checklist"]
            guard app.scrollToElement(startButton, maxSwipes: 4) else {
                throw SimulationFailure(message: "Checklist detail did not expose Start Checklist.")
            }

            startButton.tap()

            let firstItem = app.buttons[WeekSimulationPersona.firstChecklistItem]
            let secondItem = app.buttons[WeekSimulationPersona.secondChecklistItem]
            guard firstItem.waitForExistence(timeout: 5), secondItem.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Checklist run did not expose the expected starter items.")
            }

            firstItem.tap()
            secondItem.tap()

            let firstValue = String(describing: firstItem.value ?? "")
            let secondValue = String(describing: secondItem.value ?? "")
            guard firstValue == "Complete", secondValue == "Complete" else {
                throw SimulationFailure(message: "Checklist run items were not marked complete after tapping them.")
            }

            app.navigateBack()
            return "Started the checklist run and completed the first two checklist items."
        }

        try requireStep(
            day: 3,
            feature: "Weekly Drill",
            action: "Open the weekly drill and finish its local quiz",
            expectedResult: "The weekly drill records completion for the current week.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day3-weekly-drill"
        ) {
            app.tapTab("Home")
            let weeklyDrillCard = app.buttons["home-weekly-drill-card"]
            guard app.scrollToElement(weeklyDrillCard, maxSwipes: 5) else {
                throw SimulationFailure(message: "Home did not surface the weekly drill card.")
            }

            weeklyDrillCard.tap()
            let startQuiz = app.buttons["quick-card-start-quiz"]
            guard startQuiz.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Weekly drill quick card did not expose the quiz action.")
            }

            startQuiz.tap()
            try completeVisibleQuiz()
            app.navigateBack()

            return "Completed the weekly drill quiz and returned to Home."
        }

        try requireStep(
            day: 3,
            feature: "Ask",
            action: "Verify Ask note-scope behavior against the family-plan note",
            expectedResult: "Ask cites the family-plan note when personal notes are included and refuses after notes are excluded.",
            releaseCriterion: .askScopeBoundaries,
            screenshotName: "day3-ask-note-scope"
        ) {
            app.tapTab("Ask")

            let includeNotesToggle = app.switches["Include personal notes"]
            guard includeNotesToggle.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Ask did not expose the Include personal notes toggle.")
            }

            setToggle(includeNotesToggle, isOn: true)

            submitAskQuestion(WeekSimulationPersona.familyMeetupQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not answer the family meetup question when notes were included.")
            }

            let familyPlanCitation = app.anyElement(containing: WeekSimulationPersona.familyPlanTitle)
            guard familyPlanCitation.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Ask answer did not cite the saved family-plan note.")
            }

            setToggle(includeNotesToggle, isOn: false)
            submitAskQuestion(WeekSimulationPersona.familyMeetupQuestion)
            guard app.staticTexts["Not Found Locally"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask still answered from the personal note after notes were excluded.")
            }

            return "Ask respected the Include personal notes setting for the family meetup question."
        }

        relaunch(dayIndex: 2, connectivity: .offline)

        try requireStep(
            day: 3,
            feature: "Persistence",
            action: "Verify checklist and weekly-drill progress after relaunch",
            expectedResult: "Home still shows the active checklist run and completed weekly drill after relaunch.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day3-after-relaunch"
        ) {
            app.tapTab("Home")

            let activeRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Home did not restore the active checklist run after relaunch.")
            }

            guard app.staticText(containing: "Completed for").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Weekly drill completion did not persist to Home after relaunch.")
            }

            return "Checklist progress and weekly-drill completion both persisted across relaunch."
        }
    }

    private func runDay4() throws {
        launch(dayIndex: 3, connectivity: .onlineUsable)
        reporter.recordEvent(day: 4, message: "Day 4 launched online to exercise tools, weather, map, and orientation changes.")

        try requireStep(
            day: 4,
            feature: "Tools",
            action: "Use Morse, timer, converter, and declination tools",
            expectedResult: "Each survival-tool control responds without leaving the tool screen unstable.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day4-tools"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Tools")

            let useSOS = app.buttons["Use SOS"]
            guard useSOS.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Survival Tools did not expose the Morse SOS control.")
            }

            useSOS.tap()
            app.buttons["Play Signal"].tap()
            guard app.buttons["Stop Signal"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Morse signal did not enter the running state.")
            }
            app.buttons["Stop Signal"].tap()

            let startStopwatch = app.buttons["Start Stopwatch"]
            guard startStopwatch.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Timer / Stopwatch control was not visible.")
            }

            startStopwatch.tap()
            guard app.buttons["Pause"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Stopwatch did not transition into the running state.")
            }
            app.buttons["Pause"].tap()
            app.buttons["Reset"].tap()

            let converterInput = app.textFields["Enter value"]
            guard converterInput.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Unit converter input was not visible.")
            }
            app.clearAndTypeText("10", into: converterInput)

            let latitudeField = app.textFields["Latitude"]
            let longitudeField = app.textFields["Longitude"]
            guard latitudeField.waitForExistence(timeout: 3), longitudeField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Declination inputs were not visible.")
            }

            app.clearAndTypeText("45.52", into: latitudeField)
            app.clearAndTypeText("-122.68", into: longitudeField)

            return "Morse, stopwatch, converter, and declination tools all responded to live input."
        }

        try requireStep(
            day: 4,
            feature: "Map",
            action: "Save a visible waypoint",
            expectedResult: "The map can save a waypoint locally with a title and note.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day4-map-waypoint"
        ) {
            app.openMapScreen()

            let waypointButton = app.buttons["map-save-visible-waypoint"]
            guard waypointButton.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Map did not expose the Save Visible Waypoint action.")
            }

            waypointButton.tap()
            let titleField = app.textFields["Title"]
            let noteField = app.textFields["Note"]
            guard titleField.waitForExistence(timeout: 5), noteField.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Waypoint editor did not present title and note fields.")
            }

            app.clearAndTypeText("Neighborhood Rally Point", into: titleField)
            app.clearAndTypeText("Saved during the week simulation.", into: noteField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: "Neighborhood Rally Point").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Saved waypoint did not appear on the Map screen.")
            }

            return "Saved the visible map region as the Neighborhood Rally Point waypoint."
        }

        try requireStep(
            day: 4,
            feature: "Weather",
            action: "Load fixture-backed forecast and alerts",
            expectedResult: "Weather shows the deterministic alert and 10-day forecast while online.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day4-weather"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Weather")

            guard app.staticTexts["10-Day Forecast"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Weather did not render the 10-day forecast.")
            }

            guard app.anyElement(containing: "Wind Advisory").waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Weather did not render the fixture alert.")
            }

            return "Weather loaded the 10-day forecast and Wind Advisory alert."
        }

        try requireStep(
            day: 4,
            feature: "Accessibility",
            action: "Toggle high contrast and large print, then rotate once",
            expectedResult: "The app remains usable after accessibility changes and landscape rotation.",
            releaseCriterion: .accessibilityAndOrientation,
            screenshotName: "day4-accessibility-rotation"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            let highContrast = app.switches["settings-high-contrast-toggle"]
            let largePrint = app.switches["settings-large-print-toggle"]
            guard app.scrollToElement(highContrast, maxSwipes: 10),
                  app.scrollToElement(largePrint, maxSwipes: 10) else {
                throw SimulationFailure(message: "Settings did not expose high-contrast and large-print toggles.")
            }

            setToggle(highContrast, isOn: true)
            setToggle(largePrint, isOn: true)

            app.tapTab("Home")
            XCUIDevice.shared.orientation = .landscapeLeft
            guard app.buttons["Emergency Mode"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Home emergency entry was not usable after landscape rotation.")
            }

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card was not reachable after accessibility changes.")
            }

            XCUIDevice.shared.orientation = .portrait
            return "High contrast, large print, and one rotation completed without breaking the core Home UI."
        }
    }

    private func runDay5() throws {
        launch(dayIndex: 4, connectivity: .onlineUsable)
        reporter.recordEvent(day: 5, message: "Day 5 launched online for discovery import and offline persistence checks.")

        try requireStep(
            day: 5,
            feature: "Library",
            action: "Verify imported knowledge is absent before discovery",
            expectedResult: "The unique imported-knowledge phrase is not searchable before manual discovery runs.",
            releaseCriterion: .discoveryImportCommit,
            screenshotName: "day5-preimport-search"
        ) {
            app.tapTab("Library")
            let searchField = app.searchFields.firstMatch
            guard searchField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Library search field was not visible for the pre-import check.")
            }

            app.clearAndTypeText(WeekSimulationPersona.preImportSearchTerm, into: searchField)
            if app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle).waitForExistence(timeout: 3) {
                throw SimulationFailure(message: "Imported knowledge appeared in search before discovery committed it locally.")
            }

            return "Imported knowledge was absent from Library search before discovery."
        }

        try requireStep(
            day: 5,
            feature: "Settings",
            action: "Run manual discovery against approved fixture sources",
            expectedResult: "Discovery imports approved ready.gov fixture content and reports a successful local commit.",
            releaseCriterion: .discoveryImportCommit,
            failureSeverity: .releaseBlocker,
            screenshotName: "day5-discovery"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            let discoveryButton = app.buttons["Discover New Content"]
            guard app.scrollToElement(discoveryButton, maxSwipes: 12) else {
                throw SimulationFailure(message: "Settings did not expose the manual discovery action.")
            }

            discoveryButton.tap()
            let successMessage = app.anyElement(containing: "Imported 2 new items")
            guard successMessage.waitForExistence(timeout: 15) else {
                throw SimulationFailure(message: "Discovery did not report a successful local import commit.")
            }

            return "Discovery imported the approved fixture content and reported a successful commit."
        }

        try requireStep(
            day: 5,
            feature: "Imported Knowledge",
            action: "Verify imported content becomes searchable and citeable after discovery",
            expectedResult: "Library search finds the imported article and Ask cites it from local storage.",
            releaseCriterion: .groundingAndCitations,
            failureSeverity: .releaseBlocker,
            screenshotName: "day5-imported-knowledge"
        ) {
            app.tapTab("Library")
            let searchField = app.searchFields.firstMatch
            guard searchField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Library search field was not visible after discovery.")
            }

            app.clearAndTypeText(WeekSimulationPersona.preImportSearchTerm, into: searchField)
            let importedResult = app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle)
            guard importedResult.waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Imported knowledge was not searchable after discovery committed it locally.")
            }

            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.importedKnowledgeQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not answer the imported-knowledge question after discovery.")
            }

            let importedCitation = app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle)
            guard importedCitation.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Ask answer did not cite the imported knowledge article.")
            }

            return "Imported content became searchable in Library and citeable in Ask only after local commit."
        }

        relaunch(dayIndex: 4, connectivity: .offline)

        try requireStep(
            day: 5,
            feature: "Offline Persistence",
            action: "Verify imported knowledge and bundled packs remain available offline after relaunch",
            expectedResult: "Ask still cites the imported article offline and the bundled Water Readiness pack remains installed.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day5-offline-relaunch"
        ) {
            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.importedKnowledgeQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Imported knowledge was not available to Ask after the offline relaunch.")
            }

            let importedCitation = app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle)
            guard importedCitation.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Offline Ask answer did not retain the imported-knowledge citation.")
            }

            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")
            let knowledgePacksLink = app.otherElements["settings-knowledge-packs"]
            guard app.scrollToElement(knowledgePacksLink, maxSwipes: 12) else {
                throw SimulationFailure(message: "Knowledge Packs entry was not reachable in Settings.")
            }

            knowledgePacksLink.tap()
            guard app.anyElement(containing: WeekSimulationPersona.knowledgePackTitle).waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Knowledge Packs screen did not list the bundled Water Readiness pack.")
            }

            let packStatus = app.staticTexts["knowledge-pack-status-water-readiness"]
            guard packStatus.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Bundled Water Readiness pack did not expose its accessibility status field.")
            }

            let statusValue = String(describing: packStatus.value ?? packStatus.label)
            guard statusValue.localizedCaseInsensitiveContains("Installed") else {
                throw SimulationFailure(message: "Bundled Water Readiness pack was not in the installed state.")
            }

            return "Imported knowledge stayed citeable offline, and Water Readiness remained installed."
        }
    }

    private func runDay6() throws {
        launch(dayIndex: 5, connectivity: .offline)
        reporter.recordEvent(day: 6, message: "Day 6 launched offline for privacy, capture affordance, and export checks.")

        try requireStep(
            day: 6,
            feature: "Document Vault",
            action: "Verify the locked vault state",
            expectedResult: "The locked-state copy explains that vault documents stay excluded from Ask, widgets, Spotlight, and export flows.",
            releaseCriterion: .privacyIsolation,
            screenshotName: "day6-vault-locked"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Document Vault")

            let lockedMessage = app.anyElement(containing: "excluded from Ask, widgets, Spotlight, and export flows")
            guard lockedMessage.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Document Vault did not show the locked-state privacy boundary copy.")
            }

            guard app.buttons["document-vault-unlock"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Document Vault did not expose the unlock affordance while locked.")
            }

            return "Locked vault copy and unlock affordance both matched the expected privacy boundary."
        }

        reporter.recordUnverifiedStep(
            day: 6,
            feature: "Document Vault",
            action: "Unlock the vault and import a real document",
            expectedResult: "Device authentication and a real local import succeed without exposing document contents to Ask or system surfaces.",
            actualResult: runningOnSimulator
                ? "Skipped in simulator. Real Face ID / Touch ID and document import require a physical device run."
                : "Manual verification required even on device because biometric and picker flows are not deterministically automated in this suite.",
            releaseCriterion: .deviceCapability
        )

        try requireStep(
            day: 6,
            feature: "Inventory Capture",
            action: "Verify photo and scan affordances on the inventory form",
            expectedResult: "Inventory add/edit exposes scan, camera, photo-library import, and OCR affordances.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day6-inventory-capture"
        ) {
            app.tapTab("Inventory")
            app.openInventoryAddForm()

            guard app.buttons["inventory-form-scan-code"].waitForExistence(timeout: 3),
                  app.buttons["inventory-form-capture-photo"].waitForExistence(timeout: 3),
                  app.buttons["inventory-form-import-photo"].waitForExistence(timeout: 3),
                  app.buttons["inventory-form-recognize-label"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory form did not expose every capture affordance.")
            }

            app.dismissModal()
            return "Inventory form exposed scan, camera, import, and OCR actions."
        }

        try requireStep(
            day: 6,
            feature: "Export",
            action: "Open note, inventory, and checklist exports",
            expectedResult: "The note, inventory, and checklist export actions all open a share sheet without crashing.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day6-export-actions"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")
            let familyPlanNote = app.anyElement(containing: WeekSimulationPersona.familyPlanTitle)
            guard app.scrollToElement(familyPlanNote, maxSwipes: 4) else {
                throw SimulationFailure(message: "Family plan note was not visible for export.")
            }

            familyPlanNote.tap()
            app.buttons["Note actions"].tap()
            let markdownExport = app.buttons["Export as Markdown"]
            guard markdownExport.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note detail did not expose markdown export.")
            }
            markdownExport.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            app.tapTab("Inventory")
            let inventoryExport = app.buttons["Export inventory"]
            guard inventoryExport.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory did not expose the export action.")
            }
            inventoryExport.tap()
            app.dismissShareSheetIfNeeded()

            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")
            let activeRun = app.buttons["checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Checklist run list did not show the active run.")
            }
            activeRun.tap()

            let runExport = app.buttons["Export checklist run as PDF"]
            guard runExport.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Checklist run did not expose the export action.")
            }
            runExport.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Note, inventory, and checklist exports all opened and dismissed cleanly."
        }

        try requireStep(
            day: 6,
            feature: "Share",
            action: "Open quick-card and handbook share flows",
            expectedResult: "Quick-card and handbook share actions open a share sheet without destabilizing navigation.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day6-share-actions"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Quick Cards")

            let pinnedCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", pinnedQuickCardTitle)).firstMatch
            guard pinnedCard.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Pinned quick card was not visible in the Quick Cards list.")
            }
            pinnedCard.tap()

            let quickCardShare = app.buttons["Share quick card"]
            guard quickCardShare.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Quick card detail did not expose the share action.")
            }
            quickCardShare.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            app.tapTab("Library")
            guard app.openLibraryChapter(named: "Water") else {
                throw SimulationFailure(message: "Water chapter was not reachable for the handbook share flow.")
            }

            let section = app.staticTexts["Store Drinking Water Safely"]
            guard app.scrollToElement(section, maxSwipes: 4) else {
                throw SimulationFailure(message: "Expected handbook section was not visible inside the Water chapter.")
            }
            section.tap()

            let handbookShare = app.buttons["Share handbook section"]
            guard handbookShare.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Handbook section detail did not expose the share action.")
            }
            handbookShare.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Quick-card and handbook share actions both opened and dismissed cleanly."
        }
    }

    private func runDay7() throws {
        launch(dayIndex: 6, connectivity: .offline)
        reporter.recordEvent(day: 7, message: "Day 7 launched offline for emergency-mode and final recovery validation.")

        try requireStep(
            day: 7,
            feature: "Emergency Mode",
            action: "Jump from Emergency Mode to Quick Cards and Survival Tools",
            expectedResult: "Emergency Mode opens offline and both shortcuts remain usable.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day7-emergency-mode"
        ) {
            app.tapTab("Home")
            let emergencyMode = app.buttons["home-emergency-mode-button"]
            guard emergencyMode.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Home did not expose the Emergency Mode entry point.")
            }

            emergencyMode.tap()
            guard app.buttons["Exit Emergency Mode"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Emergency Mode did not open from Home.")
            }

            let quickCardsShortcut = app.buttons["View Quick Cards"]
            guard quickCardsShortcut.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Emergency Mode did not expose the Quick Cards shortcut.")
            }
            quickCardsShortcut.tap()
            guard app.navigationBars["Quick Cards"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Quick Cards did not open from Emergency Mode.")
            }
            app.navigateBack()

            let toolsShortcut = app.buttons["Open Survival Tools"]
            guard toolsShortcut.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Emergency Mode did not expose the Survival Tools shortcut.")
            }
            toolsShortcut.tap()
            guard app.navigationBars["Tools"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Survival Tools did not open from Emergency Mode.")
            }
            app.navigateBack()

            app.buttons["Exit Emergency Mode"].tap()
            return "Emergency Mode opened offline and both shortcut drills remained usable."
        }

        try requireStep(
            day: 7,
            feature: "Checklist Recovery",
            action: "Resume the active checklist run",
            expectedResult: "The active checklist still shows the completed starter items before the final relaunch.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day7-checklist-recovery"
        ) {
            app.tapTab("Home")
            let activeRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Home did not expose the active checklist on Day 7.")
            }

            activeRun.tap()
            let firstItem = app.buttons[WeekSimulationPersona.firstChecklistItem]
            let secondItem = app.buttons[WeekSimulationPersona.secondChecklistItem]
            guard firstItem.waitForExistence(timeout: 5),
                  secondItem.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Checklist run did not restore the starter items on Day 7.")
            }

            let firstValue = String(describing: firstItem.value ?? "")
            let secondValue = String(describing: secondItem.value ?? "")
            guard firstValue == "Complete",
                  secondValue == "Complete" else {
                throw SimulationFailure(message: "Checklist run lost completion state before the final relaunch.")
            }

            app.navigateBack()
            return "The active checklist retained the completed starter items on Day 7."
        }

        relaunch(dayIndex: 6, connectivity: .offline)

        try requireStep(
            day: 7,
            feature: "Final Recovery",
            action: "Verify no state loss after the last cold relaunch",
            expectedResult: "Pinned content, weekly drill completion, active checklist, and imported knowledge all remain available offline.",
            releaseCriterion: .persistenceAcrossRelaunch,
            failureSeverity: .releaseBlocker,
            screenshotName: "day7-final-home"
        ) {
            app.tapTab("Home")

            let activeRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Active checklist disappeared after the final cold relaunch.")
            }

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card disappeared after the final cold relaunch.")
            }

            guard app.staticText(containing: "Completed for").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Weekly drill completion disappeared after the final cold relaunch.")
            }

            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.importedKnowledgeQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Imported knowledge was not available to Ask after the final cold relaunch.")
            }

            let importedCitation = app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle)
            guard importedCitation.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Imported-knowledge citation disappeared after the final cold relaunch.")
            }

            return "Pinned content, weekly drill, active checklist, and imported knowledge all survived the final cold relaunch."
        }
    }

    private func launch(dayIndex: Int, connectivity: WeekSimulationConnectivity, resetState: Bool = false) {
        app = launchSimulation(dayIndex: dayIndex, connectivity: connectivity, resetState: resetState)
    }

    private func relaunch(dayIndex: Int, connectivity: WeekSimulationConnectivity) {
        app = relaunchSimulation(dayIndex: dayIndex, connectivity: connectivity)
    }
}
