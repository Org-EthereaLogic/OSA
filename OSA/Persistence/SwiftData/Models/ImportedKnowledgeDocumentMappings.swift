import Foundation

extension PersistedImportedKnowledgeDocument {
    convenience init(from document: ImportedKnowledgeDocument, source: PersistedSourceRecord?) {
        self.init(
            id: document.id,
            sourceID: document.sourceID,
            title: document.title,
            normalizedMarkdown: document.normalizedMarkdown,
            plainText: document.plainText,
            documentTypeRawValue: document.documentType.rawValue,
            versionHash: document.versionHash,
            importedAt: document.importedAt,
            supersedesDocumentID: document.supersedesDocumentID,
            source: source
        )
    }

    func update(from document: ImportedKnowledgeDocument) {
        sourceID = document.sourceID
        title = document.title
        normalizedMarkdown = document.normalizedMarkdown
        plainText = document.plainText
        documentTypeRawValue = document.documentType.rawValue
        versionHash = document.versionHash
        importedAt = document.importedAt
        supersedesDocumentID = document.supersedesDocumentID
    }

    func toDomain() -> ImportedKnowledgeDocument {
        ImportedKnowledgeDocument(
            id: id,
            sourceID: sourceID,
            title: title,
            normalizedMarkdown: normalizedMarkdown,
            plainText: plainText,
            documentType: DocumentType(rawValue: documentTypeRawValue) ?? .article,
            versionHash: versionHash,
            importedAt: importedAt,
            supersedesDocumentID: supersedesDocumentID
        )
    }
}
