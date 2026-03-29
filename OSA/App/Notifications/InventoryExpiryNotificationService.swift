import Foundation
@preconcurrency import UserNotifications

enum InventoryNotificationAuthorizationStatus: String, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var canSchedule: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Requested"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        }
    }

    var detailText: String {
        switch self {
        case .notDetermined:
            return "Turn reminders on to request local notification permission."
        case .denied:
            return "Notifications are currently off for OSA. You can re-enable them in iPhone Settings."
        case .authorized, .provisional, .ephemeral:
            return "Reminders stay on this device and are scheduled from your local inventory only."
        }
    }
}

@MainActor
protocol InventoryExpiryNotificationServicing: AnyObject {
    func authorizationStatus() async -> InventoryNotificationAuthorizationStatus
    func requestAuthorization() async throws -> InventoryNotificationAuthorizationStatus
    func rescheduleNotifications() async throws
}

@MainActor
protocol InventoryNotificationCenterClient {
    func authorizationStatus() async -> InventoryNotificationAuthorizationStatus
    func requestAuthorization() async throws -> InventoryNotificationAuthorizationStatus
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

struct UserNotificationCenterClient: InventoryNotificationCenterClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> InventoryNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return Self.mapAuthorizationStatus(settings.authorizationStatus)
    }

    func requestAuthorization() async throws -> InventoryNotificationAuthorizationStatus {
        _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return await authorizationStatus()
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private static func mapAuthorizationStatus(
        _ status: UNAuthorizationStatus
    ) -> InventoryNotificationAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .denied
        }
    }
}

@MainActor
final class InventoryExpiryNotificationService: InventoryExpiryNotificationServicing {
    static let identifierPrefix = "inventory-expiry"

    private let notificationCenterClient: any InventoryNotificationCenterClient
    private let inventoryRepository: any InventoryRepository
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        notificationCenterClient: any InventoryNotificationCenterClient = UserNotificationCenterClient(),
        inventoryRepository: any InventoryRepository,
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.notificationCenterClient = notificationCenterClient
        self.inventoryRepository = inventoryRepository
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func authorizationStatus() async -> InventoryNotificationAuthorizationStatus {
        await notificationCenterClient.authorizationStatus()
    }

    func requestAuthorization() async throws -> InventoryNotificationAuthorizationStatus {
        try await notificationCenterClient.requestAuthorization()
    }

    func rescheduleNotifications() async throws {
        await clearPendingInventoryNotifications()

        guard userDefaults.object(forKey: InventoryAlertSettings.isEnabledKey) as? Bool ?? InventoryAlertSettings.isEnabledDefault else {
            return
        }

        let status = await notificationCenterClient.authorizationStatus()
        guard status.canSchedule else { return }

        let leadTime = InventoryAlertSettings.leadTime(
            from: userDefaults.object(forKey: InventoryAlertSettings.leadTimeKey) as? Int ?? InventoryAlertSettings.leadTimeDefault.rawValue
        )

        let now = Date()
        let items = try inventoryRepository.itemsExpiringSoon(within: leadTime.days)

        for item in items {
            guard let request = makeRequest(for: item, leadTime: leadTime, now: now) else {
                continue
            }

            try await notificationCenterClient.add(request)
        }
    }

    static func notificationIdentifier(for itemID: UUID) -> String {
        "\(identifierPrefix).\(itemID.uuidString.lowercased())"
    }

    private func clearPendingInventoryNotifications() async {
        let existing = await notificationCenterClient.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
            .map(\.identifier)

        guard !existing.isEmpty else { return }

        notificationCenterClient.removePendingNotificationRequests(withIdentifiers: existing)
        notificationCenterClient.removeDeliveredNotifications(withIdentifiers: existing)
    }

    private func makeRequest(
        for item: InventoryItem,
        leadTime: InventoryAlertLeadTime,
        now: Date
    ) -> UNNotificationRequest? {
        guard let expiryDate = item.expiryDate, expiryDate > now, !item.isArchived else {
            return nil
        }

        let scheduledDate = scheduledReminderDate(
            for: expiryDate,
            leadTime: leadTime,
            now: now
        )
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )

        let content = UNMutableNotificationContent()
        content.title = "\(item.name) expires soon"
        content.body = "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted)). Review or replace it in Inventory."
        content.sound = .default
        content.threadIdentifier = Self.identifierPrefix
        content.userInfo = ["inventoryItemID": item.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: Self.notificationIdentifier(for: item.id),
            content: content,
            trigger: trigger
        )
    }

    private func scheduledReminderDate(
        for expiryDate: Date,
        leadTime: InventoryAlertLeadTime,
        now: Date
    ) -> Date {
        let preferredDate = calendar.date(byAdding: .day, value: -leadTime.days, to: expiryDate) ?? expiryDate
        if preferredDate > now {
            return preferredDate
        }

        return calendar.date(byAdding: .minute, value: 1, to: now) ?? now.addingTimeInterval(60)
    }
}
