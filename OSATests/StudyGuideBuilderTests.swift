import XCTest
@testable import OSA

final class StudyGuideBuilderTests: XCTestCase {
    private let builder = StudyGuideBuilder()

    func testBuildMarkdownIncludesTitleOverviewKeyPointsAndSources() {
        let markdown = builder.buildMarkdown(
            from: makeResult(),
            preferredTags: []
        )

        XCTAssertTrue(markdown.contains("# Study Guide: How do I purify water?"))
        XCTAssertTrue(markdown.contains("## Overview"))
        XCTAssertTrue(markdown.contains("Boil water for at least one minute"))
        XCTAssertTrue(markdown.contains("## Key Points"))
        XCTAssertTrue(markdown.contains("### Handbook: Water Purification"))
        XCTAssertTrue(markdown.contains("## Sources"))
        XCTAssertTrue(markdown.contains("- Quick Card: Boil Water Advisory Steps"))
    }

    func testMakeNoteUsesLocalReferenceStudyGuideTagAndLinkedSections() {
        let sectionID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let note = builder.makeNote(
            from: makeResult(sectionID: sectionID),
            preferredTags: ["region:pacific-northwest"],
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(note.noteType, .localReference)
        XCTAssertTrue(note.tags.contains("study-guide"))
        XCTAssertTrue(note.tags.contains("region:pacific-northwest"))
        XCTAssertEqual(note.linkedSectionIDs, [sectionID])
        XCTAssertFalse(note.plainText.isEmpty)
    }

    func testBuildMarkdownIncludesRegionPreferenceWhenPresent() {
        let markdown = builder.buildMarkdown(
            from: makeResult(),
            preferredTags: ["region:pacific-northwest"]
        )

        XCTAssertTrue(markdown.contains("Region preference: Pacific Northwest"))
    }

    private func makeResult(sectionID: UUID = UUID()) -> AnswerResult {
        AnswerResult(
            query: "How do I purify water?",
            evidence: [
                EvidenceItem(
                    id: sectionID,
                    kind: .handbookSection,
                    title: "Water Purification",
                    snippet: "Boil water for at least one minute before drinking.",
                    score: 5.0,
                    sourceLabel: "Handbook",
                    tags: ["water"]
                ),
                EvidenceItem(
                    id: UUID(),
                    kind: .quickCard,
                    title: "Boil Water Advisory Steps",
                    snippet: "Bring water to a rolling boil and cool it safely.",
                    score: 4.0,
                    sourceLabel: "Quick Card",
                    tags: ["water"]
                )
            ],
            citations: [
                CitationReference(
                    id: sectionID,
                    kind: .handbookSection,
                    title: "Water Purification",
                    sourceLabel: "Handbook"
                ),
                CitationReference(
                    id: UUID(),
                    kind: .quickCard,
                    title: "Boil Water Advisory Steps",
                    sourceLabel: "Quick Card"
                )
            ],
            confidence: .groundedHigh,
            answerMode: .extractiveOnly,
            answerText: "Boil water for at least one minute, then cool it in a clean container.",
            suggestedActions: []
        )
    }
}
