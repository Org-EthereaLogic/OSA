import XCTest
@testable import OSA

final class SensitivityPolicyTests: XCTestCase {
    private let policy = SensitivityPolicy()

    func testAllowedQuery() {
        let result = policy.classify("how do I store water")
        XCTAssertEqual(result, .allowed)
    }

    func testBlocksHuntingQuery() {
        let result = policy.classify("how to hunt deer")
        if case .blocked(let reason) = result {
            XCTAssertTrue(reason.contains("hunting"))
        } else {
            XCTFail("Expected blocked result")
        }
    }

    func testBlocksForagingQuery() {
        let result = policy.classify("identify edible mushrooms")
        if case .blocked(let reason) = result {
            XCTAssertTrue(reason.contains("plant"))
        } else {
            XCTFail("Expected blocked result")
        }
    }

    func testBlocksMedicalDosageQuery() {
        let result = policy.classify("what dosage of ibuprofen")
        if case .blocked(let reason) = result {
            XCTAssertTrue(reason.contains("Medical"))
        } else {
            XCTFail("Expected blocked result")
        }
    }

    func testSensitiveFirstAidQuery() {
        let result = policy.classify("how to apply a tourniquet")
        if case .sensitiveStaticOnly(let reason) = result {
            XCTAssertTrue(reason.contains("first-aid"))
        } else {
            XCTFail("Expected sensitiveStaticOnly result")
        }
    }

    func testSensitiveGasLeakQuery() {
        let result = policy.classify("what to do during a gas leak")
        if case .sensitiveStaticOnly(let reason) = result {
            XCTAssertTrue(reason.contains("hazard"))
        } else {
            XCTFail("Expected sensitiveStaticOnly result")
        }
    }
}
