import Foundation

// MARK: - Retrieval Service Protocol

protocol RetrievalService {
    /// Submit a user query and get a grounded retrieval outcome.
    func retrieve(query: String, scopes: Set<RetrievalScope>?) throws -> RetrievalOutcome
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
