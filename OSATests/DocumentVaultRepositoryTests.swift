import SwiftData
import XCTest
@testable import OSA

@MainActor
final class DocumentVaultRepositoryTests: XCTestCase {
    func testCreateUpdateAndDeleteEntryRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataDocumentVaultRepository(modelContext: container.mainContext)
        let createdAt = Date(timeIntervalSince1970: 1_743_206_400)

        var entry = DocumentVaultEntry(
            id: UUID(),
            title: "Passport",
            category: .identity,
            captureSource: .camera,
            encryptedFileIdentifier: "passport.vault",
            fileExtension: "jpg",
            byteCount: 2_048,
            ocrSummary: "Passport\nExpires 2032",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        try repository.createEntry(entry)

        var fetched = try XCTUnwrap(repository.entry(id: entry.id))
        XCTAssertEqual(fetched.title, "Passport")
        XCTAssertEqual(fetched.category, .identity)
        XCTAssertEqual(fetched.ocrSummary, "Passport\nExpires 2032")

        entry.title = "Updated Passport"
        entry.updatedAt = createdAt.addingTimeInterval(60)
        try repository.updateEntry(entry)

        fetched = try XCTUnwrap(repository.entry(id: entry.id))
        XCTAssertEqual(fetched.title, "Updated Passport")
        XCTAssertEqual(fetched.updatedAt, createdAt.addingTimeInterval(60))

        try repository.deleteEntry(id: entry.id)
        XCTAssertNil(try repository.entry(id: entry.id))
    }

    func testListEntriesSortsNewestUpdatedFirst() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataDocumentVaultRepository(modelContext: container.mainContext)
        let earlier = Date(timeIntervalSince1970: 1_743_206_400)
        let later = earlier.addingTimeInterval(300)

        try repository.createEntry(
            DocumentVaultEntry(
                id: UUID(),
                title: "Insurance Card",
                category: .insurance,
                captureSource: .photoLibrary,
                encryptedFileIdentifier: "insurance.vault",
                fileExtension: "jpg",
                byteCount: 1_024,
                ocrSummary: nil,
                createdAt: earlier,
                updatedAt: earlier
            )
        )
        try repository.createEntry(
            DocumentVaultEntry(
                id: UUID(),
                title: "Emergency Contacts",
                category: .emergencyPlan,
                captureSource: .fileImport,
                encryptedFileIdentifier: "contacts.vault",
                fileExtension: "pdf",
                byteCount: 4_096,
                ocrSummary: "Emergency Contacts",
                createdAt: later,
                updatedAt: later
            )
        )

        let entries = try repository.listEntries()
        XCTAssertEqual(entries.map(\.title), ["Emergency Contacts", "Insurance Card"])
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([PersistedDocumentVaultEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
