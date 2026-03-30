import Foundation
import SwiftData

final class SwiftDataPracticeProgressRepository: PracticeProgressRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func quizProgress(for contentID: UUID) throws -> QuizProgress? {
        let key = quizKey(for: contentID)
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.recordKey == key }
        )
        return try modelContext.fetch(descriptor).first.map(Self.makeQuizProgress)
    }

    func listQuizProgress() throws -> [QuizProgress] {
        let kind = PersistedPracticeProgressKind.quiz.rawValue
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.kindRawValue == kind },
            sortBy: [SortDescriptor(\.lastCompletedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.makeQuizProgress)
    }

    @discardableResult
    func saveQuizProgress(
        for contentID: UUID,
        correctCount: Int,
        totalQuestionCount: Int,
        completedAt: Date
    ) throws -> QuizProgress {
        let key = quizKey(for: contentID)
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.recordKey == key }
        )

        let existing = try modelContext.fetch(descriptor).first
        let record = existing ?? PersistedPracticeProgress(
            recordKey: key,
            contentID: contentID,
            kindRawValue: PersistedPracticeProgressKind.quiz.rawValue,
            bestCorrectCount: correctCount,
            totalQuestionCount: totalQuestionCount,
            lastCompletedAt: completedAt,
            weekToken: nil
        )

        let incomingPercent = scorePercent(correctCount: correctCount, totalQuestionCount: totalQuestionCount)
        let existingPercent = scorePercent(
            correctCount: record.bestCorrectCount,
            totalQuestionCount: record.totalQuestionCount
        )

        if existing == nil {
            modelContext.insert(record)
        }

        if incomingPercent >= existingPercent {
            record.bestCorrectCount = correctCount
            record.totalQuestionCount = totalQuestionCount
        }
        record.lastCompletedAt = completedAt

        try modelContext.save()
        return Self.makeQuizProgress(record)
    }

    func weeklyDrillCompletion(for weekToken: String) throws -> WeeklyDrillCompletion? {
        let key = weeklyDrillKey(for: weekToken)
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.recordKey == key }
        )
        return try modelContext.fetch(descriptor).first.flatMap(Self.makeWeeklyDrillCompletion)
    }

    func listWeeklyDrillCompletions() throws -> [WeeklyDrillCompletion] {
        let kind = PersistedPracticeProgressKind.weeklyDrill.rawValue
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.kindRawValue == kind },
            sortBy: [SortDescriptor(\.lastCompletedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap(Self.makeWeeklyDrillCompletion)
    }

    @discardableResult
    func markWeeklyDrillCompleted(
        contentID: UUID,
        weekToken: String,
        completedAt: Date
    ) throws -> WeeklyDrillCompletion {
        let key = weeklyDrillKey(for: weekToken)
        let descriptor = FetchDescriptor<PersistedPracticeProgress>(
            predicate: #Predicate { $0.recordKey == key }
        )

        let existing = try modelContext.fetch(descriptor).first
        let record = existing ?? PersistedPracticeProgress(
            recordKey: key,
            contentID: contentID,
            kindRawValue: PersistedPracticeProgressKind.weeklyDrill.rawValue,
            bestCorrectCount: 0,
            totalQuestionCount: 0,
            lastCompletedAt: completedAt,
            weekToken: weekToken
        )

        if existing == nil {
            modelContext.insert(record)
        }

        record.contentID = contentID
        record.lastCompletedAt = completedAt
        record.weekToken = weekToken

        try modelContext.save()
        return Self.makeWeeklyDrillCompletion(record) ?? WeeklyDrillCompletion(
            weekToken: weekToken,
            contentID: contentID,
            completedAt: completedAt
        )
    }

    private func scorePercent(correctCount: Int, totalQuestionCount: Int) -> Int {
        guard totalQuestionCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestionCount) * 100.0).rounded())
    }

    private func quizKey(for contentID: UUID) -> String {
        "quiz:\(contentID.uuidString.lowercased())"
    }

    private func weeklyDrillKey(for weekToken: String) -> String {
        "weekly:\(weekToken)"
    }

    private static func makeQuizProgress(_ record: PersistedPracticeProgress) -> QuizProgress {
        QuizProgress(
            contentID: record.contentID,
            bestCorrectCount: record.bestCorrectCount,
            totalQuestionCount: record.totalQuestionCount,
            lastCompletedAt: record.lastCompletedAt
        )
    }

    private static func makeWeeklyDrillCompletion(_ record: PersistedPracticeProgress) -> WeeklyDrillCompletion? {
        guard let weekToken = record.weekToken else { return nil }
        return WeeklyDrillCompletion(
            weekToken: weekToken,
            contentID: record.contentID,
            completedAt: record.lastCompletedAt
        )
    }
}
