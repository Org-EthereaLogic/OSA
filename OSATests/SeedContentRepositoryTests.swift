import CryptoKit
import SwiftData
import XCTest
@testable import OSA

@MainActor
final class SeedContentRepositoryTests: XCTestCase {
    func testBundledSeedContentLoadsFromAppBundle() throws {
        let candidateBundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        let appBundle = try XCTUnwrap(
            candidateBundles.first {
                $0.bundleURL.pathExtension == "app"
                    && $0.url(forResource: "SeedContent", withExtension: nil) != nil
            },
            "Expected an app bundle that contains the SeedContent resource directory."
        )

        let bundle = try SeedContentLoader.bundled(in: appBundle).loadBundle()

        XCTAssertFalse(bundle.chapters.isEmpty)
        XCTAssertFalse(bundle.quickCards.isEmpty)
        XCTAssertFalse(bundle.checklistTemplates.isEmpty)
        XCTAssertFalse(bundle.fieldReferences.isEmpty)
    }

    func testSeedContentLoaderDecodesManifestAndPackFiles() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        let bundle = try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()

        XCTAssertEqual(bundle.manifest.schemaVersion, 1)
        XCTAssertEqual(bundle.manifest.contentPackVersion, "0.1.0")
        XCTAssertEqual(bundle.manifest.packs.count, 4)
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
        XCTAssertEqual(bundle.checklistTemplates.map(\.slug), [
            "test-water-rotation-checklist"
        ])
        XCTAssertEqual(bundle.fieldReferences.map(\.slug), [
            "bleeding-control-basics"
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
        XCTAssertEqual(outcome.checklistTemplateCount, 1)
        XCTAssertEqual(outcome.fieldReferenceCount, 1)

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

        let fieldReference = try XCTUnwrap(repository.entry(slug: "bleeding-control-basics"))
        XCTAssertEqual(fieldReference.category, .firstAid)
        XCTAssertEqual(fieldReference.relatedSectionIDs, [
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
        XCTAssertEqual(try repository.listEntries().count, 1)
        XCTAssertEqual(try repository.chapter(slug: "preparedness-foundations")?.sections.count, 2)

        let versionState = try XCTUnwrap(repository.currentSeedVersionState())
        XCTAssertEqual(versionState.appliedAt, Self.appliedAt)
    }

    func testSeedContentLoaderRejectsMismatchedContentHash() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        try fixtures.overwriteManifest(
            handbookHash: "deadbeef",
            quickCardHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.quickCardPack),
            checklistHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.checklistTemplatePack),
            fieldReferenceHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.fieldReferencePack)
        )

        XCTAssertThrowsError(
            try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()
        ) { error in
            XCTAssertEqual(
                error as? SeedContentLoaderError,
                .contentHashMismatch(
                    expected: "deadbeef",
                    actual: SeedContentFixtures.sha256Hex(SeedContentFixtures.handbookPack),
                    fileName: "handbook-foundations-v1.json"
                )
            )
        }
    }

    func testSeedContentLoaderRejectsFieldReferenceWithMissingRelatedSection() throws {
        let fixtures = try SeedContentFixtures()
        defer { fixtures.cleanup() }

        try fixtures.overwriteFieldReferencePack(
            contents: SeedContentFixtures.invalidFieldReferencePack
        )
        try fixtures.overwriteManifest(
            handbookHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.handbookPack),
            quickCardHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.quickCardPack),
            checklistHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.checklistTemplatePack),
            fieldReferenceHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.invalidFieldReferencePack)
        )

        XCTAssertThrowsError(
            try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()
        ) { error in
            XCTAssertEqual(
                error as? SeedContentLoaderError,
                .missingReferencedSectionForFieldReference(
                    fieldReferenceID: UUID(uuidString: "33333333-3333-3333-3333-333333333331")!,
                    sectionID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
                )
            )
        }
    }

    func testSeedContentLoaderDecodesMediaQuizAndWeeklyDrillMetadata() throws {
        let fixtures = try EnhancedSeedContentFixtures()
        defer { fixtures.cleanup() }

        let bundle = try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()

        let quickCard = try XCTUnwrap(bundle.quickCards.first)
        XCTAssertEqual(quickCard.mediaAttachments.count, 2)
        XCTAssertEqual(quickCard.mediaAttachments.first?.bundlePath, "Media/Illustrations/pressure-dressing.svg")
        XCTAssertEqual(quickCard.quizDefinition?.questions.count, 1)
        XCTAssertEqual(quickCard.weeklyDrillMetadata?.badgeLabel, "Drill Badge")

        let fieldReference = try XCTUnwrap(bundle.fieldReferences.first)
        XCTAssertEqual(fieldReference.mediaAttachments.count, 1)
        XCTAssertEqual(fieldReference.quizDefinition?.title, "Bowline Drill")
    }

    func testSeedContentLoaderRejectsMissingMediaAsset() throws {
        let fixtures = try EnhancedSeedContentFixtures()
        defer { fixtures.cleanup() }

        try fixtures.removeIllustration()

        XCTAssertThrowsError(
            try SeedContentLoader(directoryURL: fixtures.directoryURL).loadBundle()
        ) { error in
            XCTAssertEqual(
                error as? SeedContentLoaderError,
                .missingMediaAsset(
                    contentID: UUID(uuidString: "55555555-5555-5555-5555-555555555551")!,
                    path: "Media/Illustrations/pressure-dressing.svg"
                )
            )
        }
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedFieldReferenceEntry.self,
            PersistedSeedContentState.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static let appliedAt = Date(timeIntervalSince1970: 1_742_601_600)
    private static let laterAppliedAt = Date(timeIntervalSince1970: 1_742_688_000)
}

