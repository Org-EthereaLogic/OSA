import XCTest

@MainActor
protocol SimulationTestSupport: XCTestCase {
    var app: XCUIApplication! { get set }
    var reporter: WeekSimulationReporter! { get }
    var pinnedQuickCardTitle: String { get set }
}

@MainActor
extension SimulationTestSupport {

    // MARK: - Launch Helpers

    func launchSimulation(
        dayIndex: Int,
        connectivity: WeekSimulationConnectivity,
        resetState: Bool = false
    ) -> XCUIApplication {
        app?.terminate()
        let launched = launchWeekSimulationApp(
            dayIndex: dayIndex,
            connectivity: connectivity,
            resetState: resetState
        )
        return launched
    }

    func relaunchSimulation(
        dayIndex: Int,
        connectivity: WeekSimulationConnectivity
    ) -> XCUIApplication {
        app?.terminate()
        return launchWeekSimulationApp(
            dayIndex: dayIndex,
            connectivity: connectivity,
            resetState: false
        )
    }

    // MARK: - Step Recording

    @discardableResult
    func runStep(
        day: Int,
        feature: String,
        action: String,
        expectedResult: String,
        releaseCriterion: ReleaseCriterion,
        failureSeverity: SimulationSeverity = .releaseRisk,
        screenshotName: String? = nil,
        body: () throws -> String
    ) -> Bool {
        let startedAt = Date()

        do {
            let actualResult = try body()
            return reporter.recordStep(
                day: day,
                feature: feature,
                action: action,
                expectedResult: expectedResult,
                success: true,
                actualResult: actualResult,
                releaseCriterion: releaseCriterion,
                screenshotName: screenshotName,
                app: app,
                testCase: self,
                durationMilliseconds: stepDurationMilliseconds(startedAt)
            )
        } catch {
            reporter.recordEvent(
                day: day,
                message: "\(feature) failed: \(error.localizedDescription)",
                severity: failureSeverity
            )
            return reporter.recordStep(
                day: day,
                feature: feature,
                action: action,
                expectedResult: expectedResult,
                success: false,
                actualResult: error.localizedDescription,
                releaseCriterion: releaseCriterion,
                failureSeverity: failureSeverity,
                screenshotName: screenshotName,
                app: app,
                testCase: self,
                durationMilliseconds: stepDurationMilliseconds(startedAt)
            )
        }
    }

    func requireStep(
        day: Int,
        feature: String,
        action: String,
        expectedResult: String,
        releaseCriterion: ReleaseCriterion,
        failureSeverity: SimulationSeverity = .releaseRisk,
        screenshotName: String? = nil,
        body: () throws -> String
    ) throws {
        let success = runStep(
            day: day,
            feature: feature,
            action: action,
            expectedResult: expectedResult,
            releaseCriterion: releaseCriterion,
            failureSeverity: failureSeverity,
            screenshotName: screenshotName,
            body: body
        )

        if !success {
            throw SimulationFailure(message: "Day \(day) failed during \(feature): \(action).")
        }
    }

    // MARK: - Inventory Helpers

    func addInventoryItem(_ fixture: InventoryFixture) throws {
        app.tapTab("Inventory")
        app.openInventoryAddForm()

        let nameField = app.textFields["Name"]
        guard nameField.waitForExistence(timeout: 3) else {
            throw SimulationFailure(message: "Inventory add form did not open.")
        }

        app.clearAndTypeText(fixture.name, into: nameField)
        let suggestDetails = app.buttons["Suggest Details"]
        if suggestDetails.waitForExistence(timeout: 2) {
            suggestDetails.tap()
        }

        app.clearAndTypeText(fixture.unit, into: app.textFields["Unit (e.g., gallons, boxes)"])
        app.clearAndTypeText(fixture.location, into: app.textFields["Where is this stored?"])
        dismissKeyboardIfPresent()

        if fixture.tracksExpiry {
            let expiryToggle = app.switches["inventory-form-track-expiry-toggle"]
            guard scrollToHittableElement(expiryToggle, maxSwipes: 8) else {
                throw SimulationFailure(message: "Track Expiry Date toggle was not reachable for \(fixture.name).")
            }

            setToggle(expiryToggle, isOn: true)
            let expiryPicker = app.datePickers["inventory-form-expiry-picker"]
            guard expiryPicker.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Expiry controls did not expand after enabling Track Expiry Date for \(fixture.name).")
            }
        }

