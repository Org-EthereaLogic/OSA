import SwiftUI

struct AppTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack {
                    HomeScreen()
                }
            }

            Tab(AppTab.library.title, systemImage: AppTab.library.icon, value: .library) {
                NavigationStack {
                    LibraryScreen()
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

            TabSection(AppTab.more.title) {
                Tab(AppTab.checklists.title, systemImage: AppTab.checklists.icon, value: .checklists) {
                    NavigationStack {
                        ChecklistsScreen()
                    }
                }

                Tab(AppTab.quickCards.title, systemImage: AppTab.quickCards.icon, value: .quickCards) {
                    NavigationStack {
                        QuickCardsScreen()
                    }
                }

                Tab(AppTab.notes.title, systemImage: AppTab.notes.icon, value: .notes) {
                    NavigationStack {
                        NotesScreen()
                    }
                }

                Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                    NavigationStack {
                        SettingsScreen()
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    AppTabView()
}
