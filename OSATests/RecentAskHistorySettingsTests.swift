import XCTest
@testable import OSA

final class RecentAskHistorySettingsTests: XCTestCase {
    func testRecordedQuestionsAreNewestFirstWithDeduplication() {
        var rawValue = RecentAskHistorySettings.encode(questions: [])
        rawValue = RecentAskHistorySettings.recorded("How do I purify water?", rawValue: rawValue)
        rawValue = RecentAskHistorySettings.recorded("Where is the shutoff valve?", rawValue: rawValue)
        rawValue = RecentAskHistorySettings.recorded("how do i purify water?", rawValue: rawValue)

        XCTAssertEqual(
            RecentAskHistorySettings.questions(from: rawValue),
            ["how do i purify water?", "Where is the shutoff valve?"]
        )
    }

    func testRecordedQuestionsRespectLimit() {
        var rawValue = RecentAskHistorySettings.encode(questions: [])

        for index in 0..<10 {
            rawValue = RecentAskHistorySettings.recorded(
                "Question \(index)",
                rawValue: rawValue,
                limit: 3
            )
        }

        XCTAssertEqual(
            RecentAskHistorySettings.questions(from: rawValue),
            ["Question 9", "Question 8", "Question 7"]
        )
    }

    func testInvalidRawValueReturnsEmptyQuestions() {
        XCTAssertTrue(RecentAskHistorySettings.questions(from: "not-json").isEmpty)
    }

    func testClearAndPruneReturnBoundedStorage() {
        let rawValue = RecentAskHistorySettings.encode(
            questions: ["One", "Two", "Three", "Four"]
        )

        XCTAssertEqual(
            RecentAskHistorySettings.questions(
                from: RecentAskHistorySettings.prune(rawValue: rawValue, limit: 2)
            ),
            ["One", "Two"]
        )
        XCTAssertTrue(
            RecentAskHistorySettings.questions(
                from: RecentAskHistorySettings.cleared()
            ).isEmpty
        )
    }
}
