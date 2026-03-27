import SwiftUI

struct HandbookSectionDetailView: View {
    let sectionID: UUID

    @Environment(\.handbookRepository) private var repository
    @Environment(\.onscreenContentManager) private var onscreenContentManager
    @State private var section: HandbookSection?
    @State private var chapter: HandbookChapter?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This section could not be loaded.")
                )
            } else if let section {
                content(section)
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationTitle(section?.heading ?? "Section")
        .navigationBarTitleDisplayMode(.inline)
        .background(.osaBackground)
        .task { loadSection() }
        .onDisappear { onscreenContentManager?.clear() }
    }

    @ViewBuilder
    private func content(_ section: HandbookSection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let chapter {
                    Label(chapter.title, systemImage: "book.closed.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if section.safetyLevel == .sensitiveStaticOnly {
                    Label("Sensitive - static content only", systemImage: "exclamationmark.shield")
                        .font(.caption)
                        .foregroundStyle(.osaEmergency)
                }

                if let attributed = try? AttributedString(markdown: section.bodyMarkdown) {
                    Text(attributed)
                        .font(.body)
                } else {
                    Text(section.plainText)
                        .font(.body)
                }

                if let reviewed = section.lastReviewedAt {
                    Text("Reviewed \(reviewed.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    private func loadSection() {
        do {
            guard let loadedSection = try repository?.section(id: sectionID) else {
                loadFailed = true
                return
            }

            section = loadedSection
            chapter = try repository?.chapter(id: loadedSection.chapterID)
            onscreenContentManager?.publishHandbookSection(
                id: loadedSection.id,
                heading: loadedSection.heading,
                chapterTitle: chapter?.title ?? ""
            )
        } catch {
            loadFailed = true
            onscreenContentManager?.clear()
        }
    }
}

#Preview {
    NavigationStack {
        HandbookSectionDetailView(sectionID: UUID())
    }
}
