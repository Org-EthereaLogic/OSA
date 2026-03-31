import Foundation
import XCTest

enum SimulationSeverity: String, Codable {
    case info
    case releaseRisk
    case releaseBlocker
    case unverified
}

enum ReleaseCriterion: String, Codable {
    case persistenceAcrossRelaunch
    case groundingAndCitations
    case askScopeBoundaries
    case discoveryImportCommit
    case privacyIsolation
    case accessibilityAndOrientation
    case deviceCapability
    case offlineRecovery
    case featureBaseline
}

struct SimulationStep: Codable {
    let id: UUID
    let day: Int
    let feature: String
    let action: String
    let expectedResult: String
    let actualResult: String
    let durationMilliseconds: Int
    let severity: SimulationSeverity
    let releaseCriterion: ReleaseCriterion
    let attachmentPath: String?
}

struct SimulationEvent: Codable {
    let timestamp: Date
    let day: Int?
    let message: String
    let severity: SimulationSeverity
}

private struct SimulationTimeline: Codable {
    let runID: String
    let scenarioID: String
    let executedAt: Date
    let steps: [SimulationStep]
    let events: [SimulationEvent]
}

enum WeekSimulationConnectivity: String {
    case offline
    case onlineUsable
}

enum WeekSimulationLaunchArgument {
    static let scenarioID = "UI-TEST-SCENARIO-ID"
    static let resetState = "UI-TEST-RESET-STATE"
    static let now = "UI-TEST-NOW"
    static let connectivity = "UI-TEST-CONNECTIVITY"
    static let fixtureMode = "UI-TEST-FIXTURE-MODE"
}

enum WeekSimulationPersona {
    static let scenarioID = "week-in-life-preparedness-planner"
    static let emergencyContactName = "Jordan Lee"
    static let familyPlanTitle = "Family Emergency Plan"
    static let familyMeetupPhrase = "Family meetup: Lincoln High School parking lot."
    static let familyMeetupQuestion = "Where is our family meetup point?"
    static let studyGuideQuery = "How much water should I store?"
    static let studyGuideTitle = "Study Guide: How much water should I store?"
    static let preImportSearchTerm = "damaged seals"
    static let importedKnowledgeQuestion = "What should I replace if a water container has a damaged seal?"
    static let importedKnowledgeTitle = "Water Storage and Rotation Basics"
    static let notFoundQuestion = "What is the city bus schedule during an outage?"
    static let outOfScopeQuestion = "Who won the baseball game yesterday?"
    static let firstChecklistItem = "Water: 1 gallon per person per day for 3 days"
    static let secondChecklistItem = "Food: 3-day supply of non-perishable items"
    static let checklistTitle = "72-Hour Emergency Kit Check"
    static let knowledgePackTitle = "Water Readiness"

    static let inventoryItems: [InventoryFixture] = [
        InventoryFixture(
            name: "Water Brick",
            unit: "gallons",
            location: "Garage shelf",
            notes: "Rotate before summer.",
            tracksExpiry: true,
            enablesLowStockReminder: true
        ),
        InventoryFixture(
            name: "Trail Mix Bin",
            unit: "packs",
            location: "Hall closet",
            notes: "Weekend evacuation snacks.",
            tracksExpiry: false,
            enablesLowStockReminder: false
        ),
        InventoryFixture(
            name: "AA Battery Tote",
            unit: "batteries",
            location: "Office cabinet",
            notes: "Headlamp and radio spares.",
            tracksExpiry: false,
            enablesLowStockReminder: false
        ),
        InventoryFixture(
            name: "First Aid Pouch",
            unit: "kits",
            location: "Entry closet",
            notes: "Check gloves and burn gel.",
            tracksExpiry: false,
            enablesLowStockReminder: false
        )
    ]

    static let dayDates: [Date] = [
        makeDate("2026-03-30T08:00:00.000-07:00"),
        makeDate("2026-03-31T08:00:00.000-07:00"),
        makeDate("2026-04-01T08:00:00.000-07:00"),
        makeDate("2026-04-02T08:00:00.000-07:00"),
        makeDate("2026-04-03T08:00:00.000-07:00"),
        makeDate("2026-04-04T08:00:00.000-07:00"),
        makeDate("2026-04-05T08:00:00.000-07:00"),
        makeDate("2026-04-06T08:00:00.000-07:00"),
        makeDate("2026-04-07T08:00:00.000-07:00"),
        makeDate("2026-04-08T08:00:00.000-07:00"),
        makeDate("2026-04-09T08:00:00.000-07:00"),
        makeDate("2026-04-10T08:00:00.000-07:00"),
        makeDate("2026-04-11T08:00:00.000-07:00"),
        makeDate("2026-04-12T08:00:00.000-07:00")
    ]

    // MARK: - Week 2 Persona Data

