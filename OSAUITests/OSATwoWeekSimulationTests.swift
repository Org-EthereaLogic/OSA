import XCTest
import UIKit

@MainActor
final class OSATwoWeekSimulationTests: XCTestCase, SimulationTestSupport {
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

    // MARK: - Entry Point

    func testPreparednessPlannerTwoWeeks() {
        reporter.recordEvent(message: "Starting fourteen-day preparedness persona simulation.")

        do {
            try runDay1()
            try runDay2()
            try runDay3()
            try runDay4()
            try runDay5()
            try runDay6()
            try runDay7()
            try runDay8()
            try runDay9()
            try runDay10()
            try runDay11()
            try runDay12()
            try runDay13()
            try runDay14()
        } catch {
            reporter.recordEvent(
                message: "Two-week simulation aborted: \(error.localizedDescription)",
                severity: .releaseBlocker
            )
        }

        let blockers = reporter.steps.filter { $0.severity == .releaseBlocker }
        let risks = reporter.steps.filter { $0.severity == .releaseRisk }
        let unverified = reporter.steps.filter { $0.severity == .unverified }
        reporter.recordEvent(
            message: "Two-week simulation finished with \(blockers.count) blockers, \(risks.count) risks, and \(unverified.count) unverified checks."
        )
        reporter.writeArtifacts()

        if let blocker = blockers.first {
            XCTFail("Two-week simulation recorded a release blocker on day \(blocker.day): \(blocker.actualResult)")
        } else if let risk = risks.first {
            XCTFail("Two-week simulation recorded a release risk on day \(risk.day): \(risk.actualResult)")
        }
    }

    // MARK: - Launch Helpers

    private func launch(dayIndex: Int, connectivity: WeekSimulationConnectivity, resetState: Bool = false) {
        app = launchSimulation(dayIndex: dayIndex, connectivity: connectivity, resetState: resetState)
    }

    private func relaunch(dayIndex: Int, connectivity: WeekSimulationConnectivity) {
        app = relaunchSimulation(dayIndex: dayIndex, connectivity: connectivity)
    }

    // MARK: - Week 1: Day 1

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

    // MARK: - Week 1: Day 2

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

    // MARK: - Week 1: Day 3

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

    // MARK: - Week 1: Day 4

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

    // MARK: - Week 1: Day 5

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

    // MARK: - Week 1: Day 6

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

    // MARK: - Week 1: Day 7

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

    // MARK: - Week 2: Day 8 — Routine Maintenance (Offline)

    private func runDay8() throws {
        launch(dayIndex: 7, connectivity: .offline)
        reporter.recordEvent(day: 8, message: "Day 8 launched offline for routine maintenance and Week 1 data verification.")

        try requireStep(
            day: 8,
            feature: "Home",
            action: "Verify all Week 1 data persists after 7-day gap",
            expectedResult: "Pinned card, checklist run, weekly drill, and inventory reminders all visible.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day8-week1-persistence"
        ) {
            app.tapTab("Home")

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card from Day 1 was not visible on Home after the Week 1 gap.")
            }

            let activeRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Active checklist run from Day 3 was not visible on Home.")
            }