private struct EnhancedSeedContentFixtures {
    let rootURL: URL
    let directoryURL: URL

    init() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        directoryURL = rootURL.appendingPathComponent("SeedContent", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: rootURL.appendingPathComponent("Media/Illustrations", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: rootURL.appendingPathComponent("Media/Videos", isDirectory: true),
            withIntermediateDirectories: true
        )

        try write("handbook-foundations-v1.json", contents: SeedContentFixtures.handbookPack)
        try write("quick-cards-core-v1.json", contents: Self.quickCardPack)
        try write("checklist-templates-core-v1.json", contents: SeedContentFixtures.checklistTemplatePack)
        try write("field-references-core-v1.json", contents: Self.fieldReferencePack)
        try writeMedia("Media/Illustrations/pressure-dressing.svg", contents: "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>")
        try writeMedia("Media/Illustrations/bowline.svg", contents: "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>")
        try writeMedia("Media/Videos/pressure-dressing-flow.mp4", contents: "placeholder")
        try write(
            "SeedManifest.json",
            contents: Self.makeManifest(
                handbookHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.handbookPack),
                quickCardHash: SeedContentFixtures.sha256Hex(Self.quickCardPack),
                checklistHash: SeedContentFixtures.sha256Hex(SeedContentFixtures.checklistTemplatePack),
                fieldReferenceHash: SeedContentFixtures.sha256Hex(Self.fieldReferencePack)
            )
        )
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: rootURL)
    }

    func removeIllustration() throws {
        try FileManager.default.removeItem(
            at: rootURL.appendingPathComponent("Media/Illustrations/pressure-dressing.svg")
        )
    }

    private func write(_ fileName: String, contents: String) throws {
        try contents.write(
            to: directoryURL.appendingPathComponent(fileName),
            atomically: true,
            encoding: .utf8
        )
    }

    private func writeMedia(_ relativePath: String, contents: String) throws {
        try contents.write(
            to: rootURL.appendingPathComponent(relativePath),
            atomically: true,
            encoding: .utf8
        )
    }

    private static func makeManifest(
        handbookHash: String,
        quickCardHash: String,
        checklistHash: String,
        fieldReferenceHash: String
    ) -> String {
        """
        {
          "schemaVersion": 1,
          "contentPackVersion": "0.1.0",
          "generatedAt": "2026-03-29T00:00:00Z",
          "packs": [
            {
              "identifier": "handbook-foundations",
              "kind": "handbook-chapters",
              "version": "2026.03.29.1",
              "fileName": "handbook-foundations-v1.json",
              "recordCount": 1,
              "contentHash": "\(handbookHash)"
            },
            {
              "identifier": "quick-cards-core",
              "kind": "quick-cards",
              "version": "2026.03.29.1",
              "fileName": "quick-cards-core-v1.json",
              "recordCount": 1,
              "contentHash": "\(quickCardHash)"
            },
            {
              "identifier": "checklist-templates-core",
              "kind": "checklist-templates",
              "version": "2026.03.29.1",
              "fileName": "checklist-templates-core-v1.json",
              "recordCount": 1,
              "contentHash": "\(checklistHash)"
            },
            {
              "identifier": "field-references-core",
              "kind": "field-references",
              "version": "2026.03.29.1",
              "fileName": "field-references-core-v1.json",
              "recordCount": 1,
              "contentHash": "\(fieldReferenceHash)"
            }
          ]
        }
        """
    }

    static let quickCardPack = """
    {
      "quickCards": [
        {
          "id": "55555555-5555-5555-5555-555555555551",
          "title": "Pressure Dressing Quick Check",
          "slug": "pressure-dressing-quick-check",
          "category": "first-aid",
          "summary": "Fixture with media and quiz metadata.",
          "bodyMarkdown": "1. Place the pad.",
          "priority": 90,
          "relatedSectionIDs": [
            "11111111-1111-1111-1111-111111111112"
          ],
          "tags": ["first-aid"],
          "lastReviewedAt": "2026-03-29T00:00:00Z",
          "largeTypeLayoutVersion": 1,
          "mediaAttachments": [
            {
              "kind": "inline-svg",
              "bundlePath": "Media/Illustrations/pressure-dressing.svg",
              "caption": "Pressure dressing illustration.",
              "accessibilityLabel": "Pressure dressing image."
            },
            {
              "kind": "short-video",
              "bundlePath": "Media/Videos/pressure-dressing-flow.mp4",
              "caption": "Pressure dressing video.",
              "accessibilityLabel": "Pressure dressing video.",
              "transcript": "Wrap path."
            }
          ],
          "quizDefinition": {
            "title": "Pressure Dressing Drill",
            "masteryScorePercent": 100,
            "questions": [
              {
                "id": "q1",
                "prompt": "What should you keep checking below the dressing?",
                "options": [
                  { "id": "a", "text": "Circulation" },
                  { "id": "b", "text": "Wallpaper" }
                ],
                "correctOptionID": "a",
                "explanation": "Keep checking circulation."
              }
            ]
          },
          "weeklyDrillMetadata": {
            "title": "Pressure Dressing Drill",
            "prompt": "Run the dressing sequence out loud.",
            "badgeLabel": "Drill Badge"
          }
        }
      ]
    }
    """

    static let fieldReferencePack = """
    {
      "entries": [
        {
          "id": "66666666-6666-6666-6666-666666666661",
          "slug": "bowline-reference",
          "title": "Bowline Reference",
          "category": "rope-and-knots",
          "summary": "Fixture with illustration and quiz metadata.",
          "sortOrder": 100,
          "sections": [
            {
              "title": "Tie Sequence",
              "bodyMarkdown": "- Up through the loop.",
              "plainText": "Up through the loop.",
              "sortOrder": 100
            }
          ],
          "relatedSectionIDs": [
            "11111111-1111-1111-1111-111111111112"
          ],
          "tags": ["rope"],
          "safetyLevel": "normal",
          "lastReviewedAt": "2026-03-29T00:00:00Z",
          "mediaAttachments": [
            {
              "kind": "inline-svg",
              "bundlePath": "Media/Illustrations/bowline.svg",
              "caption": "Bowline illustration.",
              "accessibilityLabel": "Bowline image."
            }
          ],
          "quizDefinition": {
            "title": "Bowline Drill",
            "masteryScorePercent": 100,
            "questions": [
              {
                "id": "q1",
                "prompt": "Which loop is not the goal here?",
                "options": [
                  { "id": "a", "text": "Fixed loop" },
                  { "id": "b", "text": "Slip loop" }
                ],
                "correctOptionID": "b",
                "explanation": "The bowline is taught as a fixed loop."
              }
            ]
          }
        }
      ]
    }
    """
}

