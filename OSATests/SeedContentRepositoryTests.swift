import SwiftData
import XCTest
@testable import OSA

final class SeedContentRepositoryTests: XCTestCase {
    func testSeedContentLoaderDecodesManifestAndPackFiles() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        let bundle = try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()

        XCTAssertEqual(bundle.manifest.schemaVersion, 1)
        XCTAssertEqual(bundle.manifest.contentPackVersion, "0.1.0")
        XCTAssertEqual(bundle.manifest.packs.count, 2)
        XCTAssertEqual(bundle.chapters.count, 1)
        XCTAssertEqual(bundle.chapters.first?.slug, "preparedness-foundations")
        XCTAssertEqual(bundle.chapters.first?.sections.map(\.heading), [
            "Start With The Risks You Actually Face",
            "Build Layers Instead Of Single-Point Fixes"
        ])
        XCTAssertEqual(bundle.quickCards.map(\.slug), [
            "first-hour-power-outage-check",
            "water-rotation-check"
        ])
    }

    func testFirstRunSeedImportPersistsContentAndSupportsOrderedReads() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        let container = try makeInMemoryContainer()
        let repository = SwiftDataContentRepository(modelContext: container.mainContext)
        let importer = SeedContentImporter(
            loader: SeedContentLoader(directoryURL: fixtures.directoryURL),
            repository: repository,
            now: { Self.appliedAt }
        )

        let outcome = try importer.importBundledContentIfNeeded()

        XCTAssertEqual(outcome.status, .imported)
        XCTAssertEqual(outcome.chapterCount, 1)
        XCTAssertEqual(outcome.sectionCount, 2)
        XCTAssertEqual(outcome.quickCardCount, 2)

        let chapters = try repository.listChapters()
        XCTAssertEqual(chapters.map(\.slug), ["preparedness-foundations"])

        let chapter = try XCTUnwrap(repository.chapter(slug: "preparedness-foundations"))
        XCTAssertEqual(chapter.sections.map(\.heading), [
            "Start With The Risks You Actually Face",
            "Build Layers Instead Of Single-Point Fixes"
        ])

        let quickCards = try repository.listQuickCards()
        XCTAssertEqual(quickCards.map(\.slug), [
            "first-hour-power-outage-check",
            "water-rotation-check"
        ])
        XCTAssertEqual(quickCards.first?.priority, 100)

        let quickCard = try XCTUnwrap(repository.quickCard(slug: "water-rotation-check"))
        XCTAssertEqual(quickCard.relatedSectionIDs, [
            UUID(uuidString: "11111111-1111-1111-1111-111111111112")!
        ])

        let versionState = try XCTUnwrap(repository.currentSeedVersionState())
        XCTAssertEqual(versionState.schemaVersion, 1)
        XCTAssertEqual(versionState.contentPackVersion, "0.1.0")
        XCTAssertEqual(versionState.appliedAt, Self.appliedAt)
    }

    func testRepeatSeedImportSkipsWhenBundleVersionIsAlreadyCurrent() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        let container = try makeInMemoryContainer()
        let repository = SwiftDataContentRepository(modelContext: container.mainContext)
        let importer = SeedContentImporter(
            loader: SeedContentLoader(directoryURL: fixtures.directoryURL),
            repository: repository,
            now: { Self.appliedAt }
        )

        _ = try importer.importBundledContentIfNeeded()

        let secondOutcome = try SeedContentImporter(
            loader: SeedContentLoader(directoryURL: fixtures.directoryURL),
            repository: repository,
            now: { Self.laterAppliedAt }
        ).importBundledContentIfNeeded()

        XCTAssertEqual(secondOutcome.status, .skippedAlreadyCurrent)
        XCTAssertEqual(try repository.listChapters().count, 1)
        XCTAssertEqual(try repository.listQuickCards().count, 2)
        XCTAssertEqual(try repository.chapter(slug: "preparedness-foundations")?.sections.count, 2)

        let versionState = try XCTUnwrap(repository.currentSeedVersionState())
        XCTAssertEqual(versionState.appliedAt, Self.appliedAt)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedSeedContentState.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static let appliedAt = Date(timeIntervalSince1970: 1_742_601_600)
    private static let laterAppliedAt = Date(timeIntervalSince1970: 1_742_688_000)
}

