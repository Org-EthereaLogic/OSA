import Foundation

protocol PracticeProgressRepository {
    func quizProgress(for contentID: UUID) throws -> QuizProgress?
    func listQuizProgress() throws -> [QuizProgress]
    @discardableResult
    func saveQuizProgress(
        for contentID: UUID,
        correctCount: Int,
        totalQuestionCount: Int,
        completedAt: Date
    ) throws -> QuizProgress

    func weeklyDrillCompletion(for weekToken: String) throws -> WeeklyDrillCompletion?
    func listWeeklyDrillCompletions() throws -> [WeeklyDrillCompletion]
    @discardableResult
    func markWeeklyDrillCompleted(
        contentID: UUID,
        weekToken: String,
        completedAt: Date
    ) throws -> WeeklyDrillCompletion
}
