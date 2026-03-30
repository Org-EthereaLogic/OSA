import CryptoKit
import Foundation

enum DocumentVaultFileStoreError: LocalizedError, Equatable {
    case invalidFileExtension
    case encryptionFailed
    case missingFile(String)
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .invalidFileExtension:
            "That document format is not supported for the vault."
        case .encryptionFailed:
            "The document could not be encrypted for local storage."
        case .missingFile(let identifier):
            "The encrypted document \(identifier) is missing from local storage."
        case .decryptionFailed:
            "The document could not be decrypted on this device."
        }
    }
}

final class EncryptedDocumentVaultStore: DocumentVaultFileStore, @unchecked Sendable {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let keyStore: DocumentVaultKeyStore

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil,
        keyStore: DocumentVaultKeyStore = DocumentVaultKeyStore()
    ) {
        self.fileManager = fileManager
        self.keyStore = keyStore

        let appSupport = baseDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("OSA", isDirectory: true)
        self.directoryURL = appSupport.appendingPathComponent("DocumentVault", isDirectory: true)

        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func storeDocument(
        data: Data,
        preferredFileExtension: String
    ) throws -> DocumentVaultStoredFile {
        let fileExtension = preferredFileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !fileExtension.isEmpty,
              fileExtension.range(of: #"^[a-z0-9]+$"#, options: .regularExpression) != nil
        else {
            throw DocumentVaultFileStoreError.invalidFileExtension
        }

        let key = try keyStore.loadOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encryptedData = sealedBox.combined else {
            throw DocumentVaultFileStoreError.encryptionFailed
        }

        let identifier = "\(UUID().uuidString).vault"
        let fileURL = directoryURL.appendingPathComponent(identifier, isDirectory: false)

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try encryptedData.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: fileURL.path
        )

        return DocumentVaultStoredFile(
            encryptedFileIdentifier: identifier,
            byteCount: data.count
        )
    }

    func decryptedData(for entry: DocumentVaultEntry) throws -> Data {
        let fileURL = url(for: entry.encryptedFileIdentifier)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw DocumentVaultFileStoreError.missingFile(entry.encryptedFileIdentifier)
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let key = try keyStore.loadOrCreateKey()

        guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
            throw DocumentVaultFileStoreError.decryptionFailed
        }

        return decryptedData
    }

    func deleteDocument(for entry: DocumentVaultEntry) throws {
        let fileURL = url(for: entry.encryptedFileIdentifier)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private func url(for identifier: String) -> URL {
        directoryURL.appendingPathComponent(identifier, isDirectory: false)
    }
}
