import Foundation

extension PersistedDocumentVaultEntry {
    convenience init(from entry: DocumentVaultEntry) {
        self.init(
            id: entry.id,
            title: entry.title,
            categoryRawValue: entry.category.rawValue,
            captureSourceRawValue: entry.captureSource.rawValue,
            encryptedFileIdentifier: entry.encryptedFileIdentifier,
            fileExtension: entry.fileExtension,
            byteCount: entry.byteCount,
            ocrSummary: entry.ocrSummary,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt
        )
    }

    func update(from entry: DocumentVaultEntry) {
        title = entry.title
        categoryRawValue = entry.category.rawValue
        captureSourceRawValue = entry.captureSource.rawValue
        encryptedFileIdentifier = entry.encryptedFileIdentifier
        fileExtension = entry.fileExtension
        byteCount = entry.byteCount
        ocrSummary = entry.ocrSummary
        updatedAt = entry.updatedAt
    }

    func toDomain() -> DocumentVaultEntry {
        DocumentVaultEntry(
            id: id,
            title: title,
            category: DocumentVaultCategory(rawValue: categoryRawValue) ?? .other,
            captureSource: DocumentCaptureSource(rawValue: captureSourceRawValue) ?? .fileImport,
            encryptedFileIdentifier: encryptedFileIdentifier,
            fileExtension: fileExtension,
            byteCount: byteCount,
            ocrSummary: ocrSummary,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
