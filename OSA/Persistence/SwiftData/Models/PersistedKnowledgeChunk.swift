import Foundation
import SwiftData

@Model
final class PersistedKnowledgeChunk {
    @Attribute(.unique) var id: UUID
    var documentID: UUID
    var localChunkID: UUID
    var headingPath: String
    var plainText: String
    var sortOrder: Int
    var tokenEstimate: Int
    var tagsJSON: String
    var trustLevelRawValue: String
    var contentHash: String
    var isSearchable: Bool

    var document: PersistedImportedKnowledgeDocument?

    init(
        id: UUID,
        documentID: UUID,
        localChunkID: UUID,
        headingPath: String,
        plainText: String,
        sortOrder: Int,
        tokenEstimate: Int,
        tagsJSON: String,
        trustLevelRawValue: String,
        contentHash: String,
        isSearchable: Bool,
        document: PersistedImportedKnowledgeDocument?
    ) {
        self.id = id
        self.documentID = documentID
        self.localChunkID = localChunkID
        self.headingPath = headingPath
        self.plainText = plainText
        self.sortOrder = sortOrder
        self.tokenEstimate = tokenEstimate
        self.tagsJSON = tagsJSON
        self.trustLevelRawValue = trustLevelRawValue
        self.contentHash = contentHash
        self.isSearchable = isSearchable
        self.document = document
    }
}
