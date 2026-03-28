import Foundation

enum SearchResultKind: String, Equatable, Sendable, CaseIterable {
    case handbookSection
    case quickCard
    case inventoryItem
    case checklistTemplate
    case noteRecord
    case importedKnowledge
}

struct SearchResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: SearchResultKind
    let title: String
    let snippet: String
    let score: Double
    let tags: [String]
}

enum SearchSuggestionSource: String, Equatable, Sendable {
    case recent
    case title
    case tag
}

struct SearchSuggestion: Identifiable, Equatable, Sendable {
    let text: String
    let source: SearchSuggestionSource

    var id: String { "\(source.rawValue):\(text)" }
}
