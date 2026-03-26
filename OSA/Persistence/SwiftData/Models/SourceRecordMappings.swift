import Foundation

extension PersistedSourceRecord {
    convenience init(from source: SourceRecord) {
        self.init(
            id: source.id,
            sourceTitle: source.sourceTitle,
            sourceURL: source.sourceURL,
            publisherDomain: source.publisherDomain,
            publisherName: source.publisherName,
            fetchedAt: source.fetchedAt,
            lastReviewedAt: source.lastReviewedAt,
            contentHash: source.contentHash,
            trustLevelRawValue: source.trustLevel.rawValue,
            tagsJSON: PersistenceValueCoding.encode(source.tags),
            localChunkIDsJSON: PersistenceValueCoding.encode(source.localChunkIDs),
            reviewStatusRawValue: source.reviewStatus.rawValue,
            licenseSummary: source.licenseSummary,
            isActive: source.isActive,
            staleAfter: source.staleAfter
        )
    }

    func update(from source: SourceRecord) {
        sourceTitle = source.sourceTitle
        sourceURL = source.sourceURL
        publisherDomain = source.publisherDomain
        publisherName = source.publisherName
        fetchedAt = source.fetchedAt
        lastReviewedAt = source.lastReviewedAt
        contentHash = source.contentHash
        trustLevelRawValue = source.trustLevel.rawValue
        tagsJSON = PersistenceValueCoding.encode(source.tags)
        localChunkIDsJSON = PersistenceValueCoding.encode(source.localChunkIDs)
        reviewStatusRawValue = source.reviewStatus.rawValue
        licenseSummary = source.licenseSummary
        isActive = source.isActive
        staleAfter = source.staleAfter
    }

    func toDomain() -> SourceRecord {
        SourceRecord(
            id: id,
            sourceTitle: sourceTitle,
            sourceURL: sourceURL,
            publisherDomain: publisherDomain,
            publisherName: publisherName,
            fetchedAt: fetchedAt,
            lastReviewedAt: lastReviewedAt,
            contentHash: contentHash,
            trustLevel: TrustLevel(rawValue: trustLevelRawValue) ?? .unverified,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            localChunkIDs: PersistenceValueCoding.decodeUUIDs(from: localChunkIDsJSON),
            reviewStatus: ReviewStatus(rawValue: reviewStatusRawValue) ?? .pending,
            licenseSummary: licenseSummary,
            isActive: isActive,
            staleAfter: staleAfter
        )
    }
}
