import SwiftUI

struct QuickCardsScreen: View {
    @Environment(\.quickCardRepository) private var repository
    @State private var cards: [QuickCard] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Quick cards could not be loaded. Try restarting the app.")
                )
            } else if cards.isEmpty {
                ContentUnavailableView(
                    "No Quick Cards Yet",
                    systemImage: "bolt.slash",
                    description: Text("Quick cards will appear here once seed content is imported.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(cards) { card in
                            NavigationLink {
                                QuickCardDetailView(card: card)
                            } label: {
                                QuickCardRow(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .navigationTitle("Quick Cards")
        .task { loadCards() }
    }

    private func loadCards() {
        do {
            cards = try repository?.listQuickCards() ?? []
        } catch {
            loadFailed = true
        }
    }
}

// MARK: - Quick Card Row

private struct QuickCardRow: View {
    let card: QuickCard

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label {
                    Text(card.category)
                        .font(.categoryLabel)
                        .textCase(.uppercase)
                } icon: {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                }
                .foregroundStyle(.osaEmergency)

                Spacer()

                if card.lastReviewedAt != nil {
                    Label("Reviewed", systemImage: "checkmark.seal.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaTrust)
                }
            }

            Text(card.title)
                .font(.cardTitle)
                .foregroundStyle(.primary)

            Text(card.summary)
                .font(.cardBody)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSecondaryBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

#Preview {
    NavigationStack {
        QuickCardsScreen()
    }
}
