import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// Concrete generation adapter that uses Apple Foundation Models for
/// grounded answer synthesis on supported devices (iOS 26+).
///
/// The adapter receives pre-retrieved evidence and citations from the
/// retrieval pipeline and produces grounded prose. It does not perform
/// retrieval or policy checks — those happen upstream in `LocalRetrievalService`.
///
/// Prompt construction is delegated to ``GroundedPromptBuilder``, which
/// encodes grounding rules, citation requirements, style constraints, and
/// safety boundaries into the model input.
@available(iOS 26, *)
struct FoundationModelAdapter: GroundedAnswerGenerator {
    private let promptBuilder = GroundedPromptBuilder()

    func generate(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        confidence: ConfidenceLevel,
        context: RetrievalContext?
    ) async throws -> String {
        let session = LanguageModelSession()
        let groundedPrompt = promptBuilder.build(
            query: query,
            evidence: evidence,
            citations: citations,
            confidence: confidence,
            context: context
        )
        let response = try await session.respond(to: groundedPrompt.fullPrompt)
        return response.content
    }
}
#endif
