import XCTest
@testable import OSA

@MainActor
final class NavigationIntentTests: XCTestCase {

    // MARK: - Quick Card Deep Link

    func testOpenQuickCardSelectsQuickCardsTab() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openQuickCard(id: id)

        XCTAssertEqual(coordinator.selectedTab, .quickCards)
    }

    func testOpenQuickCardSetsPendingRoute() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openQuickCard(id: id)

        XCTAssertEqual(coordinator.pendingRoute, .quickCard(id: id))
    }

    // MARK: - Emergency Mode Deep Link

    func testOpenEmergencyModeSelectsHomeTab() {
        let coordinator = AppNavigationCoordinator()

        coordinator.openEmergencyMode()

        XCTAssertEqual(coordinator.selectedTab, .home)
    }

    func testOpenEmergencyModeSetsPendingRoute() {
        let coordinator = AppNavigationCoordinator()

        coordinator.openEmergencyMode()

        XCTAssertEqual(coordinator.pendingRoute, .emergencyMode)
    }

    // MARK: - Handbook Section Deep Link

    func testOpenHandbookSectionSelectsLibraryTab() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openHandbookSection(id: id)

        XCTAssertEqual(coordinator.selectedTab, .library)
    }

    func testOpenHandbookSectionSetsPendingRoute() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openHandbookSection(id: id)

        XCTAssertEqual(coordinator.pendingRoute, .handbookSection(id: id))
    }

    // MARK: - Checklist Run Deep Link

    func testOpenChecklistRunSelectsChecklistsTab() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openChecklistRun(id: id)

        XCTAssertEqual(coordinator.selectedTab, .checklists)
    }

    func testOpenChecklistRunSetsPendingRoute() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openChecklistRun(id: id)

        XCTAssertEqual(coordinator.pendingRoute, .checklistRun(id: id))
    }

    func testHandleEmergencySystemSurfaceDeepLinkRoutesToEmergencyMode() {
        let coordinator = AppNavigationCoordinator()

        coordinator.handle(.emergencyMode)

        XCTAssertEqual(coordinator.selectedTab, .home)
        XCTAssertEqual(coordinator.pendingRoute, .emergencyMode)
    }

    func testHandleQuickCardSystemSurfaceDeepLinkRoutesToQuickCard() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.handle(.quickCard(id))

        XCTAssertEqual(coordinator.selectedTab, .quickCards)
        XCTAssertEqual(coordinator.pendingRoute, .quickCard(id: id))
    }

    // MARK: - Consume Pending Route

    func testConsumePendingRouteReturnsPendingAndClears() {
        let coordinator = AppNavigationCoordinator()
        let id = UUID()

        coordinator.openQuickCard(id: id)
        let consumed = coordinator.consumePendingRoute()

        XCTAssertEqual(consumed, .quickCard(id: id))
        XCTAssertNil(coordinator.pendingRoute)
    }

    func testConsumeWhenNoPendingRouteReturnsNil() {
        let coordinator = AppNavigationCoordinator()

        let consumed = coordinator.consumePendingRoute()

        XCTAssertNil(consumed)
    }

    // MARK: - Sequential Deep Links

    func testSecondDeepLinkOverridesPending() {
        let coordinator = AppNavigationCoordinator()
        let firstID = UUID()
        let secondID = UUID()

        coordinator.openQuickCard(id: firstID)
        coordinator.openHandbookSection(id: secondID)

        XCTAssertEqual(coordinator.selectedTab, .library)
        XCTAssertEqual(coordinator.pendingRoute, .handbookSection(id: secondID))
    }
}
