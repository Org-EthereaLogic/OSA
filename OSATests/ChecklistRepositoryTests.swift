import SwiftData
import XCTest
@testable import OSA

@MainActor
final class ChecklistRepositoryTests: XCTestCase {
    func testListTemplatesAfterSeedImport() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templates = try checklistRepo.listTemplates()
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.title, "Test Emergency Kit Check")
        XCTAssertEqual(templates.first?.slug, "test-emergency-kit-check")
        XCTAssertEqual(templates.first?.itemCount, 3)
    }

    func testTemplateBySlug() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let template = try XCTUnwrap(checklistRepo.template(slug: "test-emergency-kit-check"))
        XCTAssertEqual(template.title, "Test Emergency Kit Check")
        XCTAssertEqual(template.items.count, 3)
        XCTAssertEqual(template.items.map(\.text), [
            "Water supply",
            "Flashlight",
            "First aid kit"
        ])
        XCTAssertEqual(template.sourceType, .seeded)
    }

    func testTemplateByID() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        let template = try XCTUnwrap(checklistRepo.template(id: templateID))
        XCTAssertEqual(template.slug, "test-emergency-kit-check")
    }

    func testStartRunFromTemplate() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        let run = try checklistRepo.startRun(from: templateID, title: "My Kit Check", contextNote: "Before trip")

        XCTAssertEqual(run.templateID, templateID)
        XCTAssertEqual(run.title, "My Kit Check")
        XCTAssertEqual(run.contextNote, "Before trip")
        XCTAssertEqual(run.status, .inProgress)
        XCTAssertEqual(run.items.count, 3)
        XCTAssertTrue(run.items.allSatisfy { !$0.isComplete })
    }

    func testActiveRuns() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        _ = try checklistRepo.startRun(from: templateID, title: "Run 1", contextNote: nil)

        let active = try checklistRepo.activeRuns()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.title, "Run 1")
    }

    func testUpdateRunItemCompletion() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        let run = try checklistRepo.startRun(from: templateID, title: "Run", contextNote: nil)

        var updatedItems = run.items
        updatedItems[0] = ChecklistRunItem(
            id: updatedItems[0].id,
            runID: updatedItems[0].runID,
            templateItemID: updatedItems[0].templateItemID,
            text: updatedItems[0].text,
            isComplete: true,
            completedAt: Date(),
            sortOrder: updatedItems[0].sortOrder
        )

        let updatedRun = ChecklistRun(
            id: run.id,
            templateID: run.templateID,
            title: run.title,
            startedAt: run.startedAt,
            completedAt: nil,
            status: .inProgress,
            contextNote: nil,
            items: updatedItems
        )

        try checklistRepo.updateRun(updatedRun)

        let fetched = try XCTUnwrap(checklistRepo.run(id: run.id))
        XCTAssertTrue(fetched.items.first?.isComplete == true)
        XCTAssertNotNil(fetched.items.first?.completedAt)
    }

    func testDeleteRun() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        let run = try checklistRepo.startRun(from: templateID, title: "To Delete", contextNote: nil)

        try checklistRepo.deleteRun(id: run.id)

        let fetched = try checklistRepo.run(id: run.id)
        XCTAssertNil(fetched)
    }

    func testListRunsByStatus() throws {
        let (_, checklistRepo, container) = try makeRepositories()
        withExtendedLifetime(container) {}

        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        let run = try checklistRepo.startRun(from: templateID, title: "Run", contextNote: nil)

        // Complete the run
        let completedRun = ChecklistRun(
            id: run.id,
            templateID: run.templateID,
            title: run.title,
            startedAt: run.startedAt,
            completedAt: Date(),
            status: .completed,
            contextNote: nil,
            items: run.items
        )
        try checklistRepo.updateRun(completedRun)

        let inProgress = try checklistRepo.listRuns(status: .inProgress)
        XCTAssertTrue(inProgress.isEmpty)

        let completed = try checklistRepo.listRuns(status: .completed)
        XCTAssertEqual(completed.count, 1)
    }

    // MARK: - Helpers

    private func makeRepositories() throws -> (SwiftDataContentRepository, SwiftDataChecklistRepository, ModelContainer) {
        let container = try makeInMemoryContainer()
        let contentRepo = SwiftDataContentRepository(modelContext: container.mainContext)
        let checklistRepo = SwiftDataChecklistRepository(modelContext: container.mainContext)

        let bundle = SeedContentBundle(
            manifest: SeedContentManifest(
                schemaVersion: 1,
                contentPackVersion: "test",
                generatedAt: nil,
                packs: []
            ),
            chapters: [],
            quickCards: [],
            checklistTemplates: [makeTestTemplate()]
        )

        try contentRepo.upsertSeedContent(bundle, importedAt: Date())
        return (contentRepo, checklistRepo, container)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
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
            PersistedNoteRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeTestTemplate() -> ChecklistTemplate {
        let templateID = UUID(uuidString: "44444444-4444-4444-4444-444444444401")!
        return ChecklistTemplate(
            id: templateID,
            title: "Test Emergency Kit Check",
            slug: "test-emergency-kit-check",
            category: "go-bag",
            description: "A test checklist template.",
            estimatedMinutes: 15,
            tags: ["test"],
            sourceType: .seeded,
            lastReviewedAt: nil,
            items: [
                ChecklistTemplateItem(id: UUID(uuidString: "44444444-4444-4444-4444-444444444411")!, templateID: templateID, text: "Water supply", detail: nil, sortOrder: 100, isOptional: false, riskLevel: "high"),
                ChecklistTemplateItem(id: UUID(uuidString: "44444444-4444-4444-4444-444444444412")!, templateID: templateID, text: "Flashlight", detail: nil, sortOrder: 200, isOptional: false, riskLevel: "medium"),
                ChecklistTemplateItem(id: UUID(uuidString: "44444444-4444-4444-4444-444444444413")!, templateID: templateID, text: "First aid kit", detail: nil, sortOrder: 300, isOptional: true, riskLevel: "high")
            ]
        )
    }
}
