import SwiftUI

struct LibraryScreen: View {
    @Environment(\.handbookRepository) private var repository
    @State private var chapters: [HandbookChapterSummary] = []
    @State private var loadFailed = false
    @State private var searchText = ""

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Handbook content could not be loaded. Try restarting the app.")
                )
            } else if chapters.isEmpty {
                ContentUnavailableView(
                    "No Chapters Yet",
                    systemImage: "book.closed",
                    description: Text("Handbook chapters will appear here once seed content is imported.")
                )
            } else {
                List(chapters) { chapter in
                    NavigationLink {
                        ChapterDetailView(slug: chapter.slug)
                    } label: {
                        ChapterRow(chapter: chapter)
                    }
                    .listRowBackground(Color.osaSurface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.osaBackground)
            }
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Search all content")
        .overlay {
            if !searchText.isEmpty {
                SearchResultsView(query: searchText)
            }
        }
        .task { loadChapters() }
    }

    private func loadChapters() {
        do {
            chapters = try repository?.listChapters() ?? []
        } catch {
            loadFailed = true
        }
    }
}

private struct ChapterRow: View {
    let chapter: HandbookChapterSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(chapter.title)
                .font(.cardTitle)

            Text(chapter.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                if chapter.isSeeded {
                    Label("Curated", systemImage: "checkmark.seal.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaTrust)
                }

                if let reviewed = chapter.lastReviewedAt {
                    Label(reviewed.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                        .font(.metadataCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        LibraryScreen()
    }
}