private struct SeedContentFixtures {
    let directoryURL: URL

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        try write("handbook-foundations-v1.json", contents: Self.handbookPack)
        try write("quick-cards-core-v1.json", contents: Self.quickCardPack)
        try write("checklist-templates-core-v1.json", contents: Self.checklistTemplatePack)
        try write("field-references-core-v1.json", contents: Self.fieldReferencePack)
        try overwriteManifest(
            handbookHash: Self.sha256Hex(Self.handbookPack),
            quickCardHash: Self.sha256Hex(Self.quickCardPack),
            checklistHash: Self.sha256Hex(Self.checklistTemplatePack),
            fieldReferenceHash: Self.sha256Hex(Self.fieldReferencePack)
        )
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

    func overwriteFieldReferencePack(contents: String) throws {
        try write("field-references-core-v1.json", contents: contents)
    }

    func overwriteManifest(
        handbookHash: String,
        quickCardHash: String,
        checklistHash: String,
        fieldReferenceHash: String
    ) throws {
        try write(
            "SeedManifest.json",
            contents: Self.makeManifest(
                handbookHash: handbookHash,
                quickCardHash: quickCardHash,
                checklistHash: checklistHash,
                fieldReferenceHash: fieldReferenceHash
            )
        )
    }

    static func sha256Hex(_ contents: String) -> String {
        SHA256.hash(data: Data(contents.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    fileprivate static func makeManifest(
        handbookHash: String,
        quickCardHash: String,
        checklistHash: String,
        fieldReferenceHash: String
    ) -> String {
        """
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
          "contentHash": "\(handbookHash)"
        },
        {
          "identifier": "quick-cards-core",
          "kind": "quick-cards",
          "version": "2026.03.22.1",
          "fileName": "quick-cards-core-v1.json",
          "recordCount": 2,
          "contentHash": "\(quickCardHash)"
        },
        {
          "identifier": "checklist-templates-core",
          "kind": "checklist-templates",
          "version": "2026.03.22.1",
          "fileName": "checklist-templates-core-v1.json",
          "recordCount": 1,
          "contentHash": "\(checklistHash)"
        },
        {
          "identifier": "field-references-core",
          "kind": "field-references",
          "version": "2026.03.22.1",
          "fileName": "field-references-core-v1.json",
          "recordCount": 1,
          "contentHash": "\(fieldReferenceHash)"
        }
      ]
    }
    """
    }

    static let handbookPack = """
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

    static let quickCardPack = """
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

    static let checklistTemplatePack = """
    {
      "templates": [
        {
          "id": "44444444-4444-4444-4444-444444444401",
          "title": "Test Water Rotation Checklist",
          "slug": "test-water-rotation-checklist",
          "category": "water",
          "description": "Simple checklist used to verify seed import and checklist upserts.",
          "estimatedMinutes": 10,
          "tags": ["water", "rotation"],
          "sourceType": "seeded",
          "lastReviewedAt": "2026-03-22T00:00:00Z",
          "items": [
            {
              "id": "44444444-4444-4444-4444-444444444411",
              "text": "Inspect storage containers",
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

    static let fieldReferencePack = """
    {
      "entries": [
        {
          "id": "33333333-3333-3333-3333-333333333331",
          "slug": "bleeding-control-basics",
          "title": "Bleeding Control Basics",
          "category": "first-aid",
          "summary": "Static reference fixture for field-reference seed import tests.",
          "sortOrder": 100,
          "sections": [
            {
              "title": "Immediate Actions",
              "bodyMarkdown": "- Apply direct pressure.",
              "plainText": "Apply direct pressure.",
              "sortOrder": 100
            }
          ],
          "relatedSectionIDs": [
            "11111111-1111-1111-1111-111111111112"
          ],
          "tags": ["first-aid", "bleeding"],
          "safetyLevel": "sensitive-static-only",
          "lastReviewedAt": "2026-03-22T00:00:00Z"
        }
      ]
    }
    """

    static let invalidFieldReferencePack = """
    {
      "entries": [
        {
          "id": "33333333-3333-3333-3333-333333333331",
          "slug": "bleeding-control-basics",
          "title": "Bleeding Control Basics",
          "category": "first-aid",
          "summary": "Invalid reference fixture.",
          "sortOrder": 100,
          "sections": [
            {
              "title": "Immediate Actions",
              "bodyMarkdown": "- Apply direct pressure.",
              "plainText": "Apply direct pressure.",
              "sortOrder": 100
            }
          ],
          "relatedSectionIDs": [
            "99999999-9999-9999-9999-999999999999"
          ],
          "tags": ["first-aid", "bleeding"],
          "safetyLevel": "sensitive-static-only",
          "lastReviewedAt": "2026-03-22T00:00:00Z"
        }
      ]
    }
    """
}
