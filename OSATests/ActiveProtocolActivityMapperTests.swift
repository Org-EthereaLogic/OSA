import XCTest
@testable import OSA

final class ActiveProtocolActivityMapperTests: XCTestCase {
    func testSelectsMostRecentEligibleEmergencyProtocolRun() throws {
        let olderRun = checklistRun(
            title: "Older Protocol",
            startedAt: fixedDate(year: 2026, month: 3, day: 29, hour: 8),
            itemTexts: ["Check exits", "Shut off utilities"],
            completedIndices: [0]
        )
        let newestEligibleRun = checklistRun(
            title: "Newest Protocol",
            startedAt: fixedDate(year: 2026, month: 3, day: 29, hour: 10),
            itemTexts: ["Grab radio", "Move to safe room"],
            completedIndices: []
        )
        let ignoredStandardRun = checklistRun(
            title: "Standard Run",
            startedAt: fixedDate(year: 2026, month: 3, day: 29, hour: 11),
            itemTexts: ["Normal step"],
            completedIndices: []
        )
        let templates = [
            olderRun.templateID!: checklistTemplate(id: olderRun.templateID!, style: .emergencyProtocol),
            newestEligibleRun.templateID!: checklistTemplate(id: newestEligibleRun.templateID!, style: .emergencyProtocol),
            ignoredStandardRun.templateID!: checklistTemplate(id: ignoredStandardRun.templateID!, style: .standard)
        ]

        let payload = try ActiveProtocolActivityMapper().makePayload(
            from: [olderRun, newestEligibleRun, ignoredStandardRun]
        ) { templateID in
            templates[templateID]
        }

        XCTAssertEqual(payload?.runID, newestEligibleRun.id)
        XCTAssertEqual(payload?.title, "Newest Protocol")
        XCTAssertEqual(payload?.completedStepCount, 0)
        XCTAssertEqual(payload?.totalStepCount, 2)
        XCTAssertEqual(payload?.completionPercent, 0)
        XCTAssertEqual(payload?.nextStepLabel, "Grab radio")
    }

    func testReturnsNilWhenNoEligibleActiveRunsExist() throws {
        let completedRun = checklistRun(
            title: "Completed",
            status: .completed,
            itemTexts: ["Done"],
            completedIndices: [0]
        )
        let standardRun = checklistRun(
            title: "Standard",
            itemTexts: ["Do this"],
            completedIndices: []
        )
        let templates = [
            completedRun.templateID!: checklistTemplate(id: completedRun.templateID!, style: .emergencyProtocol),
            standardRun.templateID!: checklistTemplate(id: standardRun.templateID!, style: .standard)
        ]

        let payload = try ActiveProtocolActivityMapper().makePayload(
            from: [completedRun, standardRun]
        ) { templateID in
            templates[templateID]
        }

        XCTAssertNil(payload)
    }

    func testBoundsNextStepLabelAndDerivesProgressFromChecklistRun() throws {
        let mapper = ActiveProtocolActivityMapper(stepLabelLimit: 12)
        let run = checklistRun(
            title: "Protocol",
            itemTexts: [
                "Completed step",
                "Move everyone to the safest interior room now",
                "Bring radio"
            ],
            completedIndices: [0]
        )
        let template = checklistTemplate(id: run.templateID!, style: .emergencyProtocol)

        let payload = try mapper.makePayload(from: [run]) { templateID in
            templateID == template.id ? template : nil
        }

        XCTAssertEqual(payload?.completedStepCount, 1)
        XCTAssertEqual(payload?.totalStepCount, 3)
        XCTAssertEqual(payload?.completionPercent, 33)
        XCTAssertEqual(payload?.nextStepLabel, "Move everyon...")
        XCTAssertEqual(payload?.attributes.protocolTitle, "Protocol")
        XCTAssertEqual(payload?.contentState.totalStepCount, 3)
    }
}

private extension ActiveProtocolActivityMapperTests {
    func checklistTemplate(
        id: UUID,
        style: ChecklistPresentationStyle
    ) -> ChecklistTemplate {
        ChecklistTemplate(
            id: id,
            title: "Template",
            slug: "template",
            category: "emergency",
            description: "Protocol",
            estimatedMinutes: 5,
            tags: [],
            sourceType: .seeded,
            presentationStyle: style,
            timerProfile: nil,
            lastReviewedAt: nil,
            items: []
        )
    }

    func checklistRun(
        title: String,
        startedAt: Date = Date(timeIntervalSince1970: 0),
        status: ChecklistRunStatus = .inProgress,
        itemTexts: [String],
        completedIndices: Set<Int>
    ) -> ChecklistRun {
        let runID = UUID()
        let templateID = UUID()

        return ChecklistRun(
            id: runID,
            templateID: templateID,
            title: title,
            startedAt: startedAt,
            completedAt: status == .completed ? startedAt.addingTimeInterval(300) : nil,
            status: status,
            contextNote: "This should never leave the app.",
            items: itemTexts.enumerated().map { index, text in
                ChecklistRunItem(
                    id: UUID(),
                    runID: runID,
                    templateItemID: UUID(),
                    text: text,
                    isComplete: completedIndices.contains(index),
                    completedAt: completedIndices.contains(index) ? startedAt.addingTimeInterval(Double(index)) : nil,
                    sortOrder: index
                )
            }
        )
    }

    func fixedDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        )
        return components.date!
    }
}
