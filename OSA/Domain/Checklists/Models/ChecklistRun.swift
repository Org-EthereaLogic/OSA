import Foundation

enum ChecklistRunStatus: String, Codable, Equatable, Sendable {
    case inProgress = "in-progress"
    case completed
    case abandoned
}

struct ChecklistRunItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let runID: UUID
    let templateItemID: UUID?
    let text: String
    var isComplete: Bool
    var completedAt: Date?
    let sortOrder: Int
}

struct ChecklistRun: Identifiable, Equatable, Sendable {
    let id: UUID
    let templateID: UUID?
    let title: String
    let startedAt: Date
    var completedAt: Date?
    var status: ChecklistRunStatus
    var contextNote: String?
    let items: [ChecklistRunItem]

    var completionFraction: Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter(\.isComplete).count
        return Double(completed) / Double(items.count)
    }
}
