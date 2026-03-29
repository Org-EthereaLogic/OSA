import Foundation
import XCTest
@testable import OSA

final class ChecklistPDFExporterTests: XCTestCase {
    func testTemplateDocumentIncludesSummaryAndItems() {
        let template = makeTemplate()

        let document = ChecklistPDFExporter.document(for: template)

        XCTAssertEqual(document.title, template.title)
        XCTAssertTrue(document.sections.contains(where: { $0.heading == "Summary" }))
        XCTAssertTrue(document.sections.contains(where: { $0.heading == "Items" }))
        XCTAssertTrue(document.sections.last?.lines.contains("• Store one gallon of water per person") == true)
    }

    func testRunDocumentIncludesStatusContextAndCompletionMarks() {
        let run = makeRun()

        let document = ChecklistPDFExporter.document(for: run)

        XCTAssertTrue(document.sections.contains(where: { $0.lines.contains("Status: In Progress") }))
        XCTAssertTrue(document.sections.contains(where: { $0.heading == "Context" && $0.lines.contains("Weekend drill") }))
        XCTAssertTrue(document.sections.last?.lines.contains("[x] Fill and rotate water containers") == true)
        XCTAssertTrue(document.sections.last?.lines.contains("[ ] Check the flashlight battery stash") == true)
    }

    func testExportRunWritesPDFData() throws {
        let url = try ChecklistPDFExporter.exportRun(makeRun())
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let header = String(data: data.prefix(4), encoding: .ascii)

        XCTAssertEqual(header, "%PDF")
        XCTAssertFalse(data.isEmpty)
    }

    private func makeTemplate() -> ChecklistTemplate {
        let templateID = UUID()
        return ChecklistTemplate(
            id: templateID,
            title: "72-Hour Emergency Kit Check",
            slug: "72-hour-emergency-kit-check",
            category: "family",
            description: "Review core supplies for a three-day kit.",
            estimatedMinutes: 15,
            tags: ["family"],
            sourceType: .seeded,
            presentationStyle: .standard,
            timerProfile: nil,
            lastReviewedAt: Date(timeIntervalSince1970: 1_700_000_000),
            items: [
                ChecklistTemplateItem(
                    id: UUID(),
                    templateID: templateID,
                    text: "Store one gallon of water per person",
                    detail: nil,
                    sortOrder: 0,
                    isOptional: false,
                    riskLevel: nil
                ),
                ChecklistTemplateItem(
                    id: UUID(),
                    templateID: templateID,
                    text: "Pack extra pet food",
                    detail: "Only if applicable.",
                    sortOrder: 1,
                    isOptional: true,
                    riskLevel: nil
                )
            ]
        )
    }

    private func makeRun() -> ChecklistRun {
        let runID = UUID()
        return ChecklistRun(
            id: runID,
            templateID: UUID(),
            title: "Weekend Supply Drill",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            completedAt: nil,
            status: .inProgress,
            contextNote: "Weekend drill",
            items: [
                ChecklistRunItem(
                    id: UUID(),
                    runID: runID,
                    templateItemID: UUID(),
                    text: "Fill and rotate water containers",
                    isComplete: true,
                    completedAt: nil,
                    sortOrder: 0
                ),
                ChecklistRunItem(
                    id: UUID(),
                    runID: runID,
                    templateItemID: UUID(),
                    text: "Check the flashlight battery stash",
                    isComplete: false,
                    completedAt: nil,
                    sortOrder: 1
                )
            ]
        )
    }
}
