import SwiftUI

struct CompletionBadgeStripView: View {
    let badges: [CompletionBadge]

    var body: some View {
        if !badges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(badges) { badge in
                        Label(badge.title, systemImage: icon(for: badge.kind))
                            .font(.metadataCaption)
                            .foregroundStyle(tint(for: badge.kind))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(tint(for: badge.kind).opacity(0.12), in: Capsule())
                            .accessibilityHint(badge.detail)
                    }
                }
            }
        }
    }

    private func icon(for kind: PracticeBadgeKind) -> String {
        switch kind {
        case .quizCompleted:
            "checkmark.circle.fill"
        case .mastery:
            "rosette"
        case .weeklyDrill:
            "calendar.badge.checkmark"
        }
    }

    private func tint(for kind: PracticeBadgeKind) -> Color {
        switch kind {
        case .quizCompleted:
            .osaTrust
        case .mastery:
            .osaLocal
        case .weeklyDrill:
            .osaEmergency
        }
    }
}
