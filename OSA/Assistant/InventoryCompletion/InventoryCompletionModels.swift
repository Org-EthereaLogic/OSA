import Foundation

// MARK: - Service Protocol

/// A service that suggests inventory field values from partial form input.
///
/// Implementations may use on-device Foundation Models or deterministic
/// heuristics. The service never performs networking or persistence writes.
protocol InventoryCompletionService: Sendable {
    func suggest(for request: InventoryCompletionRequest) async -> InventoryCompletionSuggestion
}

// MARK: - Request

/// Captures the current partial state of the inventory form for completion.
struct InventoryCompletionRequest: Equatable, Sendable {
    let name: String
    let currentCategory: InventoryCategory
    let currentQuantity: Int
    let currentUnit: String
    let currentLocation: String
}

// MARK: - Suggestion

/// Typed suggestion output for inventory field completion.
///
/// Each field is optional — `nil` means no suggestion for that field.
/// Consumers apply suggestions using conservative merge rules that never
/// overwrite non-empty or non-default user values automatically.
struct InventoryCompletionSuggestion: Equatable, Sendable {
    let category: InventoryCategory?
    let quantity: Int?
    let unit: String?
    let location: String?

    var isEmpty: Bool {
        category == nil && quantity == nil && unit == nil && location == nil
    }

    static let empty = InventoryCompletionSuggestion(
        category: nil,
        quantity: nil,
        unit: nil,
        location: nil
    )
}
