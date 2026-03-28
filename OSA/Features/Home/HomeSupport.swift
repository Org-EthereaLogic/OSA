import Foundation

func buildHomeInventoryReminders(
    expiring: [InventoryItem],
    lowStock: [InventoryItem]
) -> [HomeInventoryReminder] {
    let now = Date()
    var reminders: [UUID: HomeInventoryReminder] = [:]

    for item in expiring {
        guard let expiryDate = item.expiryDate else { continue }
        let detail = expiryDate < now
            ? "Expired \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
            : "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
        let priority = expiryDate < now ? 0 : 1

        reminders[item.id] = HomeInventoryReminder(
            itemID: item.id,
            title: item.name,
            detail: detail,
            priority: priority
        )
    }

    for item in lowStock {
        let detail: String
        if let threshold = item.reorderThreshold {
            detail = "Low stock: \(item.quantity) \(item.unit) left, reorder at \(threshold)"
        } else {
            detail = "Low stock: \(item.quantity) \(item.unit) left"
        }

        if var existing = reminders[item.id] {
            existing.detail += " | \(detail)"
            existing.priority = min(existing.priority, 2)
            reminders[item.id] = existing
        } else {
            reminders[item.id] = HomeInventoryReminder(
                itemID: item.id,
                title: item.name,
                detail: detail,
                priority: 2
            )
        }
    }

    return reminders.values.sorted { lhs, rhs in
        if lhs.priority == rhs.priority {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhs.priority < rhs.priority
    }
}

func evaluateSupplyReadiness(
    template: SupplyTemplate,
    inventory: [InventoryItem],
    householdSize: Int
) -> SupplyReadinessSnapshot {
    var completedScore = 0.0
    var missingCriticalCount = 0
    var nearExpiryCount = 0

    for templateItem in template.items {
        let targetQuantity = templateItem.targetQuantity * (templateItem.scalesWithHouseholdSize ? householdSize : 1)
        let matches = inventory.filter { item in
            guard item.category == templateItem.inventoryCategory else { return false }
            let searchableText = "\(item.name) \(item.notes) \(item.location)".lowercased()
            return templateItem.matchKeywords.isEmpty
                || templateItem.matchKeywords.contains { searchableText.contains($0.lowercased()) }
        }

        let matchedQuantity = matches.reduce(0) { $0 + $1.quantity }
        completedScore += min(Double(matchedQuantity) / Double(max(targetQuantity, 1)), 1.0)

        if templateItem.isCritical && matchedQuantity < targetQuantity {
            missingCriticalCount += 1
        }

        nearExpiryCount += matches.filter {
            guard let expiryDate = $0.expiryDate else { return false }
            return expiryDate <= Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? .distantFuture
        }.count
    }

    let readinessPercent = Int((completedScore / Double(max(template.items.count, 1))) * 100.0)
    return SupplyReadinessSnapshot(
        title: template.title,
        scenario: template.scenario,
        readinessPercent: readinessPercent,
        missingCriticalCount: missingCriticalCount,
        nearExpiryCount: nearExpiryCount
    )
}

func homeCurrentSeasonTag(for date: Date = Date(), calendar: Calendar = .current) -> String {
    let month = calendar.component(.month, from: date)
    switch month {
    case 3...5:
        return "season:spring"
    case 6...8:
        return "season:summer"
    case 9...11:
        return "season:fall"
    default:
        return "season:winter"
    }
}

func formatHomeTagText(_ rawTag: String) -> String {
    rawTag
        .replacingOccurrences(of: "scenario:", with: "")
        .replacingOccurrences(of: "season:", with: "")
        .replacingOccurrences(of: "region:", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .split(separator: " ")
        .map { $0.capitalized }
        .joined(separator: " ")
}
