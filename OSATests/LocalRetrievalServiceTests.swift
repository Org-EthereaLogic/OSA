import XCTest
@testable import OSA

final class LocalRetrievalServiceTests: XCTestCase {
    private func makeService(
        searchResults: [SearchResult] = [],
        searchService: (any SearchService)? = nil,
        sensitivity: SensitivityResult = .allowed,
        answerMode: AnswerMode = .extractiveOnly,
        answerGenerator: (any GroundedAnswerGenerator)? = nil
    ) -> LocalRetrievalService {
        LocalRetrievalService(
            searchService: searchService ?? StubSearchService(results: searchResults),
            sensitivityClassifier: StubClassifier(result: sensitivity),
            capabilityDetector: StubCapabilityDetector(mode: answerMode),
            answerGenerator: answerGenerator
        )
    }

    func testEmptyQueryReturnsRefusal() async throws {
        let service = makeService()
        let outcome = try await service.retrieve(query: "", scopes: nil)

        if case .refused(.emptyQuery) = outcome {
            // pass
        } else {
            XCTFail("Expected emptyQuery refusal, got \(outcome)")
        }
    }

    func testBlockedSensitiveQueryReturnsRefusal() async throws {
        let service = makeService(
            sensitivity: .blocked(reason: "Hunting is blocked")
        )
        let outcome = try await service.retrieve(query: "how to hunt deer", scopes: nil)

        if case .refused(.blockedSensitiveScope(let reason)) = outcome {
            XCTAssertTrue(reason.contains("Hunting"))
        } else {
            XCTFail("Expected blockedSensitiveScope refusal, got \(outcome)")
        }
    }

    func testNoResultsReturnsInsufficientEvidence() async throws {
        let service = makeService(searchResults: [])
        let outcome = try await service.retrieve(query: "water storage", scopes: nil)

        if case .refused(.insufficientEvidence) = outcome {
            // pass
        } else {
            XCTFail("Expected insufficientEvidence refusal, got \(outcome)")
        }
    }

