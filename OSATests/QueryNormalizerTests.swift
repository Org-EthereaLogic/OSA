import XCTest
@testable import OSA

final class QueryNormalizerTests: XCTestCase {
    func testEmptyQueryReturnsNil() {
        XCTAssertNil(QueryNormalizer.normalize(""))
        XCTAssertNil(QueryNormalizer.normalize("   "))
        XCTAssertNil(QueryNormalizer.normalize("\n\t"))
    }

    func testStopwordsOnlyReturnsNil() {
        XCTAssertNil(QueryNormalizer.normalize("what is the"))
        XCTAssertNil(QueryNormalizer.normalize("how do I"))
    }

    func testBasicNormalization() {
        let result = QueryNormalizer.normalize("How do I store water safely?")
        XCTAssertEqual(result, "store water safely")
    }

    func testPreservesContentWords() {
        let result = QueryNormalizer.normalize("emergency shelter setup")
        XCTAssertEqual(result, "emergency shelter setup")
    }

    func testLowercases() {
        let result = QueryNormalizer.normalize("Water STORAGE Basics")
        XCTAssertEqual(result, "water storage basics")
    }

    func testStripsSpecialCharacters() {
        let result = QueryNormalizer.normalize("first-aid kit supplies???")
        XCTAssertEqual(result, "first aid kit supplies")
    }
}
