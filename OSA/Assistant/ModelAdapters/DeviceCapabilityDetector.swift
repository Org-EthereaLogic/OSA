import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct DeviceCapabilityDetector: CapabilityDetector {
    func detectAnswerMode() -> AnswerMode {
        if isFoundationModelsAvailable() {
            return .groundedGeneration
        } else {
            return .extractiveOnly
        }
    }

    private func isFoundationModelsAvailable() -> Bool {
        #if canImport(FoundationModels)
        return Self.checkModelAvailability()
        #else
        return false
        #endif
    }

    #if canImport(FoundationModels)
    private static func checkModelAvailability() -> Bool {
        // FoundationModels requires iOS 26+ at runtime even when the SDK
        // is present. Guard with @available before touching any FM type.
        if #available(iOS 26, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return true
            default:
                return false
            }
        }
        return false
    }
    #endif
}