    static let week2InventoryItems: [InventoryFixture] = [
        InventoryFixture(
            name: "Emergency Radio",
            unit: "units",
            location: "Hall closet",
            notes: "NOAA weather band receiver. Check batteries monthly.",
            tracksExpiry: false,
            enablesLowStockReminder: false
        ),
        InventoryFixture(
            name: "Canned Soup Rotation",
            unit: "cans",
            location: "Pantry lower shelf",
            notes: "Rotate before summer, FIFO order.",
            tracksExpiry: true,
            enablesLowStockReminder: true
        )
    ]

    static let personalNoteTitle = "Power Outage Lessons Learned"
    static let personalNoteBody = "Last outage lasted 6 hours. Generator ran fine but need extension cord for fridge."
    static let localReferenceNoteTitle = "Neighborhood Water Source"
    static let localReferenceNoteBody = "Community well at Maple Park. Needs boil-water treatment."

    static let shelterWaypointTitle = "Lincoln Elementary Shelter"
    static let shelterWaypointNote = "Red Cross designated shelter during regional events."
    static let waterWaypointTitle = "Maple Park Community Well"
    static let waterWaypointNote = "Municipal backup water source. Requires treatment."

    static let week2AskQuery = "How should I prepare for a wildfire evacuation?"
    static let week2StudyGuideTitle = "Study Guide: How should I prepare for a wildfire evacuation?"
    static let kitBuildingQuestion = "What should I pack in a 72-hour emergency kit?"

    static let week2ChecklistSlug = "home-power-outage-preparation"
    static let week2ChecklistTitle = "Home Power Outage Preparation"

    private static func makeDate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: value) else {
            fatalError("Invalid week simulation date: \(value)")
        }
        return date
    }
}

struct InventoryFixture {
    let name: String
    let unit: String
    let location: String
    let notes: String
    let tracksExpiry: Bool
    let enablesLowStockReminder: Bool
}

struct SimulationFailure: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

@MainActor
final class WeekSimulationReporter {
    let runID: String
    let artifactRoot: URL

    private(set) var steps: [SimulationStep] = []
    private(set) var events: [SimulationEvent] = []
    private let screenshotsDirectory: URL

    init(runID: String = WeekSimulationReporter.defaultRunID()) {
        self.runID = runID

        artifactRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("OSAWeekSimulationReporter", isDirectory: true)
            .appendingPathComponent(runID, isDirectory: true)

        screenshotsDirectory = artifactRoot.appendingPathComponent("screenshots", isDirectory: true)

        try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
    }

    func recordEvent(
        day: Int? = nil,
        message: String,
        severity: SimulationSeverity = .info
    ) {
        events.append(
            SimulationEvent(
                timestamp: Date(),
                day: day,
                message: message,
                severity: severity
            )
        )
    }

    @discardableResult
    func recordStep(
        day: Int,
        feature: String,
        action: String,
        expectedResult: String,
        success: Bool,
        actualResult: String,
        releaseCriterion: ReleaseCriterion,
        failureSeverity: SimulationSeverity = .releaseRisk,
        screenshotName: String? = nil,
        app: XCUIApplication? = nil,
        testCase: XCTestCase? = nil,
        durationMilliseconds: Int
    ) -> Bool {
        let attachmentPath: String?
        if let screenshotName, let app, let testCase {
            attachmentPath = captureScreenshot(named: screenshotName, app: app, testCase: testCase)
        } else {
            attachmentPath = nil
        }

        steps.append(
            SimulationStep(
                id: UUID(),
                day: day,
                feature: feature,
                action: action,
                expectedResult: expectedResult,
                actualResult: actualResult,
                durationMilliseconds: durationMilliseconds,
                severity: success ? .info : failureSeverity,
                releaseCriterion: releaseCriterion,
                attachmentPath: attachmentPath
            )
        )

        return success
    }

    func recordUnverifiedStep(
        day: Int,
        feature: String,
        action: String,
        expectedResult: String,
        actualResult: String,
        releaseCriterion: ReleaseCriterion
    ) {
        steps.append(
            SimulationStep(
                id: UUID(),
                day: day,
                feature: feature,
                action: action,
                expectedResult: expectedResult,
                actualResult: actualResult,
                durationMilliseconds: 0,
                severity: .unverified,
                releaseCriterion: releaseCriterion,
                attachmentPath: nil
            )
        )
    }

