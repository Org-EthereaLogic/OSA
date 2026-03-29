import Foundation
import UserNotifications
import XCTest
@testable import OSA

@MainActor
final class InventoryExpiryNotificationServiceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: #file)
        defaults.removePersistentDomain(forName: #file)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: #file)
        defaults = nil
        super.tearDown()
    }

    func testRequestAuthorizationReturnsUpdatedStatus() async throws {
        let center = FakeInventoryNotificationCenterClient()
        center.authorizationStatusValue = .notDetermined
        center.requestAuthorizationStatus = .authorized

        let service = InventoryExpiryNotificationService(
            notificationCenterClient: center,
            inventoryRepository: FakeInventoryRepository(),
            userDefaults: defaults
        )

        let status = try await service.requestAuthorization()

        XCTAssertEqual(status, .authorized)
        XCTAssertEqual(center.requestAuthorizationCallCount, 1)
    }

    func testRescheduleUsesLeadTimeSettingAndStableIdentifiers() async throws {
        defaults.set(true, forKey: InventoryAlertSettings.isEnabledKey)
        defaults.set(InventoryAlertLeadTime.thirtyDays.rawValue, forKey: InventoryAlertSettings.leadTimeKey)

        let repo = FakeInventoryRepository()
        repo.items = [
            makeItem(name: "Water Pouch", expiryOffsetDays: 10),
            makeItem(name: "Distant Item", expiryOffsetDays: 45),
            makeItem(name: "Expired Item", expiryOffsetDays: -2)
        ]

        let center = FakeInventoryNotificationCenterClient()
        center.authorizationStatusValue = .authorized
        center.pendingRequestsValue = [
            UNNotificationRequest(
                identifier: InventoryExpiryNotificationService.notificationIdentifier(for: UUID()),
                content: UNMutableNotificationContent(),
                trigger: nil
            ),
            UNNotificationRequest(
                identifier: "unrelated.notification",
                content: UNMutableNotificationContent(),
                trigger: nil
            )
        ]

        let service = InventoryExpiryNotificationService(
            notificationCenterClient: center,
            inventoryRepository: repo,
            userDefaults: defaults
        )

        try await service.rescheduleNotifications()

        XCTAssertEqual(repo.lastExpiringSoonWindow, 30)
        XCTAssertEqual(center.addedRequests.count, 1)
        XCTAssertEqual(
            center.addedRequests.first?.identifier,
            InventoryExpiryNotificationService.notificationIdentifier(for: repo.items[0].id)
        )
        XCTAssertEqual(center.removedPendingIdentifiers.count, 1)
        XCTAssertTrue(center.removedPendingIdentifiers.first?.hasPrefix(InventoryExpiryNotificationService.identifierPrefix) == true)
        XCTAssertNotNil(center.addedRequests.first?.trigger as? UNCalendarNotificationTrigger)
    }

    func testRescheduleClearsPendingRequestsWhenAlertsDisabled() async throws {
        defaults.set(false, forKey: InventoryAlertSettings.isEnabledKey)

        let center = FakeInventoryNotificationCenterClient()
        center.authorizationStatusValue = .authorized
        center.pendingRequestsValue = [
            UNNotificationRequest(
                identifier: InventoryExpiryNotificationService.notificationIdentifier(for: UUID()),
                content: UNMutableNotificationContent(),
                trigger: nil
            )
        ]

        let service = InventoryExpiryNotificationService(
            notificationCenterClient: center,
            inventoryRepository: FakeInventoryRepository(),
            userDefaults: defaults
        )

        try await service.rescheduleNotifications()

        XCTAssertEqual(center.addedRequests.count, 0)
        XCTAssertEqual(center.removedPendingIdentifiers.count, 1)
        XCTAssertEqual(center.removedDeliveredIdentifiers.count, 1)
    }

    func testRescheduleDoesNotScheduleWhenAuthorizationDenied() async throws {
        defaults.set(true, forKey: InventoryAlertSettings.isEnabledKey)
        defaults.set(InventoryAlertLeadTime.sevenDays.rawValue, forKey: InventoryAlertSettings.leadTimeKey)

        let repo = FakeInventoryRepository()
        repo.items = [makeItem(name: "Water Jug", expiryOffsetDays: 2)]

        let center = FakeInventoryNotificationCenterClient()
        center.authorizationStatusValue = .denied

        let service = InventoryExpiryNotificationService(
            notificationCenterClient: center,
            inventoryRepository: repo,
            userDefaults: defaults
        )

        try await service.rescheduleNotifications()

        XCTAssertEqual(repo.lastExpiringSoonWindow, nil)
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    private func makeItem(name: String, expiryOffsetDays: Int) -> InventoryItem {
        let now = Date()
        return InventoryItem(
            id: UUID(),
            name: name,
            category: .water,
            quantity: 1,
            unit: "unit",
            location: "Pantry",
            notes: "",
            expiryDate: Calendar.current.date(byAdding: .day, value: expiryOffsetDays, to: now),
            reorderThreshold: nil,
            tags: [],
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
    }
}

private final class FakeInventoryRepository: InventoryRepository {
    var items: [InventoryItem] = []
    var lastExpiringSoonWindow: Int?

    func listItems(includeArchived: Bool) throws -> [InventoryItem] { items }
    func item(id: UUID) throws -> InventoryItem? { items.first { $0.id == id } }
    func createItem(_ item: InventoryItem) throws {}
    func updateItem(_ item: InventoryItem) throws {}
    func archiveItem(id: UUID) throws {}
    func deleteItem(id: UUID) throws {}

    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] {
        lastExpiringSoonWindow = days
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return items.filter { item in
            guard let expiryDate = item.expiryDate else { return false }
            return !item.isArchived && expiryDate <= cutoff
        }
    }

    func itemsBelowReorderThreshold() throws -> [InventoryItem] { [] }
}

@MainActor
private final class FakeInventoryNotificationCenterClient: InventoryNotificationCenterClient {
    var authorizationStatusValue: InventoryNotificationAuthorizationStatus = .notDetermined
    var requestAuthorizationStatus: InventoryNotificationAuthorizationStatus = .authorized
    var pendingRequestsValue: [UNNotificationRequest] = []
    var addedRequests: [UNNotificationRequest] = []
    var removedPendingIdentifiers: [String] = []
    var removedDeliveredIdentifiers: [String] = []
    var requestAuthorizationCallCount = 0

    func authorizationStatus() async -> InventoryNotificationAuthorizationStatus {
        authorizationStatusValue
    }

    func requestAuthorization() async throws -> InventoryNotificationAuthorizationStatus {
        requestAuthorizationCallCount += 1
        authorizationStatusValue = requestAuthorizationStatus
        return requestAuthorizationStatus
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pendingRequestsValue
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedPendingIdentifiers = identifiers
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers = identifiers
    }
}
