import CryptoKit
import SwiftData
import XCTest
@testable import OSA

/// Validates seed content version tracking: first import, skip-on-same-version,
/// update-on-new-version, and isolation from user-authored data.
@MainActor
final class SeedContentMigrationTests: XCTestCase {

    // MARK: - Version Tracking

    func testFirstImportOnEmptyStoreReturnsImportedStatus() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        let outcome = try env.importer.importBundledContentIfNeeded()

        XCTAssertEqual(outcome.status, .imported)
        XCTAssertEqual(outcome.chapterCount, 1)
        XCTAssertEqual(outcome.sectionCount, 1)
        XCTAssertEqual(outcome.quickCardCount, 1)
        XCTAssertEqual(outcome.checklistTemplateCount, 1)
    }

    func testSameManifestVersionOnSecondImportReturnsSkipped() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        _ = try env.importer.importBundledContentIfNeeded()
        let secondOutcome = try env.importer.importBundledContentIfNeeded()

        XCTAssertEqual(secondOutcome.status, .skippedAlreadyCurrent)
    }

    func testUpdatedManifestVersionReturnsUpdatedStatus() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        _ = try env.importer.importBundledContentIfNeeded()

        // Write an updated fixture set with a bumped content pack version.
        env.fixtures.cleanup()
        let updatedFixtures = try M5SeedFixtures(contentPackVersion: "0.2.0")
        defer { updatedFixtures.cleanup() }
        let updatedLoader = SeedContentLoader(directoryURL: updatedFixtures.directoryURL)
        let updatedImporter = SeedContentImporter(
            loader: updatedLoader,
            repository: env.repository,
            now: { Self.laterDate }
        )

        let updatedOutcome = try updatedImporter.importBundledContentIfNeeded()

        XCTAssertEqual(updatedOutcome.status, .updated)
        XCTAssertEqual(updatedOutcome.versionState.contentPackVersion, "0.2.0")
    }

    func testSeedStateRecordsCorrectVersionFields() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        _ = try env.importer.importBundledContentIfNeeded()

        let state = try XCTUnwrap(env.repository.currentSeedVersionState())
        XCTAssertEqual(state.schemaVersion, 1)
        XCTAssertEqual(state.contentPackVersion, "0.1.0")
        XCTAssertEqual(state.appliedAt, Self.baseDate)
    }

    // MARK: - User Data Isolation

    func testUserAuthoredInventoryDataNotAffectedBySeedImport() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        // Insert a user-authored inventory item before seed import.
        let now = Date()
        let userItem = PersistedInventoryItem(
            id: UUID(),
            name: "Personal Flashlight",
            categoryRawValue: InventoryCategory.lighting.rawValue,
            quantity: 3,
            unit: "units",
            location: "Bedside table",
            notes: "User-owned",
            expiryDate: nil,
            reorderThreshold: nil,
            tagsJSON: "[]",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        env.container.mainContext.insert(userItem)
        try env.container.mainContext.save()

        // Perform seed import.
        _ = try env.importer.importBundledContentIfNeeded()

        // User-authored inventory must remain untouched.
        let inventoryDescriptor = FetchDescriptor<PersistedInventoryItem>()
        let items = try env.container.mainContext.fetch(inventoryDescriptor)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Personal Flashlight")
        XCTAssertEqual(items.first?.notes, "User-owned")
    }

    func testUserAuthoredNotesNotAffectedBySeedImport() throws {
        let env = try makeTestEnvironment()
        defer { env.fixtures.cleanup() }

        // Insert a user-authored note before seed import.
        let now = Date()
        let userNote = PersistedNoteRecord(
            id: UUID(),
            title: "My Emergency Plan",
            bodyMarkdown: "Personal evac route.",
            plainText: "Personal evac route.",
            noteTypeRawValue: NoteType.personal.rawValue,
            tagsJSON: "[]",
            linkedSectionIDsJSON: "[]",
            linkedInventoryItemIDsJSON: "[]",
            createdAt: now,
            updatedAt: now
        )
        env.container.mainContext.insert(userNote)
        try env.container.mainContext.save()

        // Perform seed import.
        _ = try env.importer.importBundledContentIfNeeded()

        // User-authored note must remain untouched.
        let noteDescriptor = FetchDescriptor<PersistedNoteRecord>()
        let notes = try env.container.mainContext.fetch(noteDescriptor)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "My Emergency Plan")
        XCTAssertEqual(notes.first?.plainText, "Personal evac route.")
    }

    // MARK: - Test Environment

    private static let baseDate = Date(timeIntervalSince1970: 1_742_601_600)
    private static let laterDate = Date(timeIntervalSince1970: 1_742_688_000)

    private func makeTestEnvironment() throws -> (
        container: ModelContainer,
        repository: SwiftDataContentRepository,
        fixtures: M5SeedFixtures,
        importer: SeedContentImporter
    ) {
        let fixtures = try M5SeedFixtures(contentPackVersion: "0.1.0")
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedSeedContentState.self,
            PersistedInventoryItem.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self,
            PersistedChecklistRun.self,
            PersistedChecklistRunItem.self,
            PersistedNoteRecord.self,
            PersistedSourceRecord.self,
            PersistedImportedKnowledgeDocument.self,
            PersistedKnowledgeChunk.self,
            PersistedPendingOperation.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repository = SwiftDataContentRepository(modelContext: container.mainContext)
        let importer = SeedContentImporter(
            loader: SeedContentLoader(directoryURL: fixtures.directoryURL),
            repository: repository,
            now: { Self.baseDate }
        )
        return (container, repository, fixtures, importer)
    }
}