    func writeArtifacts() {
        try? FileManager.default.createDirectory(at: artifactRoot, withIntermediateDirectories: true)

        let timeline = SimulationTimeline(
            runID: runID,
            scenarioID: WeekSimulationPersona.scenarioID,
            executedAt: Date(),
            steps: steps,
            events: events
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(timeline) {
            try? data.write(to: artifactRoot.appendingPathComponent("timeline.json"))
        }

        let summary = markdownSummary()
        try? summary.data(using: .utf8)?.write(to: artifactRoot.appendingPathComponent("summary.md"))
    }

    private func captureScreenshot(
        named rawName: String,
        app: XCUIApplication,
        testCase: XCTestCase
    ) -> String? {
        let safeName = Self.slug(from: rawName)
        let fileName = "\(safeName).png"
        let fileURL = screenshotsDirectory.appendingPathComponent(fileName)
        let screenshot = app.screenshot()
        try? screenshot.pngRepresentation.write(to: fileURL)

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = rawName
        attachment.lifetime = .keepAlways
        testCase.add(attachment)

        return "screenshots/\(fileName)"
    }

    private func markdownSummary() -> String {
        let blockers = steps.filter { $0.severity == .releaseBlocker }
        let risks = steps.filter { $0.severity == .releaseRisk }
        let unverified = steps.filter { $0.severity == .unverified }
        let maxDay = steps.map(\.day).max() ?? 0
        let summaryTitle = maxDay > 7 ? "Two-Week Simulation Summary" : "Week Simulation Summary"

        var lines: [String] = [
            "# \(summaryTitle)",
            "",
            "- Run ID: `\(runID)`",
            "- Scenario: `\(WeekSimulationPersona.scenarioID)`",
            "- Steps: \(steps.count)",
            "- Release blockers: \(blockers.count)",
            "- Release risks: \(risks.count)",
            "- Unverified: \(unverified.count)",
            ""
        ]

        if !events.isEmpty {
            lines.append("## Events")
            lines.append("")
            for event in events {
                let dayPrefix = event.day.map { "Day \($0)" } ?? "Run"
                lines.append("- [\(event.severity.rawValue)] \(dayPrefix): \(event.message)")
            }
            lines.append("")
        }

        lines.append("## Steps")
        lines.append("")
        for step in steps {
            lines.append("- Day \(step.day) [\(step.severity.rawValue)] \(step.feature): \(step.action)")
            lines.append("  Expected: \(step.expectedResult)")
            lines.append("  Actual: \(step.actualResult)")
            if let attachmentPath = step.attachmentPath {
                lines.append("  Attachment: `\(attachmentPath)`")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func defaultRunID() -> String {
        if let explicitRunID = ProcessInfo.processInfo.environment["OSA_WEEK_SIM_RUN_ID"],
           !explicitRunID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return explicitRunID
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func slug(from rawValue: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = rawValue.lowercased().unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

@MainActor
extension XCTestCase {
    func launchWeekSimulationApp(
        dayIndex: Int,
        connectivity: WeekSimulationConnectivity,
        resetState: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "UI-TESTING",
            "\(WeekSimulationLaunchArgument.scenarioID)=\(WeekSimulationPersona.scenarioID)",
            "\(WeekSimulationLaunchArgument.now)=\(formattedWeekSimulationDate(WeekSimulationPersona.dayDates[dayIndex]))",
            "\(WeekSimulationLaunchArgument.connectivity)=\(connectivity.rawValue)"
        ]

        if resetState {
            app.launchArguments.append("\(WeekSimulationLaunchArgument.resetState)=1")
        }

        #if targetEnvironment(simulator)
        app.launchArguments.append("\(WeekSimulationLaunchArgument.fixtureMode)=week-sim")
        #endif

        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
        return app
    }

    func formattedWeekSimulationDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    func stepDurationMilliseconds(_ start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000.0)
    }
}

@MainActor
extension XCUIApplication {
    func clearAndTypeText(
        _ text: String,
        into element: XCUIElement,
        placeholder: String? = nil
    ) {
        guard element.waitForExistence(timeout: 3) else { return }
        element.tap()

        if let currentValue = element.value as? String,
           !currentValue.isEmpty,
           currentValue != placeholder {
            let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteSequence)
        }

        element.typeText(text)
    }

    func appendText(_ text: String, into element: XCUIElement) {
        guard element.waitForExistence(timeout: 3) else { return }
        element.tap()
        element.typeText(text)
    }

    @discardableResult
    func waitForAny(
        _ elements: [XCUIElement],
        timeout: TimeInterval = 8
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for element in elements where element.exists {
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        return nil
    }

    func waitForRootUI(timeout: TimeInterval = 10) -> Bool {
        tabBars.firstMatch.waitForExistence(timeout: timeout)
    }

    func dismissShareSheetIfNeeded() {
        let cancelButton = buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            return
        }

        let closeButton = buttons["Close"]
        if closeButton.waitForExistence(timeout: 2) {
            closeButton.tap()
            return
        }

        let doneButton = buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
            return
        }

        swipeDown()
    }

    func returnToMoreRoot() {
        tapTab("More")

        for _ in 0..<6 {
            if staticTexts["Settings"].exists || buttons["Settings"].exists {
                return
            }

            let backButton = navigationBars.buttons.firstMatch
            if backButton.waitForExistence(timeout: 1.5) {
                backButton.tap()
            } else {
                break
            }
        }
    }

    func clearSearchField(_ field: XCUIElement) {
        guard field.waitForExistence(timeout: 2) else { return }
        if let currentValue = field.value as? String, !currentValue.isEmpty {
            field.tap()
            let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            field.typeText(deleteSequence)
        }
    }

    func openInventoryAddForm() {
        tapTab("Inventory")
        let addButton = buttons["Add inventory item"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            return
        }

        findButton(labelContaining: "Add")?.tap()
    }

    func staticText(containing text: String) -> XCUIElement {
        staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func button(containing text: String) -> XCUIElement {
        buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func anyElement(containing text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
}
