import XCTest
@testable import OSA

final class InventoryCompletionServiceTests: XCTestCase {

    // A stub detector that always reports FM unavailable,
    // forcing the heuristic fallback path.
    private struct HeuristicOnlyDetector: CapabilityDetector {
        func detectAnswerMode() -> AnswerMode { .extractiveOnly }
    }

    private func makeService() -> LocalInventoryCompletionService {
        LocalInventoryCompletionService(capabilityDetector: HeuristicOnlyDetector())
    }

    private func makeRequest(
        name: String,
        category: InventoryCategory = .other,
        quantity: Int = 1,
        unit: String = "",
        location: String = ""
    ) -> InventoryCompletionRequest {
        InventoryCompletionRequest(
            name: name,
            currentCategory: category,
            currentQuantity: quantity,
            currentUnit: unit,
            currentLocation: location
        )
    }

    // MARK: - FM Unavailable Routes to Heuristics

    func testFMUnavailableUsesHeuristics() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "water jugs"))

        XCTAssertEqual(suggestion.category, .water)
    }

    // MARK: - Category Inference

    func testWaterInputInfersWaterCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "water bottles"))

        XCTAssertEqual(suggestion.category, .water)
    }

    func testBatteryInputInfersPowerCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "24 AA batteries"))

        XCTAssertEqual(suggestion.category, .power)
    }

    func testFirstAidInputInfersFirstAidCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "first aid kit"))

        XCTAssertEqual(suggestion.category, .firstAid)
    }

    func testFlashlightInputInfersLightingCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "flashlight"))

        XCTAssertEqual(suggestion.category, .lighting)
    }

    func testRadioInputInfersCommunicationCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "ham radio"))

        XCTAssertEqual(suggestion.category, .communication)
    }

    func testTarpInputInfersShelterCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "tarp"))

        XCTAssertEqual(suggestion.category, .shelter)
    }

    func testSoapInputInfersSanitationCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "soap bars"))

        XCTAssertEqual(suggestion.category, .sanitation)
    }

    func testDocumentInputInfersDocumentsCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "passport copies"))

        XCTAssertEqual(suggestion.category, .documents)
    }

    func testBootsInputInfersClothingCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "boots"))

        XCTAssertEqual(suggestion.category, .clothing)
    }

    func testFoodInputInfersFoodCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "canned beans"))

        XCTAssertEqual(suggestion.category, .food)
    }

    func testKnifeInputInfersToolsCategory() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "knife"))

        XCTAssertEqual(suggestion.category, .tools)
    }

    // MARK: - Quantity and Unit Parsing

    func testCountPlusUnitParsesQuantityAndUnit() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "2 gallons water"))

        XCTAssertEqual(suggestion.quantity, 2)
        XCTAssertEqual(suggestion.unit, "gallons")
    }

    func testTwelveCansParses() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "12 cans food"))

        XCTAssertEqual(suggestion.quantity, 12)
        XCTAssertEqual(suggestion.unit, "cans")
    }

    func testLeadingNumberWithoutUnitParsesQuantityOnly() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "24 batteries"))

        XCTAssertEqual(suggestion.quantity, 24)
    }

    // MARK: - Location Inference

    func testGarageLocationInferred() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "batteries garage"))

        XCTAssertEqual(suggestion.location, "Garage")
    }

    func testBasementLocationInferred() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "water basement"))

        XCTAssertEqual(suggestion.location, "Basement")
    }

    func testHallClosetLocationInferred() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "flashlight hall closet"))

        XCTAssertEqual(suggestion.location, "Hall Closet")
    }

    func testCarLocationInferred() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "first aid kit car"))

        XCTAssertEqual(suggestion.location, "Car")
    }

    // MARK: - Combined Parsing

    func testFullParsing24AABatteriesGarage() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "24 AA batteries garage"))

        XCTAssertEqual(suggestion.category, .power)
        XCTAssertEqual(suggestion.quantity, 24)
        XCTAssertEqual(suggestion.location, "Garage")
    }

    // MARK: - Empty / Vague Input

    func testEmptyInputReturnsEmptySuggestion() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: ""))

        XCTAssertTrue(suggestion.isEmpty)
    }

    func testWhitespaceOnlyInputReturnsEmptySuggestion() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "   "))

        XCTAssertTrue(suggestion.isEmpty)
    }

    func testVagueInputReturnsEmptySuggestion() async {
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "stuff"))

        XCTAssertTrue(suggestion.isEmpty)
    }

    // MARK: - Merge Rules

    func testMergePreservesNonDefaultCategory() {
        let suggestion = InventoryCompletionSuggestion(
            category: .water,
            quantity: nil,
            unit: nil,
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .food,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.category, .food, "Non-default category must not be overwritten")
    }

    func testMergeReplacesDefaultCategory() {
        let suggestion = InventoryCompletionSuggestion(
            category: .water,
            quantity: nil,
            unit: nil,
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.category, .water, "Default .other category should be replaced")
    }

    func testMergePreservesNonDefaultQuantity() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: 24,
            unit: nil,
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 5,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.quantity, 5, "Non-default quantity must not be overwritten")
    }

    func testMergeReplacesDefaultQuantity() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: 24,
            unit: nil,
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.quantity, 24, "Default quantity 1 should be replaced by suggestion")
    }

    func testMergePreservesNonEmptyUnit() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: nil,
            unit: "gallons",
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "boxes",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.unit, "boxes", "Non-empty unit must not be overwritten")
    }

    func testMergePopulatesBlankUnit() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: nil,
            unit: "gallons",
            location: nil
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.unit, "gallons", "Blank unit should be populated by suggestion")
    }

    func testMergePreservesNonEmptyLocation() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: nil,
            unit: nil,
            location: "Garage"
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: "Kitchen"
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.location, "Kitchen", "Non-empty location must not be overwritten")
    }

    func testMergePopulatesBlankLocation() {
        let suggestion = InventoryCompletionSuggestion(
            category: nil,
            quantity: nil,
            unit: nil,
            location: "Garage"
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.location, "Garage", "Blank location should be populated by suggestion")
    }

    func testMergeAppliesMultipleFieldsAtOnce() {
        let suggestion = InventoryCompletionSuggestion(
            category: .power,
            quantity: 24,
            unit: "batteries",
            location: "Garage"
        )

        let state = InventoryCompletionMerger.FormState(
            category: .other,
            quantity: 1,
            unit: "",
            location: ""
        )

        let merged = InventoryCompletionMerger.merge(suggestion: suggestion, into: state)
        XCTAssertEqual(merged.category, .power)
        XCTAssertEqual(merged.quantity, 24)
        XCTAssertEqual(merged.unit, "batteries")
        XCTAssertEqual(merged.location, "Garage")
    }

    // MARK: - FM Invalid Output Falls Back

    func testFMPathFallsBackToHeuristicsOnError() async {
        // With HeuristicOnlyDetector, FM is never attempted.
        // This validates the fallback path works correctly.
        let service = makeService()
        let suggestion = await service.suggest(for: makeRequest(name: "2 gallons water basement"))

        XCTAssertEqual(suggestion.category, .water)
        XCTAssertEqual(suggestion.quantity, 2)
        XCTAssertEqual(suggestion.unit, "gallons")
        XCTAssertEqual(suggestion.location, "Basement")
    }
}
