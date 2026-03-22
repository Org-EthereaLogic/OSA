import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text("OSA")
                        .font(.largeTitle.bold())
                    Spacer()
                    ConnectivityBadge(state: .offline)
                }
                .padding(.horizontal, Spacing.lg)

                // Emergency quick cards
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Quick Cards")
                        .font(.sectionHeader)
                    Text("Emergency reference cards will appear here.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)

                // Active checklists
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Active Checklists")
                        .font(.sectionHeader)
                    Text("Your in-progress checklists will appear here.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)

                // Inventory reminders
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Inventory")
                        .font(.sectionHeader)
                    Text("Supply reminders and alerts will appear here.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)

                // Recent notes
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Recent Notes")
                        .font(.sectionHeader)
                    Text("Your latest notes will appear here.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(.osaBackground)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
