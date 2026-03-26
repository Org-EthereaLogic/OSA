import XCTest
@testable import OSA

@MainActor
final class OnscreenContentManagerTests: XCTestCase {

    // MARK: - Quick Card Context

    func testPublishQuickCardSetsCurrentContent() {
        let manager = OnscreenContentManager()
        let id = UUID()

        manager.publishQuickCard(id: id, title: "Boil Water", category: "Water")

        XCTAssertEqual(
            manager.currentContent,
            .quickCard(id: id, title: "Boil Water", category: "Water")
        )
    }

    // MARK: - Handbook Section Context

    func testPublishHandbookSectionSetsCurrentContent() {
        let manager = OnscreenContentManager()
        let id = UUID()

        manager.publishHandbookSection(id: id, heading: "Purification Methods", chapterTitle: "Water")

        XCTAssertEqual(
            manager.currentContent,
            .handbookSection(id: id, heading: "Purification Methods", chapterTitle: "Water")
        )
    }

    // MARK: - Clear

    func testClearRemovesCurrentContent() {
        let manager = OnscreenContentManager()
        manager.publishQuickCard(id: UUID(), title: "Test", category: "Test")

        manager.clear()

        XCTAssertNil(manager.currentContent)
    }

    // MARK: - Stale Context Replacement

    func testPublishingNewContentReplacesOld() {
        let manager = OnscreenContentManager()
        let firstID = UUID()
        let secondID = UUID()

        manager.publishQuickCard(id: firstID, title: "First", category: "A")
        manager.publishHandbookSection(id: secondID, heading: "Second", chapterTitle: "B")

        XCTAssertEqual(
            manager.currentContent,
            .handbookSection(id: secondID, heading: "Second", chapterTitle: "B")
        )
    }

    // MARK: - Initial State

    func testInitialContentIsNil() {
        let manager = OnscreenContentManager()

        XCTAssertNil(manager.currentContent)
    }
}
