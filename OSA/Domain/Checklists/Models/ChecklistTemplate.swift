import Foundation

enum ChecklistSourceType: String, Codable, Equatable, Sendable {
    case seeded
    case userCreated = "user-created"
}

enum ChecklistPresentationStyle: String, Codable, Equatable, Sendable {
    case standard
    case emergencyProtocol = "emergency-protocol"
}

enum ChecklistTimerProfile: String, Codable, Equatable, Sendable {
    case cprMetronome = "cpr-metronome"
}

struct ChecklistTemplateItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let templateID: UUID
    let text: String
    let detail: String?
    let sortOrder: Int
    let isOptional: Bool
    let riskLevel: String?
}

struct ChecklistTemplateSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let slug: String
    let category: String
    let description: String
    let estimatedMinutes: Int
    let tags: [String]
    let sourceType: ChecklistSourceType
    let presentationStyle: ChecklistPresentationStyle
    let timerProfile: ChecklistTimerProfile?
    let itemCount: Int
}

struct ChecklistTemplate: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let slug: String
    let category: String
    let description: String
    let estimatedMinutes: Int
    let tags: [String]
    let sourceType: ChecklistSourceType
    let presentationStyle: ChecklistPresentationStyle
    let timerProfile: ChecklistTimerProfile?
    let lastReviewedAt: Date?
    let items: [ChecklistTemplateItem]

    var summaryValue: ChecklistTemplateSummary {
        ChecklistTemplateSummary(
            id: id,
            title: title,
            slug: slug,
            category: category,
            description: description,
            estimatedMinutes: estimatedMinutes,
            tags: tags,
            sourceType: sourceType,
            presentationStyle: presentationStyle,
            timerProfile: timerProfile,
            itemCount: items.count
        )
    }
}
