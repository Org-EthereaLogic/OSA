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

            TabSection {
                Tab(AppTab.checklists.title, systemImage: AppTab.checklists.icon, value: AppTab.checklists) {
                    NavigationStack {
                        ChecklistsScreen()
                    }
                }

                Tab(AppTab.quickCards.title, systemImage: AppTab.quickCards.icon, value: AppTab.quickCards) {
                    NavigationStack {
                        QuickCardsScreen()
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
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    AppTabView()
}
