import Foundation

/// Errors raised during the import pipeline.
enum ImportPipelineError: Error, Equatable {
    case normalizationFailed(String)
    case emptyChunks
    case persistenceFailed(String)
}

/// Orchestrates the M4P4 import workflow:
/// normalize → chunk → persist → index.
///
/// Does not import SwiftData directly. All persistence is through
/// `ImportedKnowledgeRepository` and `SearchService` protocols.
final class ImportedKnowledgeImportPipeline: @unchecked Sendable {

    /// Default stale-after interval for MVP (30 days).
    static let defaultStaleAfterInterval: TimeInterval = 30 * 24 * 60 * 60

    private let repository: any ImportedKnowledgeRepository
    private let searchService: (any SearchService)?

    init(
        repository: any ImportedKnowledgeRepository,
        searchService: (any SearchService)?
    ) {
        self.repository = repository
        self.searchService = searchService
    }

    /// Imports a fetched response into local persistence and indexes approved content.
    ///
    /// - Returns: The persisted `SourceRecord` for the imported source.
    @discardableResult
    func importFetchedContent(_ response: TrustedSourceFetchResponse) throws -> SourceRecord {
        // 1. Normalize
        let normalized: NormalizedDocument
        do {
            normalized = try ImportedKnowledgeNormalizer.normalize(response)
        } catch {
            throw ImportPipelineError.normalizationFailed(error.localizedDescription)
        }

        // 2. Resolve trust metadata from the final URL
        let allowlistEntry = TrustedSourceAllowlist.entry(for: response.finalURL)
        let trustLevel = allowlistEntry?.trustLevel ?? .unverified
        let reviewStatus = allowlistEntry?.defaultReviewStatus ?? .pending
        let publisherName = allowlistEntry?.publisherName ?? (response.finalURL.host ?? "Unknown")
        let isApproved = reviewStatus == .approved

        // 3. Check for existing source by URL (dedupe)
        let sourceURL = normalized.sourceURL
        let existingSource = try repository.source(url: sourceURL)

        if let existing = existingSource {
            // Same content hash → metadata refresh only
            if existing.contentHash == normalized.contentHash {
                var refreshed = existing
                refreshed.fetchedAt = response.fetchedAt
                refreshed.staleAfter = response.fetchedAt.addingTimeInterval(Self.defaultStaleAfterInterval)
                try repository.updateSource(refreshed)
                return refreshed
            }

            // Content changed → create new document version
            return try importNewVersion(
                normalized: normalized,
                response: response,
                existingSource: existing,
                trustLevel: trustLevel,
                reviewStatus: reviewStatus,
                publisherName: publisherName,
                isApproved: isApproved
            )
        }

        // 4. First import — create everything
        return try importNewSource(
            normalized: normalized,
            response: response,
            trustLevel: trustLevel,
            reviewStatus: reviewStatus,
            publisherName: publisherName,
            isApproved: isApproved
        )
    }

    // MARK: - New Source Import

    private func importNewSource(
        normalized: NormalizedDocument,
        response: TrustedSourceFetchResponse,
        trustLevel: TrustLevel,
        reviewStatus: ReviewStatus,
        publisherName: String,
        isApproved: Bool
    ) throws -> SourceRecord {
        let documentID = UUID()
        let sourceID = UUID()

        // Chunk
        let tags = buildTags(
            publisherDomain: normalized.publisherDomain,
            documentType: normalized.documentType,
            title: normalized.title
        )
        let chunks = KnowledgeChunker.chunk(
            normalized,
            documentID: documentID,
            trustLevel: trustLevel,
            isSearchable: isApproved,
            tags: tags
        )
        guard !chunks.isEmpty else {
            throw ImportPipelineError.emptyChunks
        }

        // Create source
        let source = SourceRecord(
            id: sourceID,
            sourceTitle: normalized.title,
            sourceURL: normalized.sourceURL,
            publisherDomain: normalized.publisherDomain,
            publisherName: publisherName,
            fetchedAt: response.fetchedAt,
            lastReviewedAt: response.fetchedAt,
            contentHash: normalized.contentHash,
            trustLevel: trustLevel,
            tags: tags,
            localChunkIDs: chunks.map(\.localChunkID),
            reviewStatus: reviewStatus,
            licenseSummary: nil,
            isActive: true,
            staleAfter: response.fetchedAt.addingTimeInterval(Self.defaultStaleAfterInterval)
        )
        try repository.createSource(source)

        // Create document
        let document = ImportedKnowledgeDocument(
            id: documentID,
            sourceID: sourceID,
            title: normalized.title,
            normalizedMarkdown: normalized.normalizedMarkdown,
            plainText: normalized.plainText,
            documentType: normalized.documentType,
            versionHash: normalized.contentHash,
            importedAt: response.fetchedAt,
            supersedesDocumentID: nil
        )
        try repository.createDocument(document)

        // Create chunks
        try repository.createChunks(chunks)

        // Index only approved searchable chunks
        if isApproved {
            indexChunks(chunks, sourceTitle: normalized.title, publisherDomain: normalized.publisherDomain)
        }

        return source
    }