    func testSuccessfulRetrievalReturnsAnswer() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "Water Storage", snippet: "Store one gallon per person", score: 5.0, tags: []),
            SearchResult(id: UUID(), kind: .quickCard, title: "Water Emergency", snippet: "Quick water tips", score: 4.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "water storage", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertFalse(result.evidence.isEmpty)
            XCTAssertFalse(result.citations.isEmpty)
            XCTAssertEqual(result.citations.count, result.evidence.count)
            XCTAssertFalse(result.answerText.isEmpty)
        } else {
            XCTFail("Expected answered outcome, got \(outcome)")
        }
    }

    func testHighConfidenceWithMultipleApprovedSources() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "A", snippet: "Snippet A", score: 5.0, tags: []),
            SearchResult(id: UUID(), kind: .handbookSection, title: "B", snippet: "Snippet B", score: 4.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "shelter", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.confidence, .groundedHigh)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testMediumConfidenceWithSingleSource() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .noteRecord, title: "My Note", snippet: "Personal info", score: 3.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "personal note", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.confidence, .groundedMedium)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testSensitiveStaticOnlyRestrictsScopes() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "First Aid", snippet: "CPR steps", score: 5.0, tags: []),
        ]
        let service = makeService(
            searchResults: results,
            sensitivity: .sensitiveStaticOnly(reason: "First aid is sensitive")
        )
        let outcome = try await service.retrieve(query: "cpr steps", scopes: nil)

        if case .answered(let result) = outcome {
            // Should still return answer from handbook (allowed for sensitive-static-only)
            XCTAssertFalse(result.evidence.isEmpty)
        } else {
            XCTFail("Expected answered outcome for sensitive-static-only")
        }
    }

    func testCitationsHaveStableIDs() async throws {
        let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let results = [
            SearchResult(id: fixedID, kind: .handbookSection, title: "Water", snippet: "Info", score: 5.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "water", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.citations.first?.id, fixedID)
            XCTAssertEqual(result.citations.first?.kind, .handbookSection)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testRetrievalScopesExcludeNotesWhenPersonalNotesAreDisabled() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .noteRecord, title: "My Water Note", snippet: "Private note", score: 6.0, tags: []),
            SearchResult(id: UUID(), kind: .handbookSection, title: "Water Storage", snippet: "Store one gallon per person.", score: 5.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let scopes = AskScopeSettings.retrievalScopes(includePersonalNotes: false)

        let outcome = try await service.retrieve(query: "water", scopes: scopes)

        if case .answered(let result) = outcome {
            XCTAssertTrue(result.evidence.contains(where: { $0.kind == .handbookSection }))
            XCTAssertFalse(result.evidence.contains(where: { $0.kind == .noteRecord }))
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testImportedKnowledgeScopeMapsToSearchKind() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .importedKnowledge, title: "Emergency Water", snippet: "Imported guide content", score: 5.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let scopes: Set<RetrievalScope> = [.importedKnowledge]
        let outcome = try await service.retrieve(query: "water", scopes: scopes)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.evidence.first?.kind, .importedKnowledge)
            XCTAssertEqual(result.evidence.first?.sourceLabel, "Imported Source")
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testImportedKnowledgeContributesToHighConfidence() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .importedKnowledge, title: "A", snippet: "Content A", score: 5.0, tags: []),
            SearchResult(id: UUID(), kind: .importedKnowledge, title: "B", snippet: "Content B", score: 4.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "emergency", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.confidence, .groundedHigh)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testImportedKnowledgeCitationDisplayLabel() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .importedKnowledge, title: "Water Guide", snippet: "Content", score: 5.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let outcome = try await service.retrieve(query: "water", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.citations.first?.displayLabel, "Source: Water Guide")
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testImportedKnowledgeIncludedInDefaultScopes() {
        let scopes = AskScopeSettings.retrievalScopes(includePersonalNotes: false)
        XCTAssertTrue(scopes.contains(.importedKnowledge))
    }

    func testRetrievalScopesIncludeNotesWhenPersonalNotesAreEnabled() async throws {
        let noteID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let results = [
            SearchResult(id: noteID, kind: .noteRecord, title: "Family Water Plan", snippet: "Stored in the garage cabinet.", score: 5.0, tags: []),
        ]
        let service = makeService(searchResults: results)
        let scopes = AskScopeSettings.retrievalScopes(includePersonalNotes: true)

        let outcome = try await service.retrieve(query: "where is our stored water", scopes: scopes)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.evidence.first?.id, noteID)
            XCTAssertEqual(result.evidence.first?.kind, .noteRecord)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testShortFollowUpUsesPreviousContextWhenNeeded() async throws {
        let waterFilters = SearchResult(
            id: UUID(),
            kind: .handbookSection,
            title: "Water Filters",
            snippet: "Use an approved water filter after pre-filtering debris.",
            score: 10.0,
            tags: ["water", "filters"]
        )
        let searchService = StubSearchService(results: []) { query, scopes, _, limit in
            if query.contains("filters") && query.contains("purify") {
                return Array([waterFilters].prefix(limit))
            }

            if let scopes, !scopes.contains(.handbookSection) {
                return []
            }

            return []
        }
        let service = makeService(searchService: searchService)
        let context = RetrievalContext(
            followUp: FollowUpContext(
                previousQuery: "how do I purify water",
                previousAnswerSummary: "Use boiling or treatment methods for safer water.",
                previousCitationLabels: ["Handbook: Water Purification"],
                previousCitationIDs: [UUID()]
            )
        )

        let outcome = try await service.retrieve(
            query: "What about filters?",
            scopes: nil,
            context: context
        )

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.evidence.first?.title, "Water Filters")
        } else {
            XCTFail("Expected answered outcome when follow-up context is provided")
        }
    }

    func testShortFollowUpRefusesWithoutContext() async throws {
        let searchService = StubSearchService(results: []) { query, _, _, _ in
            query == "filters" ? [] : []
        }
        let service = makeService(searchService: searchService)

        let outcome = try await service.retrieve(
            query: "What about filters?",
            scopes: nil,
            context: nil
        )

        if case .refused(.insufficientEvidence) = outcome {
            // pass
        } else {
            XCTFail("Expected insufficientEvidence refusal without follow-up context, got \(outcome)")
        }
    }

    func testPreferredRegionTagsBoostMatchingContent() async throws {
        let generic = SearchResult(
            id: UUID(),
            kind: .handbookSection,
            title: "Winter Storm Supplies",
            snippet: "Pack light sources and blankets.",
            score: 6.0,
            tags: []
        )
        let regional = SearchResult(
            id: UUID(),
            kind: .handbookSection,
            title: "Mountain Winter Storm Supplies",
            snippet: "Pack traction gear and extra insulation.",
            score: 5.5,
            tags: ["region:mountain"]
        )
        let service = makeService(searchResults: [generic, regional])
        let context = RetrievalContext(preferredTags: ["region:mountain"])

        let outcome = try await service.retrieve(
            query: "winter storm supplies",
            scopes: nil,
            context: context
        )

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.evidence.first?.id, regional.id)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testNilContextPreservesCurrentOneShotBehavior() async throws {
        let results = [
            SearchResult(
                id: UUID(),
                kind: .handbookSection,
                title: "Water Storage",
                snippet: "Store one gallon per person.",
                score: 5.0,
                tags: []
            )
        ]
        let service = makeService(searchResults: results)

        let defaultOutcome = try await service.retrieve(query: "water storage", scopes: nil)
        let explicitNilOutcome = try await service.retrieve(
            query: "water storage",
            scopes: nil,
            context: nil
        )

        XCTAssertEqual(defaultOutcome, explicitNilOutcome)
    }
}

