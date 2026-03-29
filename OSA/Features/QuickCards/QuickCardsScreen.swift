import SwiftUI

struct QuickCardsScreen: View {
    @Environment(\.quickCardRepository) private var repository
    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @AppStorage(PinnedContentSettings.pinnedQuickCardIDsKey)
    private var pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: [])
    @State private var cards: [QuickCard] = []
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var selectedCard: QuickCard?
    @State private var selectedSection: HandbookSection?

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Quick cards could not be loaded. Try restarting the app.")
                )
            } else if cards.isEmpty {
                zeroStateView
            } else if filteredCards.isEmpty {
                noResultsView
            } else {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        quickCardsHeader

                        LazyVStack(spacing: Spacing.md) {
                            ForEach(filteredCards) { card in
                                NavigationLink {
                                    QuickCardDetailView(card: card)
                                } label: {
                                    QuickCardRow(card: card)
                                }
                                .buttonStyle(.plain)
                                .hapticTap(.prominentNavigation)
                                .accessibilityHint("Opens quick card details.")
                                .contextMenu {
                                    Button {
                                        selectedCard = card
                                    } label: {
                                        Label("Open", systemImage: "arrow.forward.circle")
                                    }

                                    Button {
                                        togglePin(for: card)
                                    } label: {
                                        Label(
                                            isPinned(card) ? "Unpin" : "Pin",
                                            systemImage: isPinned(card) ? "pin.slash" : "pin"
                                        )
                                    }

                                    if let relatedSection = firstRelatedSection(for: card) {
                                        Button {
                                            selectedSection = relatedSection
                                        } label: {
                                            Label("Open Related Handbook", systemImage: "book.closed")
                                        }
                                    }
                                }
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
        .searchable(text: $searchText, prompt: "Search quick cards")
        .navigationDestination(isPresented: cardNavigationBinding) {
            if let selectedCard {
                QuickCardDetailView(card: selectedCard)
            }
        }
        .navigationDestination(isPresented: sectionNavigationBinding) {
            if let selectedSection {
                HandbookSectionDetailView(sectionID: selectedSection.id)
            }
        }
        .task { loadCards() }
    }

    private var filteredCards: [QuickCard] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return cards }

        return cards.filter { card in
            [card.title, card.summary, card.category]
                .contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
                || card.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
        }
    }

    private var zeroStateView: some View {
        ContentUnavailableView(
            "No Quick Cards Yet",
            systemImage: "bolt.slash",
            description: Text("Urgent quick cards appear here after local seed content is available so you can pin or review them offline.")
        )
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Matching Quick Cards", systemImage: "magnifyingglass")
        } description: {
            Text("Nothing matched \"\(searchText)\". Try category words like water, fire, outage, or family.")
        } actions: {
            Button("Clear Search") {
                searchText = ""
            }
        }
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
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func isPinned(_ card: QuickCard) -> Bool {
        PinnedContentSettings.isPinned(card.id, rawValue: pinnedQuickCardIDsRawValue)
    }

    private func togglePin(for card: QuickCard) {
        pinnedQuickCardIDsRawValue = PinnedContentSettings.toggled(card.id, rawValue: pinnedQuickCardIDsRawValue)
        hapticFeedbackService?.play(.pinToggle)
    }

    private func firstRelatedSection(for card: QuickCard) -> HandbookSection? {
        guard let handbookRepository else { return nil }

        return card.relatedSectionIDs.compactMap { id -> HandbookSection? in
            guard let section = (try? handbookRepository.section(id: id)) ?? nil else {
                return nil
            }
            return section
        }
        .first
    }

    private var cardNavigationBinding: Binding<Bool> {
        Binding(
            get: { selectedCard != nil },
            set: { isPresented in
                if !isPresented {
                    selectedCard = nil
                }
            }
        )
    }

    private var sectionNavigationBinding: Binding<Bool> {
        Binding(
            get: { selectedSection != nil },
            set: { isPresented in
                if !isPresented {
                    selectedSection = nil
                }
            }
        )
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
                        .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        QuickCardsScreen()
    }
}
