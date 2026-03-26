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
