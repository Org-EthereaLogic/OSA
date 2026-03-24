import Foundation

enum ChecklistSourceType: String, Codable, Equatable, Sendable {
    case seeded
    case userCreated = "user-created"
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
            itemCount: items.count
        )
    }
}
