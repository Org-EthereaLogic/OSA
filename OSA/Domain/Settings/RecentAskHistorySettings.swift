import Foundation

enum RecentAskHistorySettings {
    static let recentQuestionsKey = "settings.ask.recentQuestions"
    static let maxRecentQuestions = 8

    static func questions(from rawValue: String) -> [String] {
        SettingsValueCoding.decodeStrings(from: rawValue)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func encode(questions: [String]) -> String {
        SettingsValueCoding.encode(questions)
    }

    static func recorded(
        _ question: String,
        rawValue: String,
        limit: Int = maxRecentQuestions
    ) -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return prune(rawValue: rawValue, limit: limit) }

        var values = questions(from: rawValue)
        values.removeAll { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
        values.insert(trimmed, at: 0)
        return encode(questions: Array(values.prefix(limit)))
    }

    static func cleared() -> String {
        encode(questions: [])
    }

    static func prune(rawValue: String, limit: Int = maxRecentQuestions) -> String {
        encode(questions: Array(questions(from: rawValue).prefix(limit)))
    }
}
