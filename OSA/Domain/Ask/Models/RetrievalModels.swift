import Foundation

// MARK: - Retrieval Scope

enum RetrievalScope: String, CaseIterable, Equatable, Sendable {
    case handbook
    case quickCards
    case inventory
    case checklists
    case notes
}

// MARK: - Evidence Item

struct EvidenceItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: SearchResultKind
    let title: String
    let snippet: String
    let score: Double
    let sourceLabel: String
    let tags: [String]
}

// MARK: - Citation Reference

struct CitationReference: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: SearchResultKind
    let title: String
    let sourceLabel: String

    var displayLabel: String {
        switch kind {
        case .handbookSection: "Handbook: \(title)"
        case .quickCard: "Quick Card: \(title)"
        case .inventoryItem: "Inventory: \(title)"
        case .checklistTemplate: "Checklist: \(title)"
        case .noteRecord: "Note: \(title)"
        }
    }
}

// MARK: - Answer Mode

enum AnswerMode: Equatable, Sendable {
    case groundedGeneration
    case extractiveOnly
    case searchResultsOnly
}

// MARK: - Confidence Level

enum ConfidenceLevel: Equatable, Sendable {
    case groundedHigh
    case groundedMedium
    case insufficientLocalEvidence
}

// MARK: - Refusal Reason

enum RefusalReason: Equatable, Sendable {
    case emptyQuery
    case blockedSensitiveScope(String)
    case insufficientEvidence
    case outsideProductScope
}

// MARK: - Retrieval Outcome

enum RetrievalOutcome: Equatable, Sendable {
    case answered(AnswerResult)
    case refused(RefusalReason)
}

struct AnswerResult: Equatable, Sendable {
    let query: String
    let evidence: [EvidenceItem]
    let citations: [CitationReference]
    let confidence: ConfidenceLevel
    let answerMode: AnswerMode
    let answerText: String
    let suggestedActions: [SuggestedAction]
}

// MARK: - Suggested Action

enum SuggestedAction: Equatable, Sendable {
    case openQuickCard(id: UUID, title: String)
    case openHandbookSection(id: UUID, title: String)
    case searchOnline(query: String)
}