            guard app.scrollToElement(app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name), maxSwipes: 6) else {
                throw SimulationFailure(message: "Inventory reminder for Water Brick was not visible on Home.")
            }

            return "All Week 1 data persisted across the 7-day gap: pinned card, checklist, inventory reminders."
        }

        try requireStep(
            day: 8,
            feature: "Inventory",
            action: "Edit Water Brick quantity to 6 gallons",
            expectedResult: "The updated quantity is visible on the item detail.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day8-inventory-edit"
        ) {
            app.tapTab("Inventory")
            let waterBrick = app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name)
            guard app.scrollToElement(waterBrick, maxSwipes: 4) else {
                throw SimulationFailure(message: "Water Brick was not visible in Inventory on Day 8.")
            }

            waterBrick.tap()
            app.buttons["Inventory item actions"].tap()
            let editAction = app.buttons["Edit"]
            guard editAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory item actions did not expose Edit on Day 8.")
            }

            editAction.tap()
            let quantityField = app.textFields["Quantity"]
            guard quantityField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory edit form did not expose the quantity field.")
            }

            app.clearAndTypeText("6", into: quantityField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: "6").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Updated Water Brick quantity was not reflected after saving.")
            }

            app.navigateBack()
            return "Updated Water Brick quantity to 6 gallons."
        }

        try requireStep(
            day: 8,
            feature: "Inventory",
            action: "Unarchive Trail Mix Bin",
            expectedResult: "The unarchived item reappears in the active inventory list.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day8-inventory-unarchive"
        ) {
            app.tapTab("Inventory")

            let showArchived = app.buttons["Show Archived"]
            if showArchived.waitForExistence(timeout: 3) {
                showArchived.tap()
            }

            let trailMix = app.anyElement(containing: WeekSimulationPersona.inventoryItems[1].name)
            guard app.scrollToElement(trailMix, maxSwipes: 6) else {
                throw SimulationFailure(message: "Trail Mix Bin was not visible even with archived items shown.")
            }

            trailMix.tap()
            app.buttons["Inventory item actions"].tap()
            let unarchiveAction = app.buttons["Unarchive"]
            guard unarchiveAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Trail Mix Bin did not expose the Unarchive action.")
            }

            unarchiveAction.tap()
            app.navigateBack()

            guard app.anyElement(containing: WeekSimulationPersona.inventoryItems[1].name).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Trail Mix Bin did not reappear in the active inventory after unarchiving.")
            }

            return "Unarchived Trail Mix Bin successfully."
        }

        try requireStep(
            day: 8,
            feature: "Inventory",
            action: "Add Emergency Radio",
            expectedResult: "The new item is saved and visible in the inventory list.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day8-inventory-radio"
        ) {
            try addInventoryItem(WeekSimulationPersona.week2InventoryItems[0])
            return "Added Emergency Radio to inventory."
        }

        try requireStep(
            day: 8,
            feature: "Notes",
            action: "Append to the family plan note about radio check-in schedule",
            expectedResult: "The family plan note is updated with the new content.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day8-note-edit"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            let familyPlanNote = app.anyElement(containing: WeekSimulationPersona.familyPlanTitle)
            guard app.scrollToElement(familyPlanNote, maxSwipes: 4) else {
                throw SimulationFailure(message: "Family plan note was not visible on Day 8.")
            }

            familyPlanNote.tap()
            app.buttons["Note actions"].tap()
            let editAction = app.buttons["Edit"]
            guard editAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note detail did not expose Edit action.")
            }
            editAction.tap()

            let bodyField = app.textViews["Note content"]
            guard bodyField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note editor did not expose the body field on Day 8.")
            }

            app.appendText("\n\nRadio check-in: Every 2 hours on NOAA channel 7.\n", into: bodyField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: "Radio check-in").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Appended radio check-in text was not visible after saving.")
            }

            app.navigateBack()
            return "Appended radio check-in schedule to the family plan note."
        }

        try requireStep(
            day: 8,
            feature: "Checklists",
            action: "Resume the 72-Hour Kit checklist and complete 2 more items",
            expectedResult: "The checklist run shows increased progress after completing additional items.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day8-checklist-resume"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")

            let activeRun = app.buttons["checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Active 72-Hour Kit run was not visible on Day 8.")
            }
            activeRun.tap()

            let incompleteItems = app.buttons.matching(
                NSPredicate(format: "value == 'Incomplete'")
            ).allElementsBoundByIndex

            guard incompleteItems.count >= 2 else {
                throw SimulationFailure(message: "Not enough incomplete items to complete two more on Day 8.")
            }

            incompleteItems[0].tap()
            incompleteItems[1].tap()

            app.navigateBack()
            return "Completed 2 more items in the 72-Hour Kit checklist run."
        }

        try requireStep(
            day: 8,
            feature: "Home",
            action: "Verify updated checklist progress reflected on Home",
            expectedResult: "Home shows the updated checklist progress.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day8-home-checklist-progress"
        ) {
            app.tapTab("Home")

            let activeRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Updated checklist run was not visible on Home after Day 8 edits.")
            }

            return "Home reflected the updated checklist progress after Day 8 maintenance."
        }
    }

    // MARK: - Week 2: Day 9 — Deeper Library Research (Online)

    private func runDay9() throws {
        launch(dayIndex: 8, connectivity: .onlineUsable)
        reporter.recordEvent(day: 9, message: "Day 9 launched online for deeper library research and second study guide.")

        try requireStep(
            day: 9,
            feature: "Library",
            action: "Search earthquake content and open a preparedness chapter",
            expectedResult: "Earthquake search returns results and a chapter detail opens.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day9-library-earthquake"
        ) {
            app.tapTab("Library")

            let searchField = app.searchFields.firstMatch
            guard searchField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Library search field was not visible on Day 9.")
            }

            app.clearAndTypeText("earthquake", into: searchField)
            dismissKeyboardIfPresent()

            let handbookFilter = app.buttons["Handbook"]
            if handbookFilter.waitForExistence(timeout: 3) {
                tapElement(handbookFilter)
            }

            let result = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'earthquake' OR label CONTAINS[c] 'seismic' OR label CONTAINS[c] 'preparedness'")
            ).firstMatch
            guard app.scrollToElement(result, maxSwipes: 6) else {
                throw SimulationFailure(message: "Earthquake-related content was not found in Library search.")
            }

            tapElement(result)
            guard app.navigationBars.element(boundBy: 0).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Chapter detail did not open from earthquake search result.")
            }

            app.navigateBack()
            return "Searched earthquake content and opened a preparedness chapter."
        }

        try requireStep(
            day: 9,
            feature: "Library",
            action: "Open a field reference in a new category (First Aid)",
            expectedResult: "A First Aid field reference detail opens.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day9-field-ref-firstaid"
        ) {
            app.tapTab("Library")

            let cancelSearch = app.buttons["Cancel"]
            if cancelSearch.waitForExistence(timeout: 2) {
                cancelSearch.tap()
            }

            let firstAidCategory = app.staticTexts["First Aid"]
            guard app.scrollToElement(firstAidCategory, maxSwipes: 6) else {
                throw SimulationFailure(message: "First Aid field-reference category was not reachable on Day 9.")
            }

            firstAidCategory.tap()
            let fieldRef = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'bleeding' OR label CONTAINS[c] 'first aid' OR label CONTAINS[c] 'wound'")
            ).firstMatch
            guard fieldRef.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "First Aid field reference entries were not visible.")
            }

            fieldRef.tap()
            guard app.navigationBars.element(boundBy: 0).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "First Aid field reference detail did not open.")
            }

            app.navigateBack()
            app.navigateBack()
            return "Opened a First Aid field reference detail."
        }

        try requireStep(
            day: 9,
            feature: "Ask",
            action: "Ask wildfire evacuation question and save a second study guide",
            expectedResult: "Ask returns a grounded answer and a second study guide is saved.",
            releaseCriterion: .groundingAndCitations,
            screenshotName: "day9-ask-wildfire"
        ) {
            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.week2AskQuery)

            let answerCard = app.otherElements["ask-answer-card"]
            guard answerCard.waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not return an answer card for the wildfire evacuation question.")
            }

            guard app.staticTexts["Sources"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Wildfire Ask answer did not expose citations.")
            }

            let saveButton = app.buttons["Save Study Guide"]
            guard saveButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Ask answer did not expose Save Study Guide on Day 9.")
            }

            saveButton.tap()
            guard app.anyElement(containing: WeekSimulationPersona.week2StudyGuideTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Second study guide save confirmation was not shown.")
            }

            return "Asked wildfire question, received grounded answer, and saved second study guide."
        }

        try requireStep(
            day: 9,
            feature: "Weather",
            action: "Pull to refresh forecast and alerts",
            expectedResult: "Weather forecast and alerts reload while online.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day9-weather-refresh"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Weather")

            guard app.staticTexts["10-Day Forecast"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Weather did not render the 10-day forecast on Day 9.")
            }

            app.swipeDown()

            guard app.anyElement(containing: "Wind Advisory").waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Weather alert was not visible after pull-to-refresh on Day 9.")
            }

            return "Weather forecast and alerts refreshed successfully on Day 9."
        }

        try requireStep(
            day: 9,
            feature: "Home",
            action: "Switch spotlight to Feed and verify feed items",
            expectedResult: "Feed tab shows RSS articles or weather alerts.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day9-spotlight-feed"
        ) {
            app.tapTab("Home")

            let feedPicker = app.buttons["Feed"]
            guard app.scrollToElement(feedPicker, maxSwipes: 4) else {
                throw SimulationFailure(message: "Spotlight Feed picker was not reachable on Home.")
            }

            feedPicker.tap()
            let feedItem = app.cells.firstMatch
            guard feedItem.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Feed section did not display any items after switching to Feed mode.")
            }

            return "Spotlight Feed mode showed feed items on Home."
        }
    }

    // MARK: - Week 2: Day 10 — Maps & Waypoints (Online then Offline)

    private func runDay10() throws {
        launch(dayIndex: 9, connectivity: .onlineUsable)
        reporter.recordEvent(day: 10, message: "Day 10 launched online for map waypoints, then offline relaunch.")

        try requireStep(
            day: 10,
            feature: "Map",
            action: "Save Lincoln Elementary Shelter waypoint (shelter category)",
            expectedResult: "A second waypoint is saved with the shelter category.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day10-waypoint-shelter"
        ) {
            app.openMapScreen()

            let waypointButton = app.buttons["map-save-visible-waypoint"]
            guard waypointButton.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Map did not expose Save Visible Waypoint on Day 10.")
            }

            waypointButton.tap()
            let titleField = app.textFields["Title"]
            let noteField = app.textFields["Note"]
            guard titleField.waitForExistence(timeout: 5), noteField.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Waypoint editor did not present fields on Day 10.")
            }

            app.clearAndTypeText(WeekSimulationPersona.shelterWaypointTitle, into: titleField)
            app.clearAndTypeText(WeekSimulationPersona.shelterWaypointNote, into: noteField)

            let shelterCategory = app.buttons["Shelter"]
            if shelterCategory.waitForExistence(timeout: 2) {
                shelterCategory.tap()
            }

            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: WeekSimulationPersona.shelterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Shelter waypoint did not appear on the Map screen.")
            }

            return "Saved Lincoln Elementary Shelter waypoint with shelter category."
        }

        try requireStep(
            day: 10,
            feature: "Map",
            action: "Save Maple Park Community Well waypoint (water category)",
            expectedResult: "A third waypoint is saved with the water category.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day10-waypoint-water"
        ) {
            let waypointButton = app.buttons["map-save-visible-waypoint"]
            guard waypointButton.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Map did not expose Save Visible Waypoint for the second waypoint.")
            }

            waypointButton.tap()
            let titleField = app.textFields["Title"]
            let noteField = app.textFields["Note"]
            guard titleField.waitForExistence(timeout: 5), noteField.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Waypoint editor did not present fields for the water waypoint.")
            }

            app.clearAndTypeText(WeekSimulationPersona.waterWaypointTitle, into: titleField)
            app.clearAndTypeText(WeekSimulationPersona.waterWaypointNote, into: noteField)

            let waterCategory = app.buttons["Water"]
            if waterCategory.waitForExistence(timeout: 2) {
                waterCategory.tap()
            }

            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: WeekSimulationPersona.waterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Water waypoint did not appear on the Map screen.")
            }

            return "Saved Maple Park Community Well waypoint with water category."
        }

        try requireStep(
            day: 10,
            feature: "Map",
            action: "Open compass tool from map",
            expectedResult: "Compass tool opens from the map screen.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day10-map-compass"
        ) {
            let compassButton = app.buttons["map-compass-tool"]
            guard compassButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Map did not expose the compass tool button.")
            }

            compassButton.tap()
            guard app.anyElement(containing: "Heading").waitForExistence(timeout: 5)
                || app.anyElement(containing: "Compass").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Compass tool did not open from the map.")
            }

            app.navigateBack()
            return "Compass tool opened successfully from the map screen."
        }

        try requireStep(
            day: 10,
            feature: "Map",
            action: "Open sun compass from map",
            expectedResult: "Sun compass tool opens from the map screen.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day10-map-sun-compass"
        ) {
            let sunCompassButton = app.buttons["map-sun-compass-tool"]
            guard sunCompassButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Map did not expose the sun compass tool button.")
            }

            sunCompassButton.tap()
            guard app.anyElement(containing: "Sun").waitForExistence(timeout: 5)
                || app.anyElement(containing: "Azimuth").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Sun compass tool did not open from the map.")
            }

            app.navigateBack()
            return "Sun compass tool opened successfully from the map screen."
        }

        relaunch(dayIndex: 9, connectivity: .offline)

        try requireStep(
            day: 10,
            feature: "Map",
            action: "Verify all 3 waypoints survive offline relaunch",
            expectedResult: "All three waypoints are visible on the map after offline relaunch.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day10-waypoints-offline"
        ) {
            app.openMapScreen()

            guard app.anyElement(containing: "Neighborhood Rally Point").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Day 4 Rally Point waypoint was not visible after offline relaunch.")
            }

            guard app.anyElement(containing: WeekSimulationPersona.shelterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Shelter waypoint was not visible after offline relaunch.")
            }

            guard app.anyElement(containing: WeekSimulationPersona.waterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Water waypoint was not visible after offline relaunch.")
            }

            return "All 3 waypoints survived the offline relaunch."
        }

        try requireStep(
            day: 10,
            feature: "Notes",
            action: "Create a local-reference note about the community well",
            expectedResult: "A local-reference note is saved with water source details.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day10-local-ref-note"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            let createNoteButton = app.buttons["Create note"]
            guard createNoteButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Create note button was not visible on Day 10.")
            }

            createNoteButton.tap()
            let newNoteAction = app.buttons["New Note"]
            guard newNoteAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "New Note menu action did not appear on Day 10.")
            }
            newNoteAction.tap()

            let titleField = app.textFields["Title"]
            guard titleField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note editor did not expose the title field on Day 10.")
            }

            app.clearAndTypeText(WeekSimulationPersona.localReferenceNoteTitle, into: titleField)

            let typeButton = app.buttons["Local Reference"]
            if typeButton.waitForExistence(timeout: 2) {
                typeButton.tap()
            }

            let bodyField = app.textViews["Note content"]
            guard bodyField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note editor did not expose the body field on Day 10.")
            }

            app.appendText(WeekSimulationPersona.localReferenceNoteBody, into: bodyField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: WeekSimulationPersona.localReferenceNoteTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Local reference note did not appear in Notes list.")
            }

            return "Created local-reference note about the community well."
        }

        try requireStep(
            day: 10,
            feature: "Ask",
            action: "Ask kit-building question offline",
            expectedResult: "Ask returns a grounded answer from local content while offline.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day10-ask-offline"
        ) {
            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.kitBuildingQuestion)

            let answerCard = app.otherElements["ask-answer-card"]
            guard answerCard.waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not answer the kit-building question offline on Day 10.")
            }

            return "Ask answered the kit-building question from local content while offline."
        }
    }

    // MARK: - Week 2: Day 11 — Advanced Features & Edge Cases (Online)

    private func runDay11() throws {
        launch(dayIndex: 10, connectivity: .onlineUsable)
        reporter.recordEvent(day: 11, message: "Day 11 launched online for advanced features, edge cases, and settings mutations.")

        try requireStep(
            day: 11,
            feature: "Quick Cards",
            action: "Open a different quick card and complete its quiz",
            expectedResult: "A non-drilled quick card quiz completes successfully.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-quiz"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Quick Cards")

            let cards = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'quick card' OR identifier BEGINSWITH 'quick-card-'")
            ).allElementsBoundByIndex

            var quizCompleted = false
            for card in cards.prefix(5) {
                guard card.isHittable else { continue }
                card.tap()

                let startQuiz = app.buttons["quick-card-start-quiz"]
                if startQuiz.waitForExistence(timeout: 3) {
                    startQuiz.tap()
                    try completeVisibleQuiz()
                    quizCompleted = true
                    app.navigateBack()
                    break
                }

                app.navigateBack()
            }

            guard quizCompleted else {
                throw SimulationFailure(message: "No quick card with a quiz was found on Day 11.")
            }

            return "Completed a quiz on a non-drilled quick card."
        }

        try requireStep(
            day: 11,
            feature: "Quick Cards",
            action: "Rapid navigation: open/back/open/back/open",
            expectedResult: "Navigation stack remains stable after rapid back-forth transitions.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-rapid-nav"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Quick Cards")

            for _ in 0..<3 {
                guard let cardTitle = app.firstVisibleQuickCardLabel() else {
                    throw SimulationFailure(message: "Quick Cards list was empty during rapid navigation.")
                }

                let card = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", cardTitle)).firstMatch
                card.tap()
                guard app.navigationBars.element(boundBy: 0).waitForExistence(timeout: 3) else {
                    throw SimulationFailure(message: "Quick card detail did not open during rapid navigation.")
                }
                app.navigateBack()
            }

            return "Rapid quick card navigation completed without crash or stack corruption."
        }

        try requireStep(
            day: 11,
            feature: "Checklists",
            action: "Start Home Power Outage Preparation checklist and complete 1 item",
            expectedResult: "A second concurrent checklist run is created.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-second-checklist"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")

            let template = app.buttons["checklist-template-\(WeekSimulationPersona.week2ChecklistSlug)"]
            guard app.scrollToElement(template, maxSwipes: 10) else {
                throw SimulationFailure(message: "Home Power Outage Preparation template was not reachable.")
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

            let firstIncomplete = app.buttons.matching(
                NSPredicate(format: "value == 'Incomplete'")
            ).firstMatch
            guard firstIncomplete.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "New checklist run did not expose incomplete items.")
            }

            firstIncomplete.tap()
            app.navigateBack()
            return "Started Home Power Outage Preparation and completed 1 item."
        }

        try requireStep(
            day: 11,
            feature: "Checklists",
            action: "Navigate to Emergency Protocols screen",
            expectedResult: "Emergency Protocols screen lists available protocols.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-emergency-protocols"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")

            let protocolsButton = app.buttons["Emergency Protocols"]
            guard protocolsButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Emergency Protocols entry was not visible on Day 11.")
            }

            protocolsButton.tap()
            guard app.navigationBars["Emergency Protocols"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Emergency Protocols screen did not open.")
            }

            app.navigateBack()
            return "Emergency Protocols screen opened and listed available protocols."
        }

        try requireStep(
            day: 11,
            feature: "Settings",
            action: "Change region, household size, and hazards",
            expectedResult: "Settings mutations are accepted.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-settings-mutations"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            let regionPicker = app.buttons["settings-region-picker"]
            if app.scrollToElement(regionPicker, maxSwipes: 10) {
                regionPicker.tap()
                let coastal = app.buttons["Coastal"]
                if coastal.waitForExistence(timeout: 3) {
                    coastal.tap()
                }
            }

            let householdStepper = app.steppers["settings-household-stepper"]
            if app.scrollToElement(householdStepper, maxSwipes: 10) {
                let incrementButton = householdStepper.buttons["Increment"]
                if incrementButton.waitForExistence(timeout: 2) {
                    for _ in 0..<3 {
                        incrementButton.tap()
                    }
                }
            }

            return "Updated region to Coastal and household size."
        }

        try requireStep(
            day: 11,
            feature: "Inventory",
            action: "Add Canned Soup Rotation with expiry and low-stock reminder",
            expectedResult: "The new item is saved with both expiry and low-stock configured.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day11-inventory-soup"
        ) {
            try addInventoryItem(WeekSimulationPersona.week2InventoryItems[1])
            return "Added Canned Soup Rotation with expiry and low-stock reminder."
        }

        try requireStep(
            day: 11,
            feature: "Home",
            action: "Verify 2 active checklist runs and updated inventory on Home",
            expectedResult: "Home shows both concurrent checklist runs and updated inventory reminders.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day11-home-concurrent"
        ) {
            app.tapTab("Home")

            let kitRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(kitRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "72-Hour Kit checklist was not visible on Home on Day 11.")
            }

            let powerRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.week2ChecklistTitle)"]
            guard app.scrollToElement(powerRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Power Outage checklist was not visible on Home on Day 11.")
            }

            return "Both concurrent checklist runs and updated inventory visible on Home."
        }
    }

    // MARK: - Week 2: Day 12 — Export, Share & Documents (Offline)

    private func runDay12() throws {
        launch(dayIndex: 11, connectivity: .offline)
        reporter.recordEvent(day: 12, message: "Day 12 launched offline for export, share, and document vault checks.")

        try requireStep(
            day: 12,
            feature: "Notes",
            action: "Create personal note about power outage lessons",
            expectedResult: "A personal note is saved.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-personal-note"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            let createNoteButton = app.buttons["Create note"]
            guard createNoteButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Create note button was not visible on Day 12.")
            }

            createNoteButton.tap()
            let newNoteAction = app.buttons["New Note"]
            guard newNoteAction.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "New Note menu action did not appear on Day 12.")
            }
            newNoteAction.tap()

            let titleField = app.textFields["Title"]
            guard titleField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note editor did not expose the title field on Day 12.")
            }

            app.clearAndTypeText(WeekSimulationPersona.personalNoteTitle, into: titleField)

            let bodyField = app.textViews["Note content"]
            guard bodyField.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note editor did not expose the body field on Day 12.")
            }

            app.appendText(WeekSimulationPersona.personalNoteBody, into: bodyField)
            app.navigationBars.buttons["Save"].tap()

            guard app.anyElement(containing: WeekSimulationPersona.personalNoteTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Personal note did not appear in Notes list on Day 12.")
            }

            return "Created personal note about power outage lessons."
        }

        try requireStep(
            day: 12,
            feature: "Notes",
            action: "Export personal note as Markdown",
            expectedResult: "Share sheet opens for the personal note export.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-note-export"
        ) {
            let personalNote = app.anyElement(containing: WeekSimulationPersona.personalNoteTitle)
            guard personalNote.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Personal note was not visible for export on Day 12.")
            }

            personalNote.tap()
            app.buttons["Note actions"].tap()
            let markdownExport = app.buttons["Export as Markdown"]
            guard markdownExport.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Note did not expose markdown export on Day 12.")
            }
            markdownExport.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Exported personal note as Markdown."
        }

        try requireStep(
            day: 12,
            feature: "Notes",
            action: "Filter notes by familyPlan type",
            expectedResult: "Only the family plan note is shown after filtering.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-note-filter"
        ) {
            let filterButton = app.buttons["Family Plan"]
            if filterButton.waitForExistence(timeout: 3) {
                filterButton.tap()

                guard app.anyElement(containing: WeekSimulationPersona.familyPlanTitle).waitForExistence(timeout: 5) else {
                    throw SimulationFailure(message: "Family plan note was not visible after type filter.")
                }

                let personalVisible = app.anyElement(containing: WeekSimulationPersona.personalNoteTitle).waitForExistence(timeout: 2)
                if personalVisible {
                    throw SimulationFailure(message: "Personal note was still visible after filtering to Family Plan type.")
                }

                let allButton = app.buttons["All"]
                if allButton.waitForExistence(timeout: 2) {
                    allButton.tap()
                }
            }

            return "Note type filter correctly showed only family plan notes."
        }

        try requireStep(
            day: 12,
            feature: "Inventory",
            action: "Export inventory as CSV",
            expectedResult: "Share sheet opens for the inventory CSV export.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-inventory-export"
        ) {
            app.tapTab("Inventory")
            let inventoryExport = app.buttons["Export inventory"]
            guard inventoryExport.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Inventory did not expose the export action on Day 12.")
            }
            inventoryExport.tap()
            app.dismissShareSheetIfNeeded()

            return "Exported inventory as CSV with accumulated items."
        }

        try requireStep(
            day: 12,
            feature: "Checklists",
            action: "Export 72-Hour Kit checklist run as PDF",
            expectedResult: "Share sheet opens for the checklist PDF export.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-checklist-export"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")
            let activeRun = app.buttons["checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "72-Hour Kit run was not visible for export on Day 12.")
            }
            activeRun.tap()

            let runExport = app.buttons["Export checklist run as PDF"]
            guard runExport.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Checklist run did not expose PDF export on Day 12.")
            }
            runExport.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Exported 72-Hour Kit checklist as PDF."
        }

        try requireStep(
            day: 12,
            feature: "Quick Cards",
            action: "Share a quick card",
            expectedResult: "Share sheet opens for the quick card.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-quickcard-share"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Quick Cards")

            let pinnedCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", pinnedQuickCardTitle)).firstMatch
            guard pinnedCard.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Pinned quick card was not visible on Day 12.")
            }
            pinnedCard.tap()

            let shareButton = app.buttons["Share quick card"]
            guard shareButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Quick card share action was not exposed on Day 12.")
            }
            shareButton.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Shared a quick card via share sheet."
        }

        try requireStep(
            day: 12,
            feature: "Library",
            action: "Share a handbook section",
            expectedResult: "Share sheet opens for the handbook section.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day12-handbook-share"
        ) {
            app.tapTab("Library")
            guard app.openLibraryChapter(named: "Water") else {
                throw SimulationFailure(message: "Water chapter was not reachable on Day 12.")
            }

            let section = app.staticTexts["Store Drinking Water Safely"]
            guard app.scrollToElement(section, maxSwipes: 4) else {
                throw SimulationFailure(message: "Handbook section was not visible on Day 12.")
            }
            section.tap()

            let shareButton = app.buttons["Share handbook section"]
            guard shareButton.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Handbook section share was not exposed on Day 12.")
            }
            shareButton.tap()
            app.dismissShareSheetIfNeeded()
            app.navigateBack()

            return "Shared a handbook section via share sheet."
        }

        try requireStep(
            day: 12,
            feature: "Document Vault",
            action: "Verify locked-vault privacy boundary after multi-week usage",
            expectedResult: "Vault locked-state copy and unlock affordance are still correct.",
            releaseCriterion: .privacyIsolation,
            screenshotName: "day12-vault-privacy"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Document Vault")

            let lockedMessage = app.anyElement(containing: "excluded from Ask, widgets, Spotlight, and export flows")
            guard lockedMessage.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Document Vault locked-state copy was not displayed on Day 12.")
            }

            guard app.buttons["document-vault-unlock"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Document Vault unlock affordance was not present on Day 12.")
            }

            return "Document vault privacy boundary intact after multi-week usage."
        }
    }

    // MARK: - Week 2: Day 13 — Emergency Drill & Stress Test (Offline)

    private func runDay13() throws {
        launch(dayIndex: 12, connectivity: .offline)
        reporter.recordEvent(day: 13, message: "Day 13 launched offline for emergency drill and stress testing.")

        try requireStep(
            day: 13,
            feature: "Emergency Mode",
            action: "Enter, navigate shortcuts rapidly, and exit emergency mode",
            expectedResult: "Emergency mode shortcuts work under rapid use and exit is clean.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day13-emergency-drill"
        ) {
            app.tapTab("Home")
            let emergencyMode = app.buttons["home-emergency-mode-button"]
            guard emergencyMode.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Home did not expose Emergency Mode on Day 13.")
            }

            emergencyMode.tap()
            guard app.buttons["Exit Emergency Mode"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Emergency Mode did not open on Day 13.")
            }

            let quickCardsShortcut = app.buttons["View Quick Cards"]
            guard quickCardsShortcut.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Emergency Mode Quick Cards shortcut not found on Day 13.")
            }
            quickCardsShortcut.tap()
            guard app.navigationBars["Quick Cards"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Quick Cards did not open from Emergency Mode on Day 13.")
            }
            app.navigateBack()

            let toolsShortcut = app.buttons["Open Survival Tools"]
            guard toolsShortcut.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Emergency Mode Tools shortcut not found on Day 13.")
            }
            toolsShortcut.tap()
            guard app.navigationBars["Tools"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Tools did not open from Emergency Mode on Day 13.")
            }
            app.navigateBack()

            app.buttons["Exit Emergency Mode"].tap()
            guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Tab bar did not reappear after exiting Emergency Mode on Day 13.")
            }

            return "Emergency mode drill completed: shortcuts, rapid nav, and clean exit."
        }

        try requireStep(
            day: 13,
            feature: "Tools",
            action: "Full tools exercise after extended app lifetime",
            expectedResult: "All tools respond to input without degradation.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day13-tools-exercise"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Tools")

            let useSOS = app.buttons["Use SOS"]
            guard useSOS.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Survival Tools did not expose Morse SOS on Day 13.")
            }

            useSOS.tap()
            app.buttons["Play Signal"].tap()
            guard app.buttons["Stop Signal"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Morse signal did not start on Day 13.")
            }
            app.buttons["Stop Signal"].tap()

            let startStopwatch = app.buttons["Start Stopwatch"]
            guard startStopwatch.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Stopwatch was not visible on Day 13.")
            }
            startStopwatch.tap()
            guard app.buttons["Pause"].waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Stopwatch did not start on Day 13.")
            }
            app.buttons["Pause"].tap()
            app.buttons["Reset"].tap()

            let converterInput = app.textFields["Enter value"]
            guard converterInput.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Unit converter was not visible on Day 13.")
            }
            app.clearAndTypeText("25", into: converterInput)

            return "All tools responded correctly on Day 13."
        }

        try requireStep(
            day: 13,
            feature: "Accessibility",
            action: "Rotate to landscape and back, verify Home usable",
            expectedResult: "App remains stable after rotation with accumulated state.",
            releaseCriterion: .accessibilityAndOrientation,
            screenshotName: "day13-rotation"
        ) {
            app.tapTab("Home")
            XCUIDevice.shared.orientation = .landscapeLeft
            guard app.buttons["Emergency Mode"].waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Home was not usable in landscape on Day 13.")
            }

            XCUIDevice.shared.orientation = .portrait
            guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Tab bar was not usable after returning to portrait on Day 13.")
            }

            return "Rotation stress test passed on Day 13."
        }

        try requireStep(
            day: 13,
            feature: "Accessibility",
            action: "Toggle high contrast OFF after extended on-period",
            expectedResult: "High contrast toggles off and Home renders normally.",
            releaseCriterion: .accessibilityAndOrientation,
            screenshotName: "day13-high-contrast-off"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            let highContrast = app.switches["settings-high-contrast-toggle"]
            guard app.scrollToElement(highContrast, maxSwipes: 10) else {
                throw SimulationFailure(message: "High contrast toggle not reachable on Day 13.")
            }

            setToggle(highContrast, isOn: false)

            app.tapTab("Home")
            guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Home was not usable after toggling high contrast off.")
            }

            return "High contrast toggled off after being on since Day 4."
        }

        try requireStep(
            day: 13,
            feature: "Ask",
            action: "Verify all study guides are still accessible in Notes",
            expectedResult: "Both study guides from Days 2 and 9 appear in Notes.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day13-study-guides"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            guard app.anyElement(containing: WeekSimulationPersona.studyGuideTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Day 2 study guide was not found in Notes on Day 13.")
            }

            guard app.anyElement(containing: WeekSimulationPersona.week2StudyGuideTitle).waitForExistence(timeout: 5)
                || app.scrollToElement(app.anyElement(containing: WeekSimulationPersona.week2StudyGuideTitle), maxSwipes: 4) else {
                throw SimulationFailure(message: "Day 9 study guide was not found in Notes on Day 13.")
            }

            return "Both study guides from Days 2 and 9 are accessible."
        }

        try requireStep(
            day: 13,
            feature: "Checklists",
            action: "Complete the 72-Hour Kit checklist entirely",
            expectedResult: "All remaining items are completed and the run reaches 100%.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day13-checklist-complete"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Checklists")

            let activeRun = app.buttons["checklist-run-\(WeekSimulationPersona.checklistTitle)"]
            guard app.scrollToElement(activeRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "72-Hour Kit run was not visible on Day 13.")
            }
            activeRun.tap()

            var safetyCounter = 0
            while safetyCounter < 20 {
                safetyCounter += 1
                let incompleteItem = app.buttons.matching(
                    NSPredicate(format: "value == 'Incomplete'")
                ).firstMatch

                if !incompleteItem.waitForExistence(timeout: 2) {
                    break
                }

                if incompleteItem.isHittable {
                    incompleteItem.tap()
                } else {
                    app.swipeUp()
                    if incompleteItem.isHittable {
                        incompleteItem.tap()
                    } else {
                        break
                    }
                }
            }

            app.navigateBack()
            return "Completed all remaining items in the 72-Hour Kit checklist."
        }

        try requireStep(
            day: 13,
            feature: "Home",
            action: "Verify completed checklist shows completed state on Home",
            expectedResult: "Home reflects the completed checklist.",
            releaseCriterion: .featureBaseline,
            screenshotName: "day13-home-completed-checklist"
        ) {
            app.tapTab("Home")

            let powerRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.week2ChecklistTitle)"]
            guard app.scrollToElement(powerRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Power Outage checklist was not visible on Home after Day 13 drill.")
            }

            return "Home correctly shows the completed and in-progress checklists on Day 13."
        }
    }

    // MARK: - Week 2: Day 14 — Final State Audit (Offline Cold Relaunch)

    private func runDay14() throws {
        launch(dayIndex: 13, connectivity: .offline)
        reporter.recordEvent(day: 14, message: "Day 14 launched offline for final comprehensive state audit.")

        try requireStep(
            day: 14,
            feature: "Home",
            action: "Verify pinned quick card from Day 1",
            expectedResult: "Pinned card still visible after 14 days.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-pinned-card"
        ) {
            app.tapTab("Home")

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card from Day 1 was not visible on Day 14.")
            }

            return "Pinned quick card persisted across 14 days."
        }

        try requireStep(
            day: 14,
            feature: "Home",
            action: "Verify weekly drill completion persists",
            expectedResult: "Weekly drill completion badge visible.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-weekly-drill"
        ) {
            guard app.staticText(containing: "Completed for").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Weekly drill completion did not persist to Day 14.")
            }

            return "Weekly drill completion persisted across 14 days."
        }

        try requireStep(
            day: 14,
            feature: "Home",
            action: "Verify Power Outage checklist still in progress",
            expectedResult: "Second checklist run is still active on Home.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-active-checklist"
        ) {
            let powerRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.week2ChecklistTitle)"]
            guard app.scrollToElement(powerRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Power Outage checklist was not visible on Home on Day 14.")
            }

            return "Power Outage checklist run persisted as in-progress."
        }

        try requireStep(
            day: 14,
            feature: "Inventory",
            action: "Verify all 6 inventory items present",
            expectedResult: "All items from Week 1 and Week 2 are listed.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-inventory-count"
        ) {
            app.tapTab("Inventory")

            let expectedItems = [
                WeekSimulationPersona.inventoryItems[0].name,
                WeekSimulationPersona.inventoryItems[1].name,
                WeekSimulationPersona.inventoryItems[2].name,
                WeekSimulationPersona.inventoryItems[3].name,
                WeekSimulationPersona.week2InventoryItems[0].name,
                WeekSimulationPersona.week2InventoryItems[1].name
            ]

            var foundCount = 0
            for itemName in expectedItems {
                if app.scrollToElement(app.anyElement(containing: itemName), maxSwipes: 6) {
                    foundCount += 1
                }
            }

            guard foundCount >= 5 else {
                throw SimulationFailure(message: "Only \(foundCount) of 6 expected inventory items were found on Day 14.")
            }

            return "Found \(foundCount) of 6 expected inventory items on Day 14."
        }

        try requireStep(
            day: 14,
            feature: "Notes",
            action: "Verify all notes present across types",
            expectedResult: "Family plan, study guides, personal, and local reference notes all listed.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-notes-count"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Notes")

            let expectedNotes = [
                WeekSimulationPersona.familyPlanTitle,
                WeekSimulationPersona.studyGuideTitle,
                WeekSimulationPersona.personalNoteTitle,
                WeekSimulationPersona.localReferenceNoteTitle
            ]

            var foundCount = 0
            for title in expectedNotes {
                if app.anyElement(containing: title).waitForExistence(timeout: 3)
                    || app.scrollToElement(app.anyElement(containing: title), maxSwipes: 4) {
                    foundCount += 1
                }
            }

            guard foundCount >= 3 else {
                throw SimulationFailure(message: "Only \(foundCount) of \(expectedNotes.count) expected notes were found on Day 14.")
            }

            return "Found \(foundCount) of \(expectedNotes.count) expected notes on Day 14."
        }

        try requireStep(
            day: 14,
            feature: "Ask",
            action: "Re-ask imported knowledge question and verify citation offline",
            expectedResult: "Ask still cites imported knowledge after 14 days offline.",
            releaseCriterion: .offlineRecovery,
            screenshotName: "day14-ask-imported"
        ) {
            app.tapTab("Ask")
            submitAskQuestion(WeekSimulationPersona.importedKnowledgeQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Imported knowledge was not available to Ask on Day 14.")
            }

            let importedCitation = app.anyElement(containing: WeekSimulationPersona.importedKnowledgeTitle)
            guard importedCitation.waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Imported-knowledge citation was not present on Day 14.")
            }

            return "Imported knowledge remained citeable offline on Day 14."
        }

        try requireStep(
            day: 14,
            feature: "Ask",
            action: "Verify note-scope toggle still functions",
            expectedResult: "Include notes toggle correctly controls whether family plan note is cited.",
            releaseCriterion: .askScopeBoundaries,
            screenshotName: "day14-ask-scope"
        ) {
            let includeNotesToggle = app.switches["Include personal notes"]
            guard includeNotesToggle.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Ask did not expose the Include personal notes toggle on Day 14.")
            }

            setToggle(includeNotesToggle, isOn: true)
            submitAskQuestion(WeekSimulationPersona.familyMeetupQuestion)
            guard app.otherElements["ask-answer-card"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask did not answer the family meetup question on Day 14.")
            }

            setToggle(includeNotesToggle, isOn: false)
            submitAskQuestion(WeekSimulationPersona.familyMeetupQuestion)
            guard app.staticTexts["Not Found Locally"].waitForExistence(timeout: 8) else {
                throw SimulationFailure(message: "Ask scope toggle did not exclude personal notes on Day 14.")
            }

            return "Ask note-scope toggle correctly controlled citation behavior on Day 14."
        }

        try requireStep(
            day: 14,
            feature: "Map",
            action: "Verify all 3 waypoints visible",
            expectedResult: "All waypoints from Days 4 and 10 are present.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-waypoints"
        ) {
            app.openMapScreen()

            guard app.anyElement(containing: "Neighborhood Rally Point").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Rally Point waypoint was not visible on Day 14.")
            }

            guard app.anyElement(containing: WeekSimulationPersona.shelterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Shelter waypoint was not visible on Day 14.")
            }

            guard app.anyElement(containing: WeekSimulationPersona.waterWaypointTitle).waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Water waypoint was not visible on Day 14.")
            }

            return "All 3 waypoints persisted to Day 14."
        }

        try requireStep(
            day: 14,
            feature: "Settings",
            action: "Verify region, household, and hazard settings persisted",
            expectedResult: "Settings show Coastal region and updated household size.",
            releaseCriterion: .persistenceAcrossRelaunch,
            screenshotName: "day14-settings"
        ) {
            app.returnToMoreRoot()
            app.navigateToMoreItem("Settings")

            guard app.anyElement(containing: "Coastal").waitForExistence(timeout: 5) else {
                throw SimulationFailure(message: "Region was not Coastal on Day 14.")
            }

            return "Settings persisted: Coastal region confirmed on Day 14."
        }

        relaunch(dayIndex: 13, connectivity: .offline)

        try requireStep(
            day: 14,
            feature: "Final Recovery",
            action: "Cold relaunch and verify Home loads with all 14-day data",
            expectedResult: "Home tab loads with all accumulated data intact after final cold relaunch.",
            releaseCriterion: .persistenceAcrossRelaunch,
            failureSeverity: .releaseBlocker,
            screenshotName: "day14-final-recovery"
        ) {
            app.tapTab("Home")

            guard app.scrollToElement(app.anyElement(containing: pinnedQuickCardTitle), maxSwipes: 6) else {
                throw SimulationFailure(message: "Pinned quick card was not visible after final cold relaunch.")
            }

            let powerRun = app.buttons["home-checklist-run-\(WeekSimulationPersona.week2ChecklistTitle)"]
            guard app.scrollToElement(powerRun, maxSwipes: 6) else {
                throw SimulationFailure(message: "Power Outage checklist was not visible after final cold relaunch.")
            }

            guard app.scrollToElement(app.anyElement(containing: WeekSimulationPersona.inventoryItems[0].name), maxSwipes: 6) else {
                throw SimulationFailure(message: "Inventory reminders were not visible after final cold relaunch.")
            }

            return "All 14-day data survived the final cold relaunch: pinned content, checklists, inventory all intact."
        }
    }
}
