import Foundation

struct SensitivityPolicy: SensitivityClassifier {
    // Keywords that trigger blocked-sensitive-scope refusal
    private static let blockedPatterns: [(keywords: Set<String>, reason: String)] = [
        (["hunt", "hunting", "kill", "combat", "tactical", "weapon"],
         "Tactical, hunting, or combat guidance is outside the app's scope."),
        (["forage", "foraging", "edible", "mushroom", "identify plant"],
         "Edible-plant identification is not provided due to safety risk."),
        (["dosage", "prescribe", "diagnose", "medication dose"],
         "Medical diagnosis and dosage advice are outside the app's scope."),
    ]

    // Keywords that trigger sensitive-static-only (prefer quick cards / static sections)
    private static let sensitivePatterns: [(keywords: Set<String>, reason: String)] = [
        (["first aid", "cpr", "tourniquet", "bleeding", "wound", "burn"],
         "Medical first-aid topics are limited to reviewed static reference content."),
        (["gas leak", "power line", "chemical spill", "electrical"],
         "Emergency hazard topics are limited to reviewed static guidance."),
    ]

    func classify(_ query: String) -> SensitivityResult {
        let lowered = query.lowercased()
        let words = Set(lowered.components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty })

        // Check blocked patterns first
        for pattern in Self.blockedPatterns {
            if !pattern.keywords.isDisjoint(with: words) {
                return .blocked(reason: pattern.reason)
            }
        }

        // Check sensitive-static-only patterns
        for pattern in Self.sensitivePatterns {
            if !pattern.keywords.isDisjoint(with: words) {
                return .sensitiveStaticOnly(reason: pattern.reason)
            }
        }

        return .allowed
    }
}
