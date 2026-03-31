import Foundation

struct QuizProgress: Identifiable, Equatable, Sendable {
    let contentID: UUID
    let bestCorrectCount: Int
    let totalQuestionCount: Int
    let lastCompletedAt: Date

    var id: UUID { contentID }

    var scorePercent: Int {
        guard totalQuestionCount > 0 else { return 0 }
        return Int((Double(bestCorrectCount) / Double(totalQuestionCount) * 100.0).rounded())
    }

    var isCompleted: Bool {
        totalQuestionCount > 0
    }

    func isMastered(masteryScorePercent: Int) -> Bool {
        scorePercent >= masteryScorePercent
    }
}

struct WeeklyDrillCompletion: Identifiable, Equatable, Sendable {
    let weekToken: String
    let contentID: UUID
    let completedAt: Date

    var id: String { weekToken }
}

enum PracticeBadgeKind: String, Equatable, Sendable {
    case quizCompleted
    case mastery
    case weeklyDrill
}

struct CompletionBadge: Identifiable, Equatable, Sendable {
    let kind: PracticeBadgeKind
    let title: String
    let detail: String

    var id: String { kind.rawValue }

    static func derive(
        quizProgress: QuizProgress?,
        quizDefinition: QuizDefinition?,
        weeklyDrillCompletion: WeeklyDrillCompletion?
    ) -> [CompletionBadge] {
        var badges: [CompletionBadge] = []

        if let progress = quizProgress, progress.isCompleted {
            badges.append(
                CompletionBadge(
                    kind: .quizCompleted,
                    title: "Practiced",
                    detail: "\(progress.bestCorrectCount)/\(progress.totalQuestionCount) correct"
                )
            )
        }

        if let progress = quizProgress,
           let quizDefinition,
           progress.isMastered(masteryScorePercent: quizDefinition.masteryScorePercent) {
            badges.append(
                CompletionBadge(
                    kind: .mastery,
                    title: "Mastered",
                    detail: "\(progress.scorePercent)% best score"
                )
            )
        }

        if let weeklyDrillCompletion {
            badges.append(
                CompletionBadge(
                    kind: .weeklyDrill,
                    title: "Weekly Drill",
                    detail: "Completed \(weeklyDrillCompletion.completedAt.formatted(date: .abbreviated, time: .omitted))"
                )
            )
        }

        return badges
    }
}

enum PracticeSchedule {
    private static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    static func weekToken(for date: Date = AppClock.now()) -> String {
        let calendar = isoCalendar
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }

    static func currentWeeklyDrill(from cards: [QuickCard], date: Date = AppClock.now()) -> QuickCard? {
        let eligibleCards = cards
            .filter { $0.weeklyDrillMetadata != nil }
            .sorted { $0.slug.localizedCaseInsensitiveCompare($1.slug) == .orderedAscending }

        guard !eligibleCards.isEmpty else { return nil }

        let calendar = isoCalendar
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        let index = abs((year * 100) + week) % eligibleCards.count
        return eligibleCards[index]
    }
}