private struct SeedContentFixtures {
    let directoryURL: URL

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        try write("SeedManifest.json", contents: Self.manifest)
        try write("handbook-foundations-v1.json", contents: Self.handbookPack)
        try write("quick-cards-core-v1.json", contents: Self.quickCardPack)
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

    private static let manifest = """
    {
      "schemaVersion": 1,
      "contentPackVersion": "0.1.0",
      "generatedAt": "2026-03-22T00:00:00Z",
      "packs": [
        {
          "identifier": "handbook-foundations",
          "kind": "handbook-chapters",
          "version": "2026.03.22.1",
          "fileName": "handbook-foundations-v1.json",
          "recordCount": 1,
          "contentHash": null
        },
        {
          "identifier": "quick-cards-core",
          "kind": "quick-cards",
          "version": "2026.03.22.1",
          "fileName": "quick-cards-core-v1.json",
          "recordCount": 2,
          "contentHash": null
        }
      ]
    }
    """

    private static let handbookPack = """
    {
      "chapters": [
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "slug": "preparedness-foundations",
          "title": "Preparedness Foundations",
          "summary": "Core household readiness principles that stay usable offline and under stress.",
          "sortOrder": 100,
          "tags": ["foundations", "planning", "offline-first"],
          "version": 1,
          "isSeeded": true,
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "sections": [
            {
              "id": "11111111-1111-1111-1111-111111111112",
              "chapterID": "11111111-1111-1111-1111-111111111111",
              "parentSectionID": null,
              "heading": "Start With The Risks You Actually Face",
              "bodyMarkdown": "Preparedness works better when you plan against likely local problems first.",
              "plainText": "Preparedness works better when you plan against likely local problems first.",
              "sortOrder": 100,
              "tags": ["risk-assessment", "priorities", "planning"],
              "safetyLevel": "normal",
              "chunkGroupID": "preparedness-foundations-risk-baseline",
              "version": 1,
              "lastReviewedAt": "2026-03-22T00:00:00Z"
            },
            {
              "id": "11111111-1111-1111-1111-111111111113",
              "chapterID": "11111111-1111-1111-1111-111111111111",
              "parentSectionID": null,
              "heading": "Build Layers Instead Of Single-Point Fixes",
              "bodyMarkdown": "A resilient plan has backups for the basics.",
              "plainText": "A resilient plan has backups for the basics.",
              "sortOrder": 200,
              "tags": ["redundancy", "maintenance", "readiness"],
              "safetyLevel": "normal",
              "chunkGroupID": "preparedness-foundations-layering",
              "version": 1,
              "lastReviewedAt": "2026-03-22T00:00:00Z"
            }
          ]
        }
      ]
    }
    """

    private static let quickCardPack = """
    {
      "quickCards": [
        {
          "id": "22222222-2222-2222-2222-222222222221",
          "title": "First Hour Power Outage Check",
          "slug": "first-hour-power-outage-check",
          "category": "power-outage",
          "summary": "Stabilize light, refrigeration, charging, and household communication in the first hour.",
          "bodyMarkdown": "1. Confirm everyone is safe.",
          "priority": 100,
          "relatedSectionIDs": [
            "11111111-1111-1111-1111-111111111112",
            "11111111-1111-1111-1111-111111111113"
          ],
          "tags": ["power", "lighting", "communications"],
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "largeTypeLayoutVersion": 1
        },
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "title": "Water Rotation Check",
          "slug": "water-rotation-check",
          "category": "water",
          "summary": "Keep stored water easy to trust, easy to reach, and easy to rotate.",
          "bodyMarkdown": "1. Check containers for leaks.",
          "priority": 80,
          "relatedSectionIDs": [
            "11111111-1111-1111-1111-111111111112"
          ],
          "tags": ["water", "storage", "rotation"],
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "largeTypeLayoutVersion": 1
        }
      ]
    }
    """
}
