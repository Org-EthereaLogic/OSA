import Foundation
import SwiftData

@Model
final class PersistedChecklistRun {
    @Attribute(.unique) var id: UUID
    var templateID: UUID?
    var title: String
    var startedAt: Date
    var completedAt: Date?
    var statusRawValue: String
    var contextNote: String?

    @Relationship(deleteRule: .cascade, inverse: \PersistedChecklistRunItem.run)
    var items: [PersistedChecklistRunItem]

    init(
        id: UUID,
        templateID: UUID?,
        title: String,
        startedAt: Date,
        completedAt: Date?,
        statusRawValue: String,
        contextNote: String?,
        items: [PersistedChecklistRunItem] = []
    ) {
        self.id = id
        self.templateID = templateID
        self.title = title
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.statusRawValue = statusRawValue
        self.contextNote = contextNote
        self.items = items
    }
}
