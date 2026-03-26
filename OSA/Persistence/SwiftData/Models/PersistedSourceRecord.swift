import Foundation
import SwiftData

@Model
final class PersistedSourceRecord {
    @Attribute(.unique) var id: UUID
    var sourceTitle: String
    var sourceURL: String
    var publisherDomain: String
    var publisherName: String
    var fetchedAt: Date
    var lastReviewedAt: Date
    var contentHash: String
    var trustLevelRawValue: String
    var tagsJSON: String
    var localChunkIDsJSON: String
    var reviewStatusRawValue: String
    var licenseSummary: String?
    var isActive: Bool
    var staleAfter: Date

    @Relationship(deleteRule: .cascade, inverse: \PersistedImportedKnowledgeDocument.source)
    var documents: [PersistedImportedKnowledgeDocument]

    init(
        id: UUID,
        sourceTitle: String,
        sourceURL: String,
        publisherDomain: String,
        publisherName: String,
        fetchedAt: Date,
        lastReviewedAt: Date,
        contentHash: String,
        trustLevelRawValue: String,
        tagsJSON: String,
        localChunkIDsJSON: String,
        reviewStatusRawValue: String,
        licenseSummary: String?,
        isActive: Bool,
        staleAfter: Date,
        documents: [PersistedImportedKnowledgeDocument] = []
    ) {
        self.id = id
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.publisherDomain = publisherDomain
        self.publisherName = publisherName
        self.fetchedAt = fetchedAt
        self.lastReviewedAt = lastReviewedAt
        self.contentHash = contentHash
        self.trustLevelRawValue = trustLevelRawValue
        self.tagsJSON = tagsJSON
        self.localChunkIDsJSON = localChunkIDsJSON
        self.reviewStatusRawValue = reviewStatusRawValue
        self.licenseSummary = licenseSummary
        self.isActive = isActive
        self.staleAfter = staleAfter
        self.documents = documents
    }
}
