import Foundation

enum FieldReferenceCategory: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case firstAid = "first-aid"
    case weatherExposure = "weather-exposure"
    case waterTreatment = "water-treatment"
    case signaling = "signaling"
    case lookalikeComparison = "lookalike-comparison"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstAid: "First Aid"
        case .weatherExposure: "Weather Exposure"
        case .waterTreatment: "Water Treatment"
        case .signaling: "Signaling"
        case .lookalikeComparison: "Lookalike Checks"
        }
    }

    var systemImage: String {
        switch self {
        case .firstAid: "cross.case.fill"
        case .weatherExposure: "cloud.sun.fill"
        case .waterTreatment: "drop.fill"
        case .signaling: "flashlight.on.fill"
        case .lookalikeComparison: "square.on.square"
        }
    }

    var summary: String {
        switch self {
        case .firstAid:
            "Reviewed, static injury-response references that stay concise and non-diagnostic."
        case .weatherExposure:
            "Cold, heat, smoke, and exposure references tuned for household response."
        case .waterTreatment:
            "Storage, treatment, and contamination references for safer household water use."
        case .signaling:
            "Low-friction visual and radio signaling references for offline conditions."
        case .lookalikeComparison:
            "Conservative comparison notes for items that are easy to confuse under stress."
        }
    }
}

struct FieldReferenceSection: Identifiable, Codable, Equatable, Sendable {
    let title: String
    let bodyMarkdown: String
    let plainText: String
    let sortOrder: Int

    var id: String { "\(sortOrder)-\(title)" }
}

struct FieldReferenceEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let slug: String
    let title: String
    let category: FieldReferenceCategory
    let summary: String
    let sortOrder: Int
    let sections: [FieldReferenceSection]
    let relatedSectionIDs: [UUID]
    let tags: [String]
    let safetyLevel: HandbookSafetyLevel
    let lastReviewedAt: Date?

    var sortedSections: [FieldReferenceSection] {
        sections.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    var plainText: String {
        ([summary] + sortedSections.map { "\($0.title) \($0.plainText)" })
            .joined(separator: " ")
    }
}
