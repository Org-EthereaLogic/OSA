import Foundation

enum InventoryAlertLeadTime: Int, CaseIterable, Identifiable, Sendable {
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    var id: Int { rawValue }

    var days: Int { rawValue }

    var displayName: String {
        "\(rawValue) days"
    }
}

enum InventoryAlertSettings {
    static let isEnabledKey = "settings.inventory.expiryAlertsEnabled"
    static let leadTimeKey = "settings.inventory.expiryAlertLeadTimeDays"

    static let isEnabledDefault = false
    static let leadTimeDefault = InventoryAlertLeadTime.thirtyDays

    static func leadTime(from rawValue: Int) -> InventoryAlertLeadTime {
        InventoryAlertLeadTime(rawValue: rawValue) ?? leadTimeDefault
    }
}
