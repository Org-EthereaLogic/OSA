import Foundation
import SwiftData

@Model
final class PersistedImportedKnowledgeDocument {
    @Attribute(.unique) var id: UUID
    var sourceID: UUID
    var title: String
    var normalizedMarkdown: String
    var plainText: String
    var documentTypeRawValue: String
    var versionHash: String
    var importedAt: Date
    var supersedesDocumentID: UUID?

    var source: PersistedSourceRecord?

    @Relationship(deleteRule: .cascade, inverse: \PersistedKnowledgeChunk.document)
    var chunks: [PersistedKnowledgeChunk]

    init(
        id: UUID,
        sourceID: UUID,
        title: String,
        normalizedMarkdown: String,
        plainText: String,
        documentTypeRawValue: String,
        versionHash: String,
        importedAt: Date,
        supersedesDocumentID: UUID?,
        source: PersistedSourceRecord?,
        chunks: [PersistedKnowledgeChunk] = []
    ) {
        self.id = id
        self.sourceID = sourceID
        self.title = title
        self.normalizedMarkdown = normalizedMarkdown
        self.plainText = plainText
        self.documentTypeRawValue = documentTypeRawValue
        self.versionHash = versionHash
        self.importedAt = importedAt
        self.supersedesDocumentID = supersedesDocumentID
        self.source = source
        self.chunks = chunks
    }
}
