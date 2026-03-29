import Foundation

enum InventoryCSVExporter {
    static let headers = [
        "Name",
        "Category",
        "Quantity",
        "Unit",
        "Location",
        "Notes",
        "Expiry Date",
        "Reorder Threshold",
        "Tags",
        "Archived",
        "Created At",
        "Updated At"
    ]

    static func csvString(for items: [InventoryItem]) -> String {
        let rows = [headers] + items.map(row(for:))
        return rows
            .map { $0.map(escapedField(_:)).joined(separator: ",") }
            .joined(separator: "\n")
    }

    static func exportFile(
        for items: [InventoryItem],
        filename: String = "inventory-export.csv"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let csv = csvString(for: items)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func row(for item: InventoryItem) -> [String] {
        [
            item.name,
            displayName(for: item.category),
            String(item.quantity),
            item.unit,
            item.location,
            item.notes,
            item.expiryDate.map(formatExpiryDate(_:)) ?? "",
            item.reorderThreshold.map(String.init) ?? "",
            item.tags.joined(separator: "; "),
            item.isArchived ? "true" : "false",
            formatTimestamp(item.createdAt),
            formatTimestamp(item.updatedAt)
        ]
    }

    private static func escapedField(_ field: String) -> String {
        guard field.contains(",") || field.contains("\n") || field.contains("\"") else {
            return field
        }

        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func displayName(for category: InventoryCategory) -> String {
        switch category {
        case .water:
            return "Water"
        case .food:
            return "Food"
        case .power:
            return "Power"
        case .firstAid:
            return "First Aid"
        case .lighting:
            return "Lighting"
        case .communication:
            return "Communication"
        case .shelter:
            return "Shelter"
        case .tools:
            return "Tools"
        case .sanitation:
            return "Sanitation"
        case .documents:
            return "Documents"
        case .clothing:
            return "Clothing"
        case .other:
            return "Other"
        }
    }

    private static func formatExpiryDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private static func formatTimestamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
