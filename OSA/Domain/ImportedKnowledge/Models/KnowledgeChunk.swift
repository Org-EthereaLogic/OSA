import Foundation

/// A retrieval-ready text chunk derived from an imported knowledge document.
struct KnowledgeChunk: Identifiable, Equatable, Sendable {
    let id: UUID
    var documentID: UUID
    var localChunkID: UUID
    var headingPath: String
    var plainText: String
    var sortOrder: Int
    var tokenEstimate: Int
    var tags: [String]
    var trustLevel: TrustLevel
    var contentHash: String
    var isSearchable: Bool
}
