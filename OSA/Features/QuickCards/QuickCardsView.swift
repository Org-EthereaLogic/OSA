import SwiftUI

struct QuickCardsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Quick Cards")
                        .font(.cardTitle)
                    Text("High-priority actionable cards optimized for one-handed reading under stress.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xxxl)
                .padding(.horizontal, Spacing.xxl)

                Text("Quick cards will appear here once seed content is imported.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationTitle("Quick Cards")
    }
}

#Preview {
    NavigationStack {
        QuickCardsView()
    }
}
