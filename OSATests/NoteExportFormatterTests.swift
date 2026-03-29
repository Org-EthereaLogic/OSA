import Foundation
import XCTest
@testable import OSA

final class NoteExportFormatterTests: XCTestCase {
    func testMarkdownContentUsesStoredMarkdownAndTitle() {
        let note = makeNote(bodyMarkdown: "## Meeting Point\n\nUse the school parking lot.", plainText: "ignored")

        let exported = NoteExportFormatter.markdownContent(for: note)

        XCTAssertTrue(exported.contains("# Family Plan"))
        XCTAssertTrue(exported.contains("## Meeting Point"))
        XCTAssertTrue(exported.contains("Shared from OSA"))
    }

    func testPlainTextContentUsesStoredPlainTextAndTitle() {
        let note = makeNote(bodyMarkdown: "ignored", plainText: "School parking lot behind the gym.")

        let exported = NoteExportFormatter.plainTextContent(for: note)

        XCTAssertTrue(exported.contains("Family Plan"))
        XCTAssertTrue(exported.contains("School parking lot behind the gym."))
        XCTAssertTrue(exported.contains("Shared from OSA"))
    }

    func testStoredPlainTextRemovesMarkdownSyntax() {
        let plainText = NoteExportFormatter.storedPlainText(
            fromMarkdown: "# Heading\n\n- Water\n- Food\n\n**Bold** _Text_"
        )

        XCTAssertEqual(plainText, "Heading\n\nWater\nFood\n\nBold Text")
    }

    private func makeNote(bodyMarkdown: String, plainText: String) -> NoteRecord {
        NoteRecord(
            id: UUID(),
            title: "Family Plan",
            bodyMarkdown: bodyMarkdown,
            plainText: plainText,
            noteType: .familyPlan,
            tags: [],
            linkedSectionIDs: [],
            linkedInventoryItemIDs: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
