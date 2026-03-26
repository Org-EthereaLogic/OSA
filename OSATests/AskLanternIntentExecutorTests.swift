import XCTest
@testable import OSA

@MainActor
final class AskLanternIntentExecutorTests: XCTestCase {

    // MARK: - Answered Outcome

    func testAnsweredOutcomeIncludesAnswerTextAndSources() async {
        let service = StubRetrievalService(outcome: .answered(AnswerResult(
            query: "how to purify water",
            evidence: [],
            citations: [
                CitationReference(id: UUID(), kind: .handbookSection, title: "Water Purification", sourceLabel: "Handbook"),
                CitationReference(id: UUID(), kind: .quickCard, title: "Boil Water", sourceLabel: "Quick Card")
            ],
            confidence: .groundedHigh,
            answerMode: .extractiveOnly,
            answerText: "Boil water for at least one minute.",
            suggestedActions: []
        )))
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "how to purify water")

        XCTAssertFalse(result.isRefusal)
        XCTAssertTrue(result.text.contains("Boil water"))
        XCTAssertTrue(result.text.contains("Sources:"))
        XCTAssertTrue(result.text.contains("Water Purification"))
        XCTAssertTrue(result.text.contains("Boil Water"))
    }

    func testAnsweredWithNoCitationsOmitsSourcesSuffix() async {
        let service = StubRetrievalService(outcome: .answered(AnswerResult(
            query: "test",
            evidence: [],
            citations: [],
            confidence: .groundedMedium,
            answerMode: .extractiveOnly,
            answerText: "Some answer text.",
            suggestedActions: []
        )))
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "test")

        XCTAssertFalse(result.isRefusal)
        XCTAssertFalse(result.text.contains("Sources:"))
    }

    // MARK: - Blocked Query

    func testBlockedQueryReturnsRefusal() async {
        let service = StubRetrievalService(outcome: .refused(.blockedSensitiveScope("Topic is blocked.")))
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "how to hunt deer")

        XCTAssertTrue(result.isRefusal)
        XCTAssertTrue(result.text.contains("outside Lantern's scope"))
    }

    // MARK: - Insufficient Evidence

    func testInsufficientEvidenceReturnsNotFoundLocally() async {
        let service = StubRetrievalService(outcome: .refused(.insufficientEvidence))
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "quantum computing")

        XCTAssertTrue(result.isRefusal)
        XCTAssertTrue(result.text.contains("No relevant content"))
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsRefusal() async {
        let service = StubRetrievalService(outcome: .refused(.emptyQuery))
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "   ")

        XCTAssertTrue(result.isRefusal)
        XCTAssertTrue(result.text.contains("specific question"))
    }

    // MARK: - Service Unavailable

    func testServiceErrorReturnsFallbackMessage() async {
        let service = ThrowingRetrievalService()
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        let result = await executor.execute(question: "how to store water")

        XCTAssertTrue(result.isRefusal)
        XCTAssertTrue(result.text.contains("unavailable"))
    }

    // MARK: - Notes Scope

    func testPersonalNotesExcludedWhenSettingIsFalse() async {
        var capturedScopes: Set<RetrievalScope>?
        let service = CapturingRetrievalService { scopes in
            capturedScopes = scopes
            return .refused(.insufficientEvidence)
        }
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { false })

        _ = await executor.execute(question: "test")

        XCTAssertNotNil(capturedScopes)
        XCTAssertFalse(capturedScopes!.contains(.notes))
    }

    func testPersonalNotesIncludedWhenSettingIsTrue() async {
        var capturedScopes: Set<RetrievalScope>?
        let service = CapturingRetrievalService { scopes in
            capturedScopes = scopes
            return .refused(.insufficientEvidence)
        }
        let executor = AskLanternIntentExecutor(retrievalService: service, includePersonalNotes: { true })

        _ = await executor.execute(question: "test")

        XCTAssertNotNil(capturedScopes)
        XCTAssertTrue(capturedScopes!.contains(.notes))
    }
}

// MARK: - Test Doubles

private final class StubRetrievalService: RetrievalService, @unchecked Sendable {
    let outcome: RetrievalOutcome

    init(outcome: RetrievalOutcome) {
        self.outcome = outcome
    }

    func retrieve(query: String, scopes: Set<RetrievalScope>?) async throws -> RetrievalOutcome {
        outcome
    }
}

private final class ThrowingRetrievalService: RetrievalService, @unchecked Sendable {
    func retrieve(query: String, scopes: Set<RetrievalScope>?) async throws -> RetrievalOutcome {
        throw NSError(domain: "test", code: -1)
    }
}

private final class CapturingRetrievalService: RetrievalService, @unchecked Sendable {
    let handler: (Set<RetrievalScope>?) -> RetrievalOutcome

    init(handler: @escaping (Set<RetrievalScope>?) -> RetrievalOutcome) {
        self.handler = handler
    }

    func retrieve(query: String, scopes: Set<RetrievalScope>?) async throws -> RetrievalOutcome {
        handler(scopes)
    }
}
