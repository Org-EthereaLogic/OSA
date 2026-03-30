import SwiftData
import XCTest
@testable import OSA

@MainActor
final class PracticeProgressRepositoryTests: XCTestCase {
    func testQuizProgressPersistsAndRetainsBestScore() throws {
        let container = try makeContainer()
        let repository = SwiftDataPracticeProgressRepository(modelContext: container.mainContext)
        let contentID = UUID()

        let first = try repository.saveQuizProgress(
            for: contentID,
            correctCount: 1,
            totalQuestionCount: 3,
            completedAt: Date(timeIntervalSince1970: 1_742_700_000)
        )
        let improved = try repository.saveQuizProgress(
            for: contentID,
            correctCount: 3,
            totalQuestionCount: 3,
            completedAt: Date(timeIntervalSince1970: 1_742_700_600)
        )
        let laterLower = try repository.saveQuizProgress(
            for: contentID,
            correctCount: 2,
            totalQuestionCount: 3,
            completedAt: Date(timeIntervalSince1970: 1_742_701_200)
        )

        XCTAssertEqual(first.bestCorrectCount, 1)
        XCTAssertEqual(improved.bestCorrectCount, 3)
        XCTAssertEqual(laterLower.bestCorrectCount, 3)

        let stored = try XCTUnwrap(repository.quizProgress(for: contentID))
        XCTAssertEqual(stored.bestCorrectCount, 3)
        XCTAssertEqual(stored.totalQuestionCount, 3)
        XCTAssertEqual(stored.scorePercent, 100)
        XCTAssertEqual(stored.lastCompletedAt, Date(timeIntervalSince1970: 1_742_701_200))

        withExtendedLifetime(container) {}
    }

    func testWeeklyDrillCompletionRoundTripsByWeekToken() throws {
        let container = try makeContainer()
        let repository = SwiftDataPracticeProgressRepository(modelContext: container.mainContext)
        let weekToken = "2026-W13"
        let contentID = UUID()
        let completedAt = Date(timeIntervalSince1970: 1_742_702_000)

        let completion = try repository.markWeeklyDrillCompleted(
            contentID: contentID,
            weekToken: weekToken,
            completedAt: completedAt
        )

        XCTAssertEqual(completion.weekToken, weekToken)
        XCTAssertEqual(completion.contentID, contentID)
        XCTAssertEqual(completion.completedAt, completedAt)

        let stored = try XCTUnwrap(repository.weeklyDrillCompletion(for: weekToken))
        XCTAssertEqual(stored.contentID, contentID)
        XCTAssertEqual(stored.completedAt, completedAt)

        withExtendedLifetime(container) {}
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PersistedPracticeProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
