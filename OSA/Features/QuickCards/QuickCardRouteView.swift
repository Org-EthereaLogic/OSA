import SwiftUI

struct QuickCardRouteView: View {
    let cardID: UUID

    @Environment(\.quickCardRepository) private var repository
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
    }

    private func loadCard() {
        do {
            card = try repository?.quickCard(id: cardID)
            if card == nil {
                loadFailed = true
            }
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        QuickCardRouteView(cardID: UUID())
    }
}
