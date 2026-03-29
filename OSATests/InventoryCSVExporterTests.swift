import Foundation
import XCTest
@testable import OSA

final class InventoryCSVExporterTests: XCTestCase {
    func testCSVIncludesStableHeadersAndEscapesSpecialCharacters() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let item = InventoryItem(
            id: UUID(),
            name: #"Water, "Emergency""#,
            category: .water,
            quantity: 4,
            unit: "gallons",
            location: "Garage",
            notes: "Line one\nLine two",
            expiryDate: Date(timeIntervalSince1970: 1_700_086_400),
            reorderThreshold: 2,
            tags: ["rotation", "family"],
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )

        let csv = InventoryCSVExporter.csvString(for: [item])

        XCTAssertTrue(csv.hasPrefix(InventoryCSVExporter.headers.joined(separator: ",")))
        XCTAssertTrue(csv.contains(#""Water, ""Emergency"""#))
        XCTAssertTrue(csv.contains("\"Line one\nLine two\""))
        XCTAssertTrue(csv.contains("rotation; family"))
    }

    func testExportFileWritesCSVToTemporaryLocation() throws {
        let item = InventoryItem(
            id: UUID(),
            name: "Water Jug",
            category: .water,
            quantity: 2,
            unit: "gallons",
            location: "",
            notes: "",
            expiryDate: nil,
            reorderThreshold: nil,
            tags: [],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isArchived: false
        )

        let url = try InventoryCSVExporter.exportFile(for: [item], filename: "inventory-export-test.csv")
        defer { try? FileManager.default.removeItem(at: url) }

        let contents = try String(contentsOf: url, encoding: .utf8)

        XCTAssertEqual(contents, InventoryCSVExporter.csvString(for: [item]))
    }
}
