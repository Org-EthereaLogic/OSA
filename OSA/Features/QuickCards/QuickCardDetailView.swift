import SwiftUI

struct QuickCardDetailView: View {
    let card: QuickCard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Category + title header — warm ember accent area
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

                    // Title — large-type stress reading
                    Text(card.title)
                        .font(.stressTitle)
                        .foregroundStyle(.primary)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.osaSecondaryBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                .padding(.horizontal, -Spacing.lg)

                // Body content
                if let attributed = try? AttributedString(markdown: card.bodyMarkdown) {
                    Text(attributed)
                        .font(.cardBody)
                } else {
                    Text(card.summary)
                        .font(.cardBody)
                }

                // Provenance metadata
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
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
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
