import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Concrete inventory completion service that prefers on-device Foundation
/// Models structured output when available and falls back to deterministic
/// heuristics otherwise.
///
/// This service never performs networking, persistence writes, or reads
/// from unrelated personal records. It operates only on the partial form
/// input provided in the request.
struct LocalInventoryCompletionService: InventoryCompletionService {

    private nonisolated(unsafe) let capabilityDetector: any CapabilityDetector

    init(capabilityDetector: any CapabilityDetector) {
        self.capabilityDetector = capabilityDetector
    }

    func suggest(for request: InventoryCompletionRequest) async -> InventoryCompletionSuggestion {
        let trimmedName = request.name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return .empty }

        #if canImport(FoundationModels)
        if capabilityDetector.detectAnswerMode() == .groundedGeneration {
            if let fmSuggestion = await attemptFMCompletion(for: request, name: trimmedName) {
                return fmSuggestion
            }
        }
        #endif

        return heuristicSuggestion(for: request, name: trimmedName)
    }

    // MARK: - Foundation Models Path

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    @Generable
    struct InventoryFMOutput {
        @Guide(description: "The most likely inventory category from: water, food, power, first-aid, lighting, communication, shelter, tools, sanitation, documents, clothing, other")
        var suggestedCategory: String?

        @Guide(description: "The numeric quantity parsed or inferred from the input")
        var suggestedQuantity: Int?

        @Guide(description: "The unit of measure such as gallons, cans, boxes, or packs")
        var suggestedUnit: String?

        @Guide(description: "The storage location parsed or inferred from the input such as garage, basement, or closet")
        var suggestedLocation: String?
    }

    private func attemptFMCompletion(
        for request: InventoryCompletionRequest,
        name: String
    ) async -> InventoryCompletionSuggestion? {
        guard #available(iOS 26, *) else { return nil }

        let prompt = """
        You are an inventory assistant for an emergency preparedness app. \
        Given a partial inventory item description, extract structured fields.

        Item text: "\(name)"

        Extract:
        - category: one of water, food, power, first-aid, lighting, communication, shelter, tools, sanitation, documents, clothing, other
        - quantity: a numeric count if present
        - unit: the unit of measure if present (e.g., gallons, cans, boxes, batteries)
        - location: storage location if mentioned (e.g., garage, basement, closet)

        Only include fields that are clearly supported by the input. \
        Do not guess or invent information.
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: prompt,
                generating: InventoryFMOutput.self
            )
            return mapFMOutput(response.content, request: request)
        } catch {
            return nil
        }
    }

    @available(iOS 26, *)
    private func mapFMOutput(
        _ output: InventoryFMOutput,
        request: InventoryCompletionRequest
    ) -> InventoryCompletionSuggestion {
        let category: InventoryCategory? = output.suggestedCategory
            .flatMap { parseCategoryString($0) }

        return InventoryCompletionSuggestion(
            category: category,
            quantity: output.suggestedQuantity,
            unit: output.suggestedUnit,
            location: output.suggestedLocation
        )
    }
    #endif

    // MARK: - Heuristic Fallback

    func heuristicSuggestion(
        for request: InventoryCompletionRequest,
        name: String
    ) -> InventoryCompletionSuggestion {
        let lower = name.lowercased()
        let tokens = lower.split(separator: " ").map(String.init)

        let category = inferCategory(from: lower, tokens: tokens)
        let parsed = parseQuantityAndUnit(from: tokens)
        let location = inferLocation(from: lower, tokens: tokens)

        let hasAnySuggestion = category != nil
            || parsed.quantity != nil
            || parsed.unit != nil
            || location != nil

        guard hasAnySuggestion else { return .empty }

        return InventoryCompletionSuggestion(
            category: category,
            quantity: parsed.quantity,
            unit: parsed.unit,
            location: location
        )
    }

    // MARK: - Category Inference

    private func inferCategory(from lower: String, tokens: [String]) -> InventoryCategory? {
        let categoryKeywords: [(keywords: [String], category: InventoryCategory)] = [
            (["water", "h2o", "aqua"], .water),
            (["food", "canned", "mre", "ration", "granola", "rice", "beans", "pasta",
              "freeze-dried", "freeze dried"], .food),
            (["battery", "batteries", "generator", "solar", "charger", "power bank",
              "powerbank"], .power),
            (["first aid", "med kit", "medkit", "bandage", "gauze", "antiseptic",
              "ibuprofen", "aspirin", "tylenol", "first-aid"], .firstAid),
            (["flashlight", "lantern", "headlamp", "candle", "glow stick",
              "glowstick"], .lighting),
            (["radio", "walkie", "ham radio", "scanner", "whistle"], .communication),
            (["tent", "tarp", "sleeping bag", "blanket", "poncho"], .shelter),
            (["knife", "axe", "hatchet", "saw", "duct tape", "rope", "paracord",
              "multi-tool", "multitool", "wrench", "pliers"], .tools),
            (["soap", "sanitizer", "bleach", "toilet", "wipes", "trash bag",
              "hygiene"], .sanitation),
            (["document", "passport", "license", "insurance", "map", "id card",
              "certificate"], .documents),
            (["jacket", "boots", "gloves", "socks", "hat", "coat",
              "rain gear"], .clothing),
        ]

        for (keywords, category) in categoryKeywords {
            for keyword in keywords {
                if keyword.contains(" ") {
                    if lower.contains(keyword) { return category }
                } else {
                    if tokens.contains(keyword) { return category }
                }
            }
        }
        return nil
    }

    // MARK: - Quantity and Unit Parsing

    private func parseQuantityAndUnit(
        from tokens: [String]
    ) -> (quantity: Int?, unit: String?) {
        guard let first = tokens.first, let number = Int(first), number > 0 else {
            return (nil, nil)
        }

        let remaining = tokens.dropFirst()
        let knownUnits = [
            "gallon", "gallons", "gal",
            "can", "cans",
            "box", "boxes",
            "bottle", "bottles",
            "pack", "packs",
            "bag", "bags",
            "roll", "rolls",
            "pair", "pairs",
            "kit", "kits",
            "lb", "lbs", "pound", "pounds",
            "oz", "ounce", "ounces",
            "liter", "liters", "litre", "litres",
            "case", "cases",
            "set", "sets",
        ]

        // Find the first recognized unit token in the remaining words
        for (index, token) in remaining.enumerated() {
            if knownUnits.contains(token) {
                let unit = remaining.prefix(index + 1).joined(separator: " ")
                return (number, unit)
            }
        }

        // No recognized unit but we have a number — return just the quantity
        // if there are description tokens that could imply items
        if !remaining.isEmpty {
            return (number, nil)
        }

        return (number, nil)
    }

    // MARK: - Location Inference

    private func inferLocation(from lower: String, tokens: [String]) -> String? {
        let locationKeywords: [(keyword: String, display: String)] = [
            ("garage", "Garage"),
            ("basement", "Basement"),
            ("attic", "Attic"),
            ("hall closet", "Hall Closet"),
            ("closet", "Closet"),
            ("pantry", "Pantry"),
            ("shed", "Shed"),
            ("car", "Car"),
            ("trunk", "Trunk"),
            ("kitchen", "Kitchen"),
            ("bathroom", "Bathroom"),
            ("bedroom", "Bedroom"),
            ("laundry", "Laundry Room"),
            ("under stairs", "Under Stairs"),
            ("go bag", "Go Bag"),
            ("bug out", "Bug Out Bag"),
        ]

        for (keyword, display) in locationKeywords {
            if keyword.contains(" ") {
                if lower.contains(keyword) { return display }
            } else {
                if tokens.contains(keyword) { return display }
            }
        }
        return nil
    }

    // MARK: - Category String Parsing

    private func parseCategoryString(_ string: String) -> InventoryCategory? {
        let normalized = string.lowercased().trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "water": return .water
        case "food": return .food
        case "power": return .power
        case "first-aid", "first aid", "firstaid": return .firstAid
        case "lighting": return .lighting
        case "communication": return .communication
        case "shelter": return .shelter
        case "tools": return .tools
        case "sanitation": return .sanitation
        case "documents": return .documents
        case "clothing": return .clothing
        case "other": return .other
        default: return nil
        }
    }
}

// MARK: - Merge Logic

/// Applies completion suggestions to form values using conservative merge rules.
///
/// Rules:
/// - Blank `unit` and blank `location` may be populated by suggestions.
/// - `category == .other` may be replaced by a concrete suggestion.
/// - `quantity == 1` may be replaced only if the suggestion provides a parsed value.
/// - Non-empty text fields and non-default values are never overwritten.
struct InventoryCompletionMerger {

    struct FormState {
        var category: InventoryCategory
        var quantity: Int
        var unit: String
        var location: String
    }

    static func merge(
        suggestion: InventoryCompletionSuggestion,
        into state: FormState
    ) -> FormState {
        var result = state

        if let suggestedCategory = suggestion.category,
           state.category == .other {
            result.category = suggestedCategory
        }

        if let suggestedQuantity = suggestion.quantity,
           suggestedQuantity > 0,
           state.quantity == 1 {
            result.quantity = suggestedQuantity
        }

        if let suggestedUnit = suggestion.unit,
           !suggestedUnit.isEmpty,
           state.unit.trimmingCharacters(in: .whitespaces).isEmpty {
            result.unit = suggestedUnit
        }

        if let suggestedLocation = suggestion.location,
           !suggestedLocation.isEmpty,
           state.location.trimmingCharacters(in: .whitespaces).isEmpty {
            result.location = suggestedLocation
        }

        return result
    }
}
