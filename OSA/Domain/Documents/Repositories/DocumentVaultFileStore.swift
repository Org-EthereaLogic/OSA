import Foundation

struct DocumentVaultStoredFile: Equatable, Sendable {
    let encryptedFileIdentifier: String
    let byteCount: Int
}

protocol DocumentVaultFileStore {
    func storeDocument(
        data: Data,
        preferredFileExtension: String
    ) throws -> DocumentVaultStoredFile

    func decryptedData(for entry: DocumentVaultEntry) throws -> Data
    func deleteDocument(for entry: DocumentVaultEntry) throws
}
