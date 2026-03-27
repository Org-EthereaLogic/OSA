import SwiftUI

struct ChapterDetailView: View {
    let slug: String

    @Environment(\.handbookRepository) private var repository
    @State private var chapter: HandbookChapter?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This chapter could not be loaded.")
                )
            } else if let chapter {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                        chapterHeader(chapter)

                        ForEach(chapter.sections.sorted(by: { $0.sortOrder < $1.sortOrder })) { section in
                            SectionContentBlock(section: section)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxxl)
                }
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(chapter?.title ?? "Chapter")
        .navigationBarTitleDisplayMode(.large)
        .background(.osaBackground)
        .task { loadChapter() }
    }

    @ViewBuilder
    private func chapterHeader(_ chapter: HandbookChapter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(chapter.summary)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.sm) {
                if chapter.isSeeded {
                    Label("Curated", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.osaTrust)
                }

                if let reviewed = chapter.lastReviewedAt {
                    Label(reviewed.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.bottom, Spacing.md)
    }

    private func loadChapter() {
        do {
            chapter = try repository?.chapter(slug: slug)
            if chapter == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }
}

// MARK: - Section Content

private struct SectionContentBlock: View {
    let section: HandbookSection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(section.heading)
                .font(.sectionHeader)

            if section.safetyLevel == .sensitiveStaticOnly {
                Label("Sensitive \u{2014} static content only", systemImage: "exclamationmark.shield")
                    .font(.caption)
                    .foregroundStyle(.osaEmergency)
            }

            if let attributed = try? AttributedString(markdown: MarkdownPreprocessor.prepare(section.bodyMarkdown)) {
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
    }
}

#Preview {
    NavigationStack {
        ChapterDetailView(slug: "sample-chapter")
    }
}
