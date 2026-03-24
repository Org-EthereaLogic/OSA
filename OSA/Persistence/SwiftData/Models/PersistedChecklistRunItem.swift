import Foundation
import SwiftData

@Model
final class PersistedChecklistRunItem {
    @Attribute(.unique) var id: UUID
    var runID: UUID
    var templateItemID: UUID?
    var text: String
    var isComplete: Bool
    var completedAt: Date?
    var sortOrder: Int

    var run: PersistedChecklistRun?

    init(
        id: UUID,
        runID: UUID,
        templateItemID: UUID?,
        text: String,
        isComplete: Bool,
        completedAt: Date?,
        sortOrder: Int,
        run: PersistedChecklistRun? = nil
    ) {
        self.id = id
        self.runID = runID
        self.templateItemID = templateItemID
        self.text = text
        self.isComplete = isComplete
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.run = run
    }
}
