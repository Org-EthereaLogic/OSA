import SwiftUI

struct AppTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab(AppTab.library.title, systemImage: AppTab.library.icon, value: .library) {
                NavigationStack {
                    LibraryView()
                }
            }

            Tab(AppTab.ask.title, systemImage: AppTab.ask.icon, value: .ask) {
                NavigationStack {
                    AskView()
                }
            }

            Tab(AppTab.inventory.title, systemImage: AppTab.inventory.icon, value: .inventory) {
                NavigationStack {
                    InventoryView()
                }
            }

            TabSection(AppTab.more.title) {
                Tab(AppTab.checklists.title, systemImage: AppTab.checklists.icon, value: .checklists) {
                    NavigationStack {
                        ChecklistsView()
                    }
                }

                Tab(AppTab.quickCards.title, systemImage: AppTab.quickCards.icon, value: .quickCards) {
                    NavigationStack {
                        QuickCardsView()
                    }
                }

                Tab(AppTab.notes.title, systemImage: AppTab.notes.icon, value: .notes) {
                    NavigationStack {
                        NotesView()
                    }
                }

                Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                    NavigationStack {
                        SettingsView()
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
