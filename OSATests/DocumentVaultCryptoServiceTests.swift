import Security
import XCTest
@testable import OSA

final class DocumentVaultCryptoServiceTests: XCTestCase {
    func testStoreEncryptsBytesAndDecryptsRoundTrip() throws {
        let directoryURL = makeTemporaryDirectory()
        let service = "DocumentVaultCryptoServiceTests.\(UUID().uuidString)"
        let account = "vault-key"
        defer {
            cleanupKeychain(service: service, account: account)
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let store = EncryptedDocumentVaultStore(
            baseDirectory: directoryURL,
            keyStore: DocumentVaultKeyStore(service: service, account: account)
        )
        let cleartext = Data("passport-scan".utf8)
        let storedFile = try store.storeDocument(data: cleartext, preferredFileExtension: "pdf")
        let encryptedURL = directoryURL
            .appendingPathComponent("DocumentVault", isDirectory: true)
            .appendingPathComponent(storedFile.encryptedFileIdentifier)

        XCTAssertEqual(storedFile.byteCount, cleartext.count)
        XCTAssertTrue(FileManager.default.fileExists(atPath: encryptedURL.path))
        XCTAssertNotEqual(try Data(contentsOf: encryptedURL), cleartext)

        let entry = makeEntry(
            encryptedFileIdentifier: storedFile.encryptedFileIdentifier,
            fileExtension: "pdf",
            byteCount: storedFile.byteCount
        )
        XCTAssertEqual(try store.decryptedData(for: entry), cleartext)
    }

    func testDecryptFailsWithDifferentKeyMaterial() throws {
        let directoryURL = makeTemporaryDirectory()
        let sourceService = "DocumentVaultCryptoServiceTests.source.\(UUID().uuidString)"
        let sourceAccount = "vault-key"
        let otherService = "DocumentVaultCryptoServiceTests.other.\(UUID().uuidString)"
        let otherAccount = "vault-key"
        defer {
            cleanupKeychain(service: sourceService, account: sourceAccount)
            cleanupKeychain(service: otherService, account: otherAccount)
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let writer = EncryptedDocumentVaultStore(
            baseDirectory: directoryURL,
            keyStore: DocumentVaultKeyStore(service: sourceService, account: sourceAccount)
        )
        let reader = EncryptedDocumentVaultStore(
            baseDirectory: directoryURL,
            keyStore: DocumentVaultKeyStore(service: otherService, account: otherAccount)
        )

        let storedFile = try writer.storeDocument(
            data: Data("insurance-card".utf8),
            preferredFileExtension: "jpg"
        )
        let entry = makeEntry(
            encryptedFileIdentifier: storedFile.encryptedFileIdentifier,
            fileExtension: "jpg",
            byteCount: storedFile.byteCount
        )

        XCTAssertThrowsError(try reader.decryptedData(for: entry)) { error in
            XCTAssertEqual(error as? DocumentVaultFileStoreError, .decryptionFailed)
        }
    }

    func testStoreRejectsInvalidFileExtension() throws {
        let directoryURL = makeTemporaryDirectory()
        let service = "DocumentVaultCryptoServiceTests.invalid.\(UUID().uuidString)"
        let account = "vault-key"
        defer {
            cleanupKeychain(service: service, account: account)
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let store = EncryptedDocumentVaultStore(
            baseDirectory: directoryURL,
            keyStore: DocumentVaultKeyStore(service: service, account: account)
        )

        XCTAssertThrowsError(
            try store.storeDocument(data: Data([0x01]), preferredFileExtension: "p?df")
        ) { error in
            XCTAssertEqual(error as? DocumentVaultFileStoreError, .invalidFileExtension)
        }
    }

    private func makeEntry(
        encryptedFileIdentifier: String,
        fileExtension: String,
        byteCount: Int
    ) -> DocumentVaultEntry {
        let now = Date(timeIntervalSince1970: 1_743_206_400)
        return DocumentVaultEntry(
            id: UUID(),
            title: "Document",
            category: .other,
            captureSource: .fileImport,
            encryptedFileIdentifier: encryptedFileIdentifier,
            fileExtension: fileExtension,
            byteCount: byteCount,
            ocrSummary: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    private func makeTemporaryDirectory() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DocumentVaultCryptoServiceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    private func cleanupKeychain(service: String, account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
