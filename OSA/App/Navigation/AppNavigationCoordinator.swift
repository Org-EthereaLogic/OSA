import Foundation
import Observation

/// A deep-link destination requested by an App Intent.
enum DeepLinkRoute: Equatable, Sendable {
    case quickCard(id: UUID)
    case handbookSection(id: UUID)
}

/// App-owned navigation coordinator that mediates between App Intents
/// and the SwiftUI app shell.
///
/// App Intents write deep-link requests here through `SharedRuntime`.
/// `AppTabView` observes the coordinator and consumes pending routes
/// to drive navigation without App Intents reaching into view state.
@MainActor
@Observable
final class AppNavigationCoordinator {
    var selectedTab: AppTab = .home
    private(set) var pendingRoute: DeepLinkRoute?

    func openQuickCard(id: UUID) {
        selectedTab = .quickCards
        pendingRoute = .quickCard(id: id)
    }

    func openHandbookSection(id: UUID) {
        selectedTab = .library
        pendingRoute = .handbookSection(id: id)
    }

    func consumePendingRoute() -> DeepLinkRoute? {
        let route = pendingRoute
        pendingRoute = nil
        return route
    }
}
