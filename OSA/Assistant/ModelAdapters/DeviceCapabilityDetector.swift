import Foundation

struct DeviceCapabilityDetector: CapabilityDetector {
    func detectAnswerMode() -> AnswerMode {
        // Foundation Models availability check
        // In iOS 26+, use FoundationModels.SystemLanguageModel.default.availability
        // For now, default to extractive-only since Foundation Models API
        // requires runtime capability detection that we wire in Phase M3P3.
        if isFoundationModelsAvailable() {
            return .groundedGeneration
        } else {
            return .extractiveOnly
        }
    }

    private func isFoundationModelsAvailable() -> Bool {
        // Placeholder: actual detection requires FoundationModels framework import
        // and checking SystemLanguageModel.default.availability at runtime.
        // This will be wired when the model adapter layer is built.
        // For now, default to false so the extractive path gets exercised first.
        false
    }
}
