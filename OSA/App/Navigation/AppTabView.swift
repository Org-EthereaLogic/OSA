import SwiftUI

struct AppTabView: View {
    @Bindable var coordinator: AppNavigationCoordinator

    @State private var libraryDeepLinkSectionID: UUID?
    @State private var quickCardDeepLinkID: UUID?

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack {
                    HomeScreen()
                }
            }

            Tab(AppTab.library.title, systemImage: AppTab.library.icon, value: .library) {
                NavigationStack {
                    LibraryScreen()
                        .navigationDestination(item: $libraryDeepLinkSectionID) { sectionID in
                            HandbookSectionDetailView(sectionID: sectionID)
                        }
                }
            }

            Tab(AppTab.ask.title, systemImage: AppTab.ask.icon, value: .ask) {
                NavigationStack {
                    AskScreen()
                }
            }

            Tab(AppTab.inventory.title, systemImage: AppTab.inventory.icon, value: .inventory) {
                NavigationStack {
                    InventoryScreen()
                }
            }

            Tab(AppTab.maps.title, systemImage: AppTab.maps.icon, value: .maps) {
                NavigationStack {
                    MapScreen()
                }
            }

            TabSection {
                Tab(AppTab.weather.title, systemImage: AppTab.weather.icon, value: AppTab.weather) {
                    NavigationStack {
                        WeatherScreen()
                    }
                }

                Tab(AppTab.checklists.title, systemImage: AppTab.checklists.icon, value: AppTab.checklists) {
                    NavigationStack {
                        ChecklistsScreen()
                    }
                }

                Tab(AppTab.quickCards.title, systemImage: AppTab.quickCards.icon, value: AppTab.quickCards) {
                    NavigationStack {
                        QuickCardsScreen()
                            .navigationDestination(item: $quickCardDeepLinkID) { cardID in
                                QuickCardRouteView(cardID: cardID)
                            }
                    }
                }

                Tab(AppTab.notes.title, systemImage: AppTab.notes.icon, value: AppTab.notes) {
                    NavigationStack {
                        NotesScreen()
                    }
                }

                Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: AppTab.settings) {
                    NavigationStack {
                        SettingsScreen()
                    }
                }
            } header: {
                Text("More")
            }
        }
        .tint(.osaPrimary)
        .tabViewStyle(.sidebarAdaptable)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.osaSurface, for: .tabBar)
        .onChange(of: coordinator.pendingRoute) { _, route in
            guard let route else { return }
            _ = coordinator.consumePendingRoute()
            switch route {
            case .quickCard(let id):
                quickCardDeepLinkID = id
            case .handbookSection(let id):
                libraryDeepLinkSectionID = id
            }
        }
    }
}

#Preview {
    AppTabView(coordinator: AppNavigationCoordinator())
}
