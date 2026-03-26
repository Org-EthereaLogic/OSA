import Foundation
import Testing
@testable import OSA

@Suite("KnowledgeChunker")
struct KnowledgeChunkerTests {

    private func makeDocument(
        plainText: String,
        title: String = "Test Document",
        sourceURL: String = "https://www.ready.gov/test"
    ) -> NormalizedDocument {
        NormalizedDocument(
            title: title,
            normalizedMarkdown: "# \(title)\n\n\(plainText)",
            plainText: plainText,
            documentType: .article,
            contentHash: ImportedKnowledgeNormalizer.stableHash(plainText),
            publisherDomain: "www.ready.gov",
            sourceURL: sourceURL
        )
    }

    // MARK: - Heading-Aware Chunking

    @Test("Heading-aware chunking splits at heading boundaries")
    func headingAwareChunking() {
        let text = """
        # Water Storage
        Store one gallon per person per day for three days.

        # Food Supply
        Keep at least a three-day supply of non-perishable food.
        """
        let doc = makeDocument(plainText: text)
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: [])

        #expect(chunks.count >= 2)
        #expect(chunks.first?.headingPath == "Water Storage")
    }

    // MARK: - Paragraph Fallback

    @Test("Paragraph-group fallback when no headings exist")
    func paragraphFallback() {
        let paragraphs = (1...5).map { "Paragraph \($0) content with enough words to make a meaningful chunk of text for testing purposes." }
        let text = paragraphs.joined(separator: "\n\n")
        let doc = makeDocument(plainText: text)
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: [])

        #expect(!chunks.isEmpty)
        // With no headings, heading path should be empty
        #expect(chunks.first?.headingPath == "")
    }

    // MARK: - Sort Order

    @Test("Chunks have stable sequential sort order")
    func stableSortOrder() {
        let text = """
        # Section One
        Content for section one.

        # Section Two
        Content for section two.

        # Section Three
        Content for section three.
        """
        let doc = makeDocument(plainText: text)
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: [])

        let sortOrders = chunks.map(\.sortOrder)
        #expect(sortOrders == sortOrders.sorted())
        #expect(Set(sortOrders).count == sortOrders.count) // all unique
    }

    // MARK: - Non-Empty Text

    @Test("All chunks have non-empty text")
    func nonEmptyChunkText() {
        let text = "Some content.\n\n\n\nMore content after gaps.\n\nFinal paragraph."
        let doc = makeDocument(plainText: text)
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: [])

        for chunk in chunks {
            #expect(!chunk.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Deterministic Local Chunk ID

    @Test("Same input produces same localChunkID")
    func deterministicLocalChunkID() {
        let text = "# Section\nSome content for determinism testing."
        let doc = makeDocument(plainText: text)
        let docID = UUID()
        let chunks1 = KnowledgeChunker.chunk(doc, documentID: docID, trustLevel: .curated, isSearchable: true, tags: [])
        let chunks2 = KnowledgeChunker.chunk(doc, documentID: docID, trustLevel: .curated, isSearchable: true, tags: [])

        #expect(chunks1.count == chunks2.count)
        for (c1, c2) in zip(chunks1, chunks2) {
            #expect(c1.localChunkID == c2.localChunkID)
        }
    }

    // MARK: - Searchable Gating

    @Test("Approved chunks are searchable")
    func approvedChunksSearchable() {
        let doc = makeDocument(plainText: "Some searchable content.")
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: [])

        let allSearchable = chunks.allSatisfy(\.isSearchable)
        #expect(allSearchable)
    }

    @Test("Pending chunks are not searchable")
    func pendingChunksNotSearchable() {
        let doc = makeDocument(plainText: "Some pending content.")
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .unverified, isSearchable: false, tags: [])

        let noneSearchable = chunks.allSatisfy { !$0.isSearchable }
        #expect(noneSearchable)
    }

    // MARK: - Trust Level Inheritance

    @Test("Chunks inherit trust level from parameter")
    func trustLevelInheritance() {
        let doc = makeDocument(plainText: "Content for trust test.")
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .community, isSearchable: true, tags: [])

        let allCommunity = chunks.allSatisfy { $0.trustLevel == .community }
        #expect(allCommunity)
    }

    // MARK: - Tags

    @Test("Chunks receive provided tags")
    func tagsApplied() {
        let doc = makeDocument(plainText: "Content with tags.")
        let tags = ["www.ready.gov", "article"]
        let chunks = KnowledgeChunker.chunk(doc, documentID: UUID(), trustLevel: .curated, isSearchable: true, tags: tags)

        let allTagged = chunks.allSatisfy { $0.tags == tags }
        #expect(allTagged)
    }
}
