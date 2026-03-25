import Foundation
import SwiftData

@Model
final class PersistedChecklistTemplateItem {
    @Attribute(.unique) var id: UUID
    var templateID: UUID
    var text: String
    var detail: String?
    var sortOrder: Int
    var isOptional: Bool
    var riskLevel: String?
    var template: PersistedChecklistTemplate?

    init(
        id: UUID,
        templateID: UUID,
        text: String,
        detail: String?,
        sortOrder: Int,
        isOptional: Bool,
        riskLevel: String?,
        template: PersistedChecklistTemplate? = nil
    ) {
        self.id = id
        self.templateID = templateID
        self.text = text
        self.detail = detail
        self.sortOrder = sortOrder
        self.isOptional = isOptional
        self.riskLevel = riskLevel
        self.template = template
    }
}