    // MARK: - Version Update Import

    private func importNewVersion(
        normalized: NormalizedDocument,
        response: TrustedSourceFetchResponse,
        existingSource: SourceRecord,
        trustLevel: TrustLevel,
        reviewStatus: ReviewStatus,
        publisherName: String,
        isApproved: Bool
    ) throws -> SourceRecord {
        let documentID = UUID()

        // Find previous document to supersede
        let previousDocs = try repository.listDocuments(sourceID: existingSource.id)
        let latestPreviousDoc = previousDocs.sorted(by: { $0.importedAt < $1.importedAt }).last

        // Remove old index entries for previous chunks
        if let prevDoc = latestPreviousDoc {
            let oldChunks = try repository.listChunks(documentID: prevDoc.id)
            for chunk in oldChunks {
                try? searchService?.removeFromIndex(id: chunk.id)
            }
        }

        // Chunk new content
        let tags = buildTags(
            publisherDomain: normalized.publisherDomain,
            documentType: normalized.documentType,
            title: normalized.title
        )
        let chunks = KnowledgeChunker.chunk(
            normalized,
            documentID: documentID,
            trustLevel: trustLevel,
            isSearchable: isApproved,
            tags: tags
        )
        guard !chunks.isEmpty else {
            throw ImportPipelineError.emptyChunks
        }

        // Update source
        var updatedSource = existingSource
        updatedSource.sourceTitle = normalized.title
        updatedSource.publisherName = publisherName
        updatedSource.fetchedAt = response.fetchedAt
        updatedSource.lastReviewedAt = response.fetchedAt
        updatedSource.contentHash = normalized.contentHash
        updatedSource.trustLevel = trustLevel
        updatedSource.reviewStatus = reviewStatus
        updatedSource.tags = tags
        updatedSource.localChunkIDs = chunks.map(\.localChunkID)
        updatedSource.staleAfter = response.fetchedAt.addingTimeInterval(Self.defaultStaleAfterInterval)
        try repository.updateSource(updatedSource)

        // Create new document
        let document = ImportedKnowledgeDocument(
            id: documentID,
            sourceID: existingSource.id,
            title: normalized.title,
            normalizedMarkdown: normalized.normalizedMarkdown,
            plainText: normalized.plainText,
            documentType: normalized.documentType,
            versionHash: normalized.contentHash,
            importedAt: response.fetchedAt,
            supersedesDocumentID: latestPreviousDoc?.id
        )
        try repository.createDocument(document)

        // Create chunks
        try repository.createChunks(chunks)

        // Index only approved searchable chunks
        if isApproved {
            indexChunks(chunks, sourceTitle: normalized.title, publisherDomain: normalized.publisherDomain)
        }

        return updatedSource
    }

    // MARK: - Indexing

    private func indexChunks(_ chunks: [KnowledgeChunk], sourceTitle: String, publisherDomain: String) {
        guard let searchService else { return }
        for chunk in chunks where chunk.isSearchable {
            try? searchService.indexImportedChunk(chunk, sourceTitle: sourceTitle, publisherDomain: publisherDomain)
        }
    }

    // MARK: - Tag Generation

    private func buildTags(publisherDomain: String, documentType: DocumentType, title: String) -> [String] {
        var tags = [publisherDomain, documentType.rawValue]
        // Add a few normalized title keywords
        let titleWords = title.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 3 }
            .prefix(5)
        tags.append(contentsOf: titleWords)
        return tags
    }
}
