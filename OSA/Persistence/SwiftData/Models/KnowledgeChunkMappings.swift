import Foundation

extension PersistedKnowledgeChunk {
    convenience init(from chunk: KnowledgeChunk, document: PersistedImportedKnowledgeDocument?) {
        self.init(
            id: chunk.id,
            documentID: chunk.documentID,
            localChunkID: chunk.localChunkID,
            headingPath: chunk.headingPath,
            plainText: chunk.plainText,
            sortOrder: chunk.sortOrder,
            tokenEstimate: chunk.tokenEstimate,
            tagsJSON: PersistenceValueCoding.encode(chunk.tags),
            trustLevelRawValue: chunk.trustLevel.rawValue,
            contentHash: chunk.contentHash,
            isSearchable: chunk.isSearchable,
            document: document
        )
    }

    func update(from chunk: KnowledgeChunk) {
        documentID = chunk.documentID
        localChunkID = chunk.localChunkID
        headingPath = chunk.headingPath
        plainText = chunk.plainText
        sortOrder = chunk.sortOrder
        tokenEstimate = chunk.tokenEstimate
        tagsJSON = PersistenceValueCoding.encode(chunk.tags)
        trustLevelRawValue = chunk.trustLevel.rawValue
        contentHash = chunk.contentHash
        isSearchable = chunk.isSearchable
    }

    func toDomain() -> KnowledgeChunk {
        KnowledgeChunk(
            id: id,
            documentID: documentID,
            localChunkID: localChunkID,
            headingPath: headingPath,
            plainText: plainText,
            sortOrder: sortOrder,
            tokenEstimate: tokenEstimate,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            trustLevel: TrustLevel(rawValue: trustLevelRawValue) ?? .unverified,
            contentHash: contentHash,
            isSearchable: isSearchable
        )
    }
}
