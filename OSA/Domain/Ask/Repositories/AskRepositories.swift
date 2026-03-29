import Foundation

// MARK: - Retrieval Service Protocol

protocol RetrievalService {
    /// Submit a user query and get a grounded retrieval outcome.
    func retrieve(
        query: String,
        scopes: Set<RetrievalScope>?,
        context: RetrievalContext?
    ) async throws -> RetrievalOutcome
}

extension RetrievalService {
    func retrieve(query: String, scopes: Set<RetrievalScope>?) async throws -> RetrievalOutcome {
        try await retrieve(query: query, scopes: scopes, context: nil)
    }
}

// MARK: - Sensitivity Classifier Protocol

protocol SensitivityClassifier {
    /// Classify whether a query touches a blocked or sensitive scope.
    func classify(_ query: String) -> SensitivityResult
}

enum SensitivityResult: Equatable, Sendable {
    case allowed
    case sensitiveStaticOnly(reason: String)
    case blocked(reason: String)
}

// MARK: - Capability Detector Protocol

protocol CapabilityDetector {
    /// Detect the current device answer mode.
    func detectAnswerMode() -> AnswerMode
}

// MARK: - Grounded Answer Generator Protocol

protocol GroundedAnswerGenerator {
    /// Generate a grounded answer from retrieved evidence using on-device generation.
    /// Called only when the device supports grounded generation.
    /// Callers must handle failures by falling back to extractive assembly.
    func generate(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        confidence: ConfidenceLevel,
        context: RetrievalContext?
    ) async throws -> String
}

extension GroundedAnswerGenerator {
    func generate(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        confidence: ConfidenceLevel
    ) async throws -> String {
        try await generate(
            query: query,
            evidence: evidence,
            citations: citations,
            confidence: confidence,
            context: nil
        )
    }
}
