import XCTest
@testable import OSA

final class EvidenceRankerTests: XCTestCase {
    func testQuickCardsRankedHigher() {
        let section = EvidenceItem(
            id: UUID(), kind: .handbookSection,
            title: "Water Storage", snippet: "Store water safely",
            score: 5.0, sourceLabel: "Handbook", tags: []
        )
        let quickCard = EvidenceItem(
            id: UUID(), kind: .quickCard,
            title: "Water Emergency", snippet: "Quick water tips",
            score: 5.0, sourceLabel: "Quick Card", tags: []
        )

        let ranked = EvidenceRanker.rank([section, quickCard], query: "water")
        XCTAssertEqual(ranked.first?.kind, .quickCard)
    }

    func testExactTitleMatchBoost() {
        let exact = EvidenceItem(
            id: UUID(), kind: .handbookSection,
            title: "Water Storage", snippet: "Details about storage",
            score: 3.0, sourceLabel: "Handbook", tags: []
        )
        let partial = EvidenceItem(
            id: UUID(), kind: .handbookSection,
            title: "Emergency Supplies", snippet: "Including water",
            score: 5.0, sourceLabel: "Handbook", tags: []
        )

        let ranked = EvidenceRanker.rank([partial, exact], query: "water storage")
        XCTAssertEqual(ranked.first?.title, "Water Storage")
    }

    func testTagMatchBoost() {
        let tagged = EvidenceItem(
            id: UUID(), kind: .handbookSection,
            title: "General Guide", snippet: "Various topics",
            score: 3.0, sourceLabel: "Handbook", tags: ["water", "storage"]
        )
        let untagged = EvidenceItem(
            id: UUID(), kind: .handbookSection,
            title: "Other Guide", snippet: "Other content",
            score: 4.0, sourceLabel: "Handbook", tags: []
        )

        let ranked = EvidenceRanker.rank([untagged, tagged], query: "water")
        XCTAssertEqual(ranked.first?.title, "General Guide")
    }

    func testEmptyInputReturnsEmpty() {
        let ranked = EvidenceRanker.rank([], query: "water")
        XCTAssertTrue(ranked.isEmpty)
    }
}