        if fixture.enablesLowStockReminder {
            let reorderToggle = app.switches["inventory-form-reorder-toggle"]
            guard scrollToHittableElement(reorderToggle, maxSwipes: 8) else {
                throw SimulationFailure(message: "Alert When Low toggle was not reachable for \(fixture.name).")
            }

            setToggle(reorderToggle, isOn: true)
            let thresholdStepper = app.steppers["inventory-form-reorder-stepper"]
            let thresholdSummary = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Threshold:'")).firstMatch
            guard thresholdStepper.waitForExistence(timeout: 3) || thresholdSummary.waitForExistence(timeout: 3) else {
                throw SimulationFailure(message: "Reorder threshold controls did not expand after enabling Alert When Low for \(fixture.name).")
            }
        }

        let notesField = app.textFields["Additional notes"]
        guard scrollToHittableElement(notesField, maxSwipes: 8) else {
            throw SimulationFailure(message: "Additional notes field was not reachable for \(fixture.name).")
        }
        app.clearAndTypeText(fixture.notes, into: notesField)

        app.navigationBars.buttons["Save"].tap()

        guard app.anyElement(containing: fixture.name).waitForExistence(timeout: 5) else {
            throw SimulationFailure(message: "Saved inventory item \(fixture.name) did not appear in the list.")
        }
    }

    // MARK: - Ask Helpers

    func submitAskQuestion(_ question: String) {
        app.tapTab("Ask")
        let input = app.textFields["ask-input-field"]
        let fallbackInput = app.textFields["Ask a question..."]
        let field = input.waitForExistence(timeout: 2) ? input : fallbackInput
        app.clearAndTypeText(question, into: field, placeholder: "Ask a question...")
        app.buttons["ask-submit-button"].tap()
    }

    // MARK: - Quiz Helpers

    func completeVisibleQuiz() throws {
        var safetyCounter = 0

        while safetyCounter < 10 {
            safetyCounter += 1

            if app.buttons["Done"].waitForExistence(timeout: 2) {
                app.buttons["Done"].tap()
                return
            }

            let optionButton = app.buttons.matching(
                NSPredicate(format: "label != 'Close' AND label != 'Next Question' AND label != 'Finish Quiz' AND label != 'Done'")
            ).allElementsBoundByIndex.first(where: { $0.isHittable })

            guard let optionButton else {
                throw SimulationFailure(message: "Quiz did not expose a selectable answer option.")
            }

            optionButton.tap()

            let next = app.buttons["Next Question"]
            let finish = app.buttons["Finish Quiz"]
            if finish.waitForExistence(timeout: 2) {
                finish.tap()
            } else if next.waitForExistence(timeout: 2) {
                next.tap()
            } else {
                throw SimulationFailure(message: "Quiz did not expose a Next Question or Finish Quiz control.")
            }
        }

        throw SimulationFailure(message: "Quiz did not finish within the expected number of questions.")
    }

    // MARK: - Toggle Helpers

    func setToggle(_ toggle: XCUIElement, isOn: Bool) {
        let control = toggleControlElement(for: toggle)

        for _ in 0..<3 {
            let currentValue = toggleValue(for: control)
            let currentlyOn = currentValue.contains("1") || currentValue.contains("on") || currentValue.contains("true")
            if currentlyOn == isOn {
                return
            }

            if control.isHittable {
                control.tap()
            } else {
                control.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }

            let deadline = Date().addingTimeInterval(1)
            while Date() < deadline {
                let updatedValue = toggleValue(for: control)
                let updatedIsOn = updatedValue.contains("1") || updatedValue.contains("on") || updatedValue.contains("true")
                if updatedIsOn == isOn {
                    return
                }
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }
    }

    func toggleControlElement(for toggle: XCUIElement) -> XCUIElement {
        let nestedSwitch = toggle.children(matching: .switch).element(boundBy: 0)
        guard nestedSwitch.exists else {
            return toggle
        }

        let outerFrame = toggle.frame
        let nestedFrame = nestedSwitch.frame
        if nestedFrame != .zero, nestedFrame != outerFrame {
            return nestedSwitch
        }

        return toggle
    }

    func toggleValue(for toggle: XCUIElement) -> String {
        String(describing: toggle.value ?? "").lowercased()
    }

    // MARK: - UI Interaction Helpers

    func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    func scrollToHittableElement(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        guard element.waitForExistence(timeout: 2) else {
            return false
        }

        if element.isHittable {
            return true
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.isHittable {
                return true
            }
        }

        for _ in 0..<maxSwipes {
            app.swipeDown()
            if element.isHittable {
                return true
            }
        }

        return element.isHittable
    }

    func dismissKeyboardIfPresent() {
        guard app.keyboards.firstMatch.waitForExistence(timeout: 1) else {
            return
        }

        let dismissalButtons = ["Return", "return", "Done", "done", "Search", "search", "Go", "go"]
        for label in dismissalButtons {
            let button = app.keyboards.buttons[label]
            if button.exists {
                button.tap()
                return
            }
        }
    }

    var runningOnSimulator: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil
    }
}