// MARK: - Test Doubles

struct StubSearchService: SearchService {
    let results: [SearchResult]
    let queryHandler: ((String, Set<SearchResultKind>?, Set<String>, Int) throws -> [SearchResult])?

    init(
        results: [SearchResult],
        queryHandler: ((String, Set<SearchResultKind>?, Set<String>, Int) throws -> [SearchResult])? = nil
    ) {
        self.results = results
        self.queryHandler = queryHandler
    }

    func search(
        query: String,
        scopes: Set<SearchResultKind>?,
        requiredTags: Set<String>,
        limit: Int
    ) throws -> [SearchResult] {
        if let queryHandler {
            return try queryHandler(query, scopes, requiredTags, limit)
        }

        var filtered = results

        if let scopes {
            filtered = filtered.filter { scopes.contains($0.kind) }
        }

        if !requiredTags.isEmpty {
            filtered = filtered.filter { !requiredTags.isDisjoint(with: Set($0.tags)) }
        }

        return Array(filtered.prefix(limit))
    }

    func suggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] { [] }
    func recordSuccessfulQuery(_ query: String) throws {}
    func indexAllContent() throws {}
    func indexInventoryItem(_ item: InventoryItem) throws {}
    func indexChecklistTemplate(_ template: ChecklistTemplate) throws {}
    func indexNote(_ note: NoteRecord) throws {}
    func indexHandbookSection(_ section: HandbookSection, chapterTitle: String) throws {}
    func indexQuickCard(_ card: QuickCard) throws {}
    func indexImportedChunk(_ chunk: KnowledgeChunk, sourceTitle: String, publisherDomain: String) throws {}
    func removeFromIndex(id: UUID) throws {}
}

struct StubClassifier: SensitivityClassifier {
    let result: SensitivityResult
    func classify(_ query: String) -> SensitivityResult { result }
}

struct StubCapabilityDetector: CapabilityDetector {
    let mode: AnswerMode
    func detectAnswerMode() -> AnswerMode { mode }
}

struct StubAnswerGenerator: GroundedAnswerGenerator {
    let generatedText: String
    var shouldFail: Bool = false

    func generate(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        confidence: ConfidenceLevel,
        context: RetrievalContext?
    ) async throws -> String {
        if shouldFail {
            throw StubGeneratorError.simulatedFailure
        }
        return generatedText
    }

    enum StubGeneratorError: Error {
        case simulatedFailure
    }
}
