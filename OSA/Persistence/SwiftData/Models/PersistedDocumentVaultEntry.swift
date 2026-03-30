import Foundation
import SwiftData

@Model
final class PersistedDocumentVaultEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRawValue: String
    var captureSourceRawValue: String
    var encryptedFileIdentifier: String
    var fileExtension: String
    var byteCount: Int
    var ocrSummary: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        title: String,
        categoryRawValue: String,
        captureSourceRawValue: String,
        encryptedFileIdentifier: String,
        fileExtension: String,
        byteCount: Int,
        ocrSummary: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = categoryRawValue
        self.captureSourceRawValue = captureSourceRawValue
        self.encryptedFileIdentifier = encryptedFileIdentifier
        self.fileExtension = fileExtension
        self.byteCount = byteCount
        self.ocrSummary = ocrSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
