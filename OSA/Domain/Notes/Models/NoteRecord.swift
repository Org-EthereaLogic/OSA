import Foundation

enum NoteType: String, Codable, CaseIterable, Equatable, Sendable {
    case personal
    case localReference = "local-reference"
    case familyPlan = "family-plan"
}

struct NoteRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var bodyMarkdown: String
    var plainText: String
    var noteType: NoteType
    var tags: [String]
    var linkedSectionIDs: [UUID]
    var linkedInventoryItemIDs: [UUID]
    let createdAt: Date
    var updatedAt: Date
}
