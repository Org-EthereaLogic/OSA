import Foundation

/// Repository contract for managing imported knowledge sources, documents, and chunks.
protocol ImportedKnowledgeRepository {
    // MARK: - SourceRecord

    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord]
    func source(id: UUID) throws -> SourceRecord?
    func source(url: String) throws -> SourceRecord?
    func createSource(_ source: SourceRecord) throws
    func updateSource(_ source: SourceRecord) throws
    func deleteSource(id: UUID) throws
    func activeSources() throws -> [SourceRecord]
    func staleSources(asOf date: Date) throws -> [SourceRecord]

    // MARK: - ImportedKnowledgeDocument

    func listDocuments(sourceID: UUID) throws -> [ImportedKnowledgeDocument]
    func document(id: UUID) throws -> ImportedKnowledgeDocument?
    func createDocument(_ document: ImportedKnowledgeDocument) throws
    func updateDocument(_ document: ImportedKnowledgeDocument) throws
    func deleteDocument(id: UUID) throws

    // MARK: - KnowledgeChunk

    func listChunks(documentID: UUID) throws -> [KnowledgeChunk]
    func chunk(id: UUID) throws -> KnowledgeChunk?
    func createChunk(_ chunk: KnowledgeChunk) throws
    func createChunks(_ chunks: [KnowledgeChunk]) throws
    func deleteChunks(documentID: UUID) throws
    func searchableChunks() throws -> [KnowledgeChunk]
}
