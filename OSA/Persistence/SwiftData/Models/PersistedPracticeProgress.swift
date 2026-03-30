import Foundation
import SwiftData

enum PersistedPracticeProgressKind: String, Codable {
    case quiz
    case weeklyDrill
}

@Model
final class PersistedPracticeProgress {
    @Attribute(.unique) var recordKey: String
    var contentID: UUID
    var kindRawValue: String
    var bestCorrectCount: Int
    var totalQuestionCount: Int
    var lastCompletedAt: Date
    var weekToken: String?

    init(
        recordKey: String,
        contentID: UUID,
        kindRawValue: String,
        bestCorrectCount: Int,
        totalQuestionCount: Int,
        lastCompletedAt: Date,
        weekToken: String?
    ) {
        self.recordKey = recordKey
        self.contentID = contentID
        self.kindRawValue = kindRawValue
        self.bestCorrectCount = bestCorrectCount
        self.totalQuestionCount = totalQuestionCount
        self.lastCompletedAt = lastCompletedAt
        self.weekToken = weekToken
    }
}
