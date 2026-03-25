import Foundation

enum AskScopeSettings {
    static let includePersonalNotesKey = "settings.ask.includePersonalNotes"
    static let includePersonalNotesDefault = false

    static func retrievalScopes(includePersonalNotes: Bool) -> Set<RetrievalScope> {
        var scopes: Set<RetrievalScope> = [
            .handbook,
            .quickCards,
            .inventory,
            .checklists
        ]

        if includePersonalNotes {
            scopes.insert(.notes)
        }

        return scopes
    }
}
