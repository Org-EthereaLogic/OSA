import XCTest
@testable import OSA

final class CapabilityDetectionTests: XCTestCase {

    // MARK: - DeviceCapabilityDetector Tests

    func testDetectorReturnsExtractiveOnCurrentPlatform() {
        // On the current SDK/simulator (no FoundationModels), the detector
        // should return extractiveOnly since #if canImport(FoundationModels) is false.
        let detector = DeviceCapabilityDetector()
        let mode = detector.detectAnswerMode()
        XCTAssertEqual(mode, .extractiveOnly)
    }

    // MARK: - Stub Capability Detector Tests

    func testStubDetectorReturnsGroundedGeneration() {
        let detector = StubCapabilityDetector(mode: .groundedGeneration)
        XCTAssertEqual(detector.detectAnswerMode(), .groundedGeneration)
    }

    func testStubDetectorReturnsExtractiveOnly() {
        let detector = StubCapabilityDetector(mode: .extractiveOnly)
        XCTAssertEqual(detector.detectAnswerMode(), .extractiveOnly)
    }

    func testStubDetectorReturnsSearchResultsOnly() {
        let detector = StubCapabilityDetector(mode: .searchResultsOnly)
        XCTAssertEqual(detector.detectAnswerMode(), .searchResultsOnly)
    }

    // MARK: - Adapter Routing: Grounded Generation Path

    func testGroundedGenerationCallsAdapter() async throws {
        let generatedText = "Based on your handbook [1], store one gallon of water per person."
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "Water Storage",
                         snippet: "Store one gallon per person per day.", score: 5.0, tags: []),
        ]
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .groundedGeneration),
            answerGenerator: StubAnswerGenerator(generatedText: generatedText)
        )

        let outcome = try await service.retrieve(query: "water storage", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.answerMode, .groundedGeneration)
            XCTAssertEqual(result.answerText, generatedText)
            XCTAssertFalse(result.citations.isEmpty, "Citations must be preserved with generation")
        } else {
            XCTFail("Expected answered outcome, got \(outcome)")
        }
    }

    // MARK: - Adapter Routing: Extractive Fallback Path

    func testExtractivePathStillWorksWithoutGenerator() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "Shelter",
                         snippet: "Build a lean-to shelter using branches.", score: 5.0, tags: []),
        ]
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .extractiveOnly)
            // No answerGenerator — extractive path
        )

        let outcome = try await service.retrieve(query: "shelter building", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.answerMode, .extractiveOnly)
            XCTAssertTrue(result.answerText.contains("lean-to"))
            XCTAssertFalse(result.citations.isEmpty)
        } else {
            XCTFail("Expected answered outcome, got \(outcome)")
        }
    }

    // MARK: - Adapter Routing: Generation Failure Falls Back to Extractive

    func testGenerationFailureFallsBackToExtractive() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "Fire Safety",
                         snippet: "Keep a fire extinguisher accessible.", score: 5.0, tags: []),
        ]
        let failingGenerator = StubAnswerGenerator(
            generatedText: "",
            shouldFail: true
        )
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .groundedGeneration),
            answerGenerator: failingGenerator
        )

        let outcome = try await service.retrieve(query: "fire safety", scopes: nil)

        if case .answered(let result) = outcome {
            // Should fall back to extractive text, not fail entirely
            XCTAssertEqual(result.answerMode, .groundedGeneration)
            XCTAssertTrue(result.answerText.contains("fire extinguisher"),
                          "Should fall back to extractive snippet on generation failure")
            XCTAssertFalse(result.citations.isEmpty)
        } else {
            XCTFail("Expected answered outcome even after generation failure, got \(outcome)")
        }
    }

    // MARK: - Adapter Routing: No Generator with Grounded Mode

    func testGroundedModeWithoutGeneratorFallsBackToExtractive() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .quickCard, title: "Emergency Kit",
                         snippet: "Pack a 72-hour emergency kit.", score: 4.0, tags: []),
        ]
        // Detector says grounded, but no generator injected
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .groundedGeneration)
            // No answerGenerator
        )

        let outcome = try await service.retrieve(query: "emergency kit", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.answerMode, .groundedGeneration)
            XCTAssertTrue(result.answerText.contains("72-hour"),
                          "Should use extractive assembly when no generator is available")
        } else {
            XCTFail("Expected answered outcome, got \(outcome)")
        }
    }

    // MARK: - Citation Integrity Across Both Paths

    func testCitationIntegrityInGroundedPath() async throws {
        let fixedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let results = [
            SearchResult(id: fixedID, kind: .handbookSection, title: "Navigation",
                         snippet: "Use a compass and map.", score: 5.0, tags: []),
        ]
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .groundedGeneration),
            answerGenerator: StubAnswerGenerator(generatedText: "Use a compass and map [1].")
        )

        let outcome = try await service.retrieve(query: "navigation", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.citations.count, 1)
            XCTAssertEqual(result.citations.first?.id, fixedID)
            XCTAssertEqual(result.citations.first?.kind, .handbookSection)
            XCTAssertEqual(result.evidence.first?.id, fixedID)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    func testCitationIntegrityInExtractivePath() async throws {
        let fixedID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let results = [
            SearchResult(id: fixedID, kind: .quickCard, title: "Water Purification",
                         snippet: "Boil water for at least one minute.", score: 5.0, tags: []),
        ]
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .extractiveOnly)
        )

        let outcome = try await service.retrieve(query: "purify water", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.citations.count, 1)
            XCTAssertEqual(result.citations.first?.id, fixedID)
            XCTAssertEqual(result.citations.first?.kind, .quickCard)
            XCTAssertEqual(result.evidence.first?.id, fixedID)
        } else {
            XCTFail("Expected answered outcome")
        }
    }

    // MARK: - Search Results Only Mode

    func testSearchResultsOnlyMode() async throws {
        let results = [
            SearchResult(id: UUID(), kind: .handbookSection, title: "Flood",
                         snippet: "Flood safety info.", score: 5.0, tags: []),
        ]
        let service = LocalRetrievalService(
            searchService: StubSearchService(results: results),
            sensitivityClassifier: StubClassifier(result: .allowed),
            capabilityDetector: StubCapabilityDetector(mode: .searchResultsOnly)
        )

        let outcome = try await service.retrieve(query: "flood", scopes: nil)

        if case .answered(let result) = outcome {
            XCTAssertEqual(result.answerMode, .searchResultsOnly)
            XCTAssertTrue(result.answerText.contains("most relevant local sources"))
        } else {
            XCTFail("Expected answered outcome")
        }
    }
}
