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
/// Prompt shaping is intentionally minimal here. M3P5 will introduce a
/// dedicated prompt-shaping layer with style, tone, and safety-template
/// refinements.
@available(iOS 26, *)
struct FoundationModelAdapter: GroundedAnswerGenerator {
    func generate(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        confidence: ConfidenceLevel
    ) async throws -> String {
        let session = LanguageModelSession()
        let prompt = buildPrompt(query: query, evidence: evidence, confidence: confidence)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: - Prompt Building

    /// Builds a minimal grounded prompt from retrieved evidence.
    /// M3P5 will replace this with a full prompt-shaping layer that
    /// includes style constraints, safety templates, and structured output.
    private func buildPrompt(
        query: String,
        evidence: [EvidenceItem],
        confidence: ConfidenceLevel
    ) -> String {
        var lines: [String] = []

        lines.append("You are a preparedness handbook assistant.")
        lines.append("Answer the following question using ONLY the provided evidence.")
        lines.append("Do not use prior knowledge. If the evidence is insufficient, say so.")
        lines.append("Cite evidence by number in square brackets.")
        lines.append("")
        lines.append("Question: \(query)")
        lines.append("")
        lines.append("Evidence:")
        for (index, item) in evidence.enumerated() {
            lines.append("[\(index + 1)] \(item.title): \(item.snippet)")
        }
        lines.append("")

        switch confidence {
        case .groundedHigh:
            lines.append("Multiple approved sources support this answer. Provide a clear, confident response.")
        case .groundedMedium:
            lines.append("Limited evidence is available. Provide a concise response and note the limitation.")
        case .insufficientLocalEvidence:
            lines.append("Evidence is insufficient. State that clearly.")
        }

        return lines.joined(separator: "\n")
    }
}
#endif
