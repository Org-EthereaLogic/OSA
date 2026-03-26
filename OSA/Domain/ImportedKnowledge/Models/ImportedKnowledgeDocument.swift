import Foundation

/// A normalized document imported from a trusted source, ready for chunking and retrieval.
struct ImportedKnowledgeDocument: Identifiable, Equatable, Sendable {
    let id: UUID
    var sourceID: UUID
    var title: String
    var normalizedMarkdown: String
    var plainText: String
    var documentType: DocumentType
    var versionHash: String
    var importedAt: Date
    var supersedesDocumentID: UUID?
}
