import SwiftUI

struct QuickCardRouteView: View {
    let cardID: UUID

    @Environment(\.quickCardRepository) private var repository
    @Environment(\.onscreenContentManager) private var onscreenContentManager
    @State private var card: QuickCard?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This quick card could not be loaded.")
                )
            } else if let card {
                QuickCardDetailView(card: card)
            } else {
                ProgressView("Loading...")
            }
        }
        .task { loadCard() }
        .onDisappear { onscreenContentManager?.clear() }
    }

    private func loadCard() {
        do {
            card = try repository?.quickCard(id: cardID)
            if let card {
                onscreenContentManager?.publishQuickCard(
                    id: card.id,
                    title: card.title,
                    category: card.category
                )
            } else {
                loadFailed = true
                onscreenContentManager?.clear()
            }
        } catch {
            loadFailed = true
            onscreenContentManager?.clear()
        }
    }
}

#Preview {
    NavigationStack {
        QuickCardRouteView(cardID: UUID())
    }
}
