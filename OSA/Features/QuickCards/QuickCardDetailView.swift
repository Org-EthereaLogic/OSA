import SwiftUI

struct QuickCardDetailView: View {
    let card: QuickCard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(card.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(.orange)

                Text(card.title)
                    .font(.largeType)

                if let attributed = try? AttributedString(markdown: card.bodyMarkdown) {
                    Text(attributed)
                        .font(.body)
                } else {
                    Text(card.summary)
                        .font(.body)
                }

                if let reviewed = card.lastReviewedAt {
                    Divider()

                    Label(
                        "Reviewed \(reviewed.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "clock"
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
