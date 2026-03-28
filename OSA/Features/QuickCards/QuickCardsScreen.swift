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
                    VStack(spacing: Spacing.lg) {
                        quickCardsHeader

                        LazyVStack(spacing: Spacing.md) {
                            ForEach(cards) { card in
                                NavigationLink {
                                    QuickCardDetailView(card: card)
                                } label: {
                                    QuickCardRow(card: card)
                                }
                                .buttonStyle(.plain)
                                .hapticTap(.prominentNavigation)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .background(.osaBackground)
            }
        }
        .navigationTitle("Quick Cards")
        .task { loadCards() }
    }

    private var quickCardsHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                BrandMarkView(size: 40)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("IMMEDIATE ACTION GUIDANCE")
                        .font(.brandEyebrow)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .tracking(1.1)

                    Text("Large-type cards for fast, low-friction reference.")
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.white.opacity(0.84))
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaPine, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaPrimary.opacity(0.24), lineWidth: 1)
        }
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
                        .foregroundStyle(.osaPaperGlow)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.osaPrimary.opacity(0.18), in: Capsule())
                }
            }

            Text(card.title)
                .font(.cardTitle)
                .foregroundStyle(.white)

            Text(card.summary)
                .font(.cardBody)
                .foregroundStyle(Color.white.opacity(0.74))
                .lineLimit(3)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.lg)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.osaPrimary.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: Color.osaNight.opacity(0.1), radius: 14, y: 8)
    }
}

#Preview {
    NavigationStack {
        QuickCardsScreen()
    }
}
