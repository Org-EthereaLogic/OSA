import Foundation
import SwiftData

final class SwiftDataImportedKnowledgeRepository: ImportedKnowledgeRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - SourceRecord

    func listSources(trustLevel: TrustLevel?) throws -> [SourceRecord] {
        var descriptor: FetchDescriptor<PersistedSourceRecord>

        if let trustLevel {
            let rawValue = trustLevel.rawValue
            descriptor = FetchDescriptor<PersistedSourceRecord>(
                predicate: #Predicate { $0.trustLevelRawValue == rawValue },
                sortBy: [SortDescriptor(\.sourceTitle)]
            )
        } else {
            descriptor = FetchDescriptor<PersistedSourceRecord>(
                sortBy: [SortDescriptor(\.sourceTitle)]
            )
        }

        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func source(id: UUID) throws -> SourceRecord? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func source(url: String) throws -> SourceRecord? {
        let targetURL = url
        let descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.sourceURL == targetURL }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createSource(_ source: SourceRecord) throws {
        modelContext.insert(PersistedSourceRecord(from: source))
        try modelContext.save()
    }

    func updateSource(_ source: SourceRecord) throws {
        let targetID = source.id
        let descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: source)
        try modelContext.save()
    }

    func deleteSource(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func activeSources() throws -> [SourceRecord] {
        var descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.sourceTitle)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func staleSources(asOf date: Date) throws -> [SourceRecord] {
        let cutoff = date
        var descriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.isActive && $0.staleAfter <= cutoff },
            sortBy: [SortDescriptor(\.staleAfter)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    // MARK: - ImportedKnowledgeDocument

    func listDocuments(sourceID: UUID) throws -> [ImportedKnowledgeDocument] {
        let targetSourceID = sourceID
        var descriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
            predicate: #Predicate { $0.sourceID == targetSourceID },
            sortBy: [SortDescriptor(\.importedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func document(id: UUID) throws -> ImportedKnowledgeDocument? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createDocument(_ document: ImportedKnowledgeDocument) throws {
        let targetSourceID = document.sourceID
        let sourceDescriptor = FetchDescriptor<PersistedSourceRecord>(
            predicate: #Predicate { $0.id == targetSourceID }
        )
        let persistedSource = try modelContext.fetch(sourceDescriptor).first

        modelContext.insert(PersistedImportedKnowledgeDocument(from: document, source: persistedSource))
        try modelContext.save()
    }

    func updateDocument(_ document: ImportedKnowledgeDocument) throws {
        let targetID = document.id
        let descriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        existing.update(from: document)
        try modelContext.save()
    }

    func deleteDocument(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
            predicate: #Predicate { $0.id == targetID }
        )

        guard let existing = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    // MARK: - KnowledgeChunk

    func listChunks(documentID: UUID) throws -> [KnowledgeChunk] {
        let targetDocID = documentID
        var descriptor = FetchDescriptor<PersistedKnowledgeChunk>(
            predicate: #Predicate { $0.documentID == targetDocID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func chunk(id: UUID) throws -> KnowledgeChunk? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedKnowledgeChunk>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func createChunk(_ chunk: KnowledgeChunk) throws {
        let targetDocID = chunk.documentID
        let docDescriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
            predicate: #Predicate { $0.id == targetDocID }
        )
        let persistedDoc = try modelContext.fetch(docDescriptor).first

        modelContext.insert(PersistedKnowledgeChunk(from: chunk, document: persistedDoc))
        try modelContext.save()
    }

    func createChunks(_ chunks: [KnowledgeChunk]) throws {
        for chunk in chunks {
            let targetDocID = chunk.documentID
            let docDescriptor = FetchDescriptor<PersistedImportedKnowledgeDocument>(
                predicate: #Predicate { $0.id == targetDocID }
            )
            let persistedDoc = try modelContext.fetch(docDescriptor).first

            modelContext.insert(PersistedKnowledgeChunk(from: chunk, document: persistedDoc))
        }
        try modelContext.save()
    }

    func deleteChunks(documentID: UUID) throws {
        let targetDocID = documentID
        var descriptor = FetchDescriptor<PersistedKnowledgeChunk>(
            predicate: #Predicate { $0.documentID == targetDocID }
        )
        descriptor.includePendingChanges = true

        let chunks = try modelContext.fetch(descriptor)
        for chunk in chunks {
            modelContext.delete(chunk)
        }
        try modelContext.save()
    }

    func searchableChunks() throws -> [KnowledgeChunk] {
        var descriptor = FetchDescriptor<PersistedKnowledgeChunk>(
            predicate: #Predicate { $0.isSearchable },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }
}