// MARK: - M5 Seed Fixtures

/// Minimal seed content fixture set for M5 migration tests.
/// Creates one chapter with one section, one quick card, and one checklist template
/// in a temp directory, with matching manifest and content hashes.
private struct M5SeedFixtures {
    let directoryURL: URL
    private let contentPackVersion: String

    init(contentPackVersion: String) throws {
        self.contentPackVersion = contentPackVersion
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("M5SeedFixtures-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        try write("handbook-m5-v1.json", contents: Self.handbookPack)
        try write("quick-cards-m5-v1.json", contents: Self.quickCardPack)
        try write("checklist-templates-m5-v1.json", contents: Self.checklistTemplatePack)
        try writeManifest(contentPackVersion: contentPackVersion)
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func write(_ fileName: String, contents: String) throws {
        try contents.write(
            to: directoryURL.appendingPathComponent(fileName),
            atomically: true,
            encoding: .utf8
        )
    }

    private func writeManifest(contentPackVersion: String) throws {
        let handbookHash = Self.sha256Hex(Self.handbookPack)
        let quickCardHash = Self.sha256Hex(Self.quickCardPack)
        let checklistHash = Self.sha256Hex(Self.checklistTemplatePack)

        let manifest = """
        {
          "schemaVersion": 1,
          "contentPackVersion": "\(contentPackVersion)",
          "generatedAt": "2026-03-22T00:00:00Z",
          "packs": [
            {
              "identifier": "handbook-m5",
              "kind": "handbook-chapters",
              "version": "2026.03.22.1",
              "fileName": "handbook-m5-v1.json",
              "recordCount": 1,
              "contentHash": "\(handbookHash)"
            },
            {
              "identifier": "quick-cards-m5",
              "kind": "quick-cards",
              "version": "2026.03.22.1",
              "fileName": "quick-cards-m5-v1.json",
              "recordCount": 1,
              "contentHash": "\(quickCardHash)"
            },
            {
              "identifier": "checklist-templates-m5",
              "kind": "checklist-templates",
              "version": "2026.03.22.1",
              "fileName": "checklist-templates-m5-v1.json",
              "recordCount": 1,
              "contentHash": "\(checklistHash)"
            }
          ]
        }
        """
        try write("SeedManifest.json", contents: manifest)
    }

    static func sha256Hex(_ contents: String) -> String {
        SHA256.hash(data: Data(contents.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // Section ID referenced by the quick card must exist in the handbook pack.
    private static let sectionID = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    private static let chapterID = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    private static let templateID = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    private static let templateItemID = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"

    static let handbookPack = """
    {
      "chapters": [
        {
          "id": "\(chapterID)",
          "slug": "m5-test-chapter",
          "title": "M5 Test Chapter",
          "summary": "Chapter for M5 migration tests.",
          "sortOrder": 100,
          "tags": ["m5", "test"],
          "version": 1,
          "isSeeded": true,
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "sections": [
            {
              "id": "\(sectionID)",
              "chapterID": "\(chapterID)",
              "parentSectionID": null,
              "heading": "M5 Test Section",
              "bodyMarkdown": "Content for M5 migration test.",
              "plainText": "Content for M5 migration test.",
              "sortOrder": 100,
              "tags": ["m5"],
              "safetyLevel": "normal",
              "chunkGroupID": "m5-test-section-chunk",
              "version": 1,
              "lastReviewedAt": "2026-03-22T00:00:00Z"
            }
          ]
        }
      ]
    }
    """

    static let quickCardPack = """
    {
      "quickCards": [
        {
          "id": "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE",
          "title": "M5 Quick Card",
          "slug": "m5-quick-card",
          "category": "test",
          "summary": "Quick card for M5 migration tests.",
          "bodyMarkdown": "1. Verify migration behavior.",
          "priority": 50,
          "relatedSectionIDs": ["\(sectionID)"],
          "tags": ["m5"],
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "largeTypeLayoutVersion": 1
        }
      ]
    }
    """

    static let checklistTemplatePack = """
    {
      "templates": [
        {
          "id": "\(templateID)",
          "title": "M5 Checklist",
          "slug": "m5-checklist",
          "category": "test",
          "description": "Checklist for M5 migration tests.",
          "estimatedMinutes": 5,
          "tags": ["m5"],
          "sourceType": "seeded",
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "items": [
            {
              "id": "\(templateItemID)",
              "text": "Verify seed import",
              "detail": null,
              "sortOrder": 100,
              "isOptional": false,
              "riskLevel": null
            }
          ]
        }
      ]
    }
    """
}
