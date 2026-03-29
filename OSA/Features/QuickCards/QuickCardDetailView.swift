import SwiftUI

struct QuickCardDetailView: View {
    let card: QuickCard

    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @AppStorage(PinnedContentSettings.pinnedQuickCardIDsKey)
    private var pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @State private var relatedSections: [HandbookSection] = []
    @State private var sharePayload: ActivitySharePayload?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label {
                        Text(card.category)
                            .font(.categoryLabel)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                    }
                    .foregroundStyle(.osaEmber)

                    Text(card.title)
                        .font(.stressTitle)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(card.summary)
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        Label("Stored locally", systemImage: "internaldrive.fill")
                            .font(.metadataCaption)
                            .foregroundStyle(.osaPaperGlow)

                        if let reviewed = card.lastReviewedAt {
                            Label(
                                reviewed.formatted(date: .abbreviated, time: .omitted),
                                systemImage: "checkmark.seal.fill"
                            )
                            .font(.metadataCaption)
                            .foregroundStyle(.osaPaperGlow)
                        }
                    }
                }
                .padding(Spacing.xl)
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

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let attributed = try? AttributedString(markdown: MarkdownPreprocessor.prepare(card.bodyMarkdown)) {
                        Text(attributed)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                    } else {
                        Text(card.summary)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                    }

                    if card.lastReviewedAt != nil || !card.tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if let reviewed = card.lastReviewedAt {
                                Label(
                                    "Reviewed \(reviewed.formatted(date: .abbreviated, time: .omitted))",
                                    systemImage: "checkmark.seal.fill"
                                )
                                .font(.metadataCaption)
                                .foregroundStyle(.osaTrust)
                            }

                            Label("Stored locally on this device", systemImage: "internaldrive.fill")
                                .font(.metadataCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !relatedSections.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Related Handbook")
                                .font(.sectionHeader)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(relatedSections) { section in
                                NavigationLink {
                                    HandbookSectionDetailView(sectionID: section.id)
                                } label: {
                                    Label(section.heading, systemImage: "book.closed.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the related handbook section.")
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.osaHairline, lineWidth: 1)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(.osaBackground)
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    sharePayload = ActivitySharePayload(
                        items: [ContentShareFormatter.quickCardText(for: card)],
                        subject: card.title
                    )
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Share quick card")
                .accessibilityHint("Shares this quick card as text with local attribution.")

                PinToolbarButton(
                    isPinned: isPinned,
                    pinLabel: "Pin quick card",
                    unpinLabel: "Unpin quick card",
                    hint: "Adds this quick card to pinned content on Home."
                ) {
                    pinnedQuickCardIDsRawValue = PinnedContentSettings.toggled(card.id, rawValue: pinnedQuickCardIDsRawValue)
                    hapticFeedbackService?.play(.pinToggle)
                }
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .task { loadRelatedSections() }
    }

    private var isPinned: Bool {
        PinnedContentSettings.isPinned(card.id, rawValue: pinnedQuickCardIDsRawValue)
    }

    private func loadRelatedSections() {
        guard let handbookRepository else { return }
        relatedSections = card.relatedSectionIDs.compactMap { id in
            try? handbookRepository.section(id: id)
        }
    }
}

#Preview {
    NavigationStack {
        QuickCardDetailView(
            card: QuickCard(
                id: UUID(),
                title: "Sample Quick Card",
                slug: "sample",
                category: "First Aid",
                summary: "A brief summary of the card.",
                bodyMarkdown: "**Step 1:** Do something important.\n\n**Step 2:** Follow up.",
                priority: 10,
                relatedSectionIDs: [],
                tags: ["first-aid"],
                lastReviewedAt: Date(),
                largeTypeLayoutVersion: 1
            )
        )
    }
}
