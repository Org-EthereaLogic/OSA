import SwiftUI

struct LibraryScreen: View {
    @Environment(\.handbookRepository) private var repository
    @Environment(\.searchService) private var searchService
    @State private var chapters: [HandbookChapterSummary] = []
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var suggestions: [SearchSuggestion] = []
    @State private var selectedScenario: HazardScenario?

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
                List {
                    Section {
                        scenarioBrowseBar
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    ForEach(filteredChapters) { chapter in
                        NavigationLink {
                            ChapterDetailView(slug: chapter.slug)
                        } label: {
                            ChapterRow(chapter: chapter)
                        }
                        .listRowBackground(Color.osaSurface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.osaBackground)
            }
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Search all content")
        .searchSuggestions {
            ForEach(suggestions) { suggestion in
                Button {
                    searchText = formattedSuggestionText(for: suggestion)
                } label: {
                    HStack {
                        Text(formattedSuggestionText(for: suggestion))
                        Spacer()
                        Text(suggestion.source.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if !searchText.isEmpty || selectedScenario != nil {
                SearchResultsView(
                    query: !searchText.isEmpty ? searchText : (selectedScenario?.displayName ?? ""),
                    forcedTag: selectedScenario?.tag
                )
            }
        }
        .task { loadChapters() }
        .onChange(of: searchText) { _, newValue in
            loadSuggestions(for: newValue)
            if !newValue.isEmpty {
                selectedScenario = nil
            }
        }
    }

    private func loadChapters() {
        do {
            chapters = try repository?.listChapters() ?? []
        } catch {
            loadFailed = true
        }
    }

    private var filteredChapters: [HandbookChapterSummary] {
        guard let selectedScenario else { return chapters }
        return chapters.filter { $0.tags.contains(selectedScenario.tag) }
    }

    private var scenarioBrowseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ScenarioChip(
                    title: "All Topics",
                    isSelected: selectedScenario == nil
                ) {
                    selectedScenario = nil
                }

                ForEach(HazardScenario.allCases) { scenario in
                    ScenarioChip(
                        title: scenario.displayName,
                        isSelected: selectedScenario == scenario
                    ) {
                        selectedScenario = selectedScenario == scenario ? nil : scenario
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func loadSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        do {
            suggestions = try searchService?.suggestions(prefix: trimmed, limit: 8) ?? []
        } catch {
            suggestions = []
        }
    }

    private func formattedSuggestionText(for suggestion: SearchSuggestion) -> String {
        formatTagText(suggestion.text)
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

private struct ScenarioChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    isSelected ? Color.osaPrimary.opacity(0.15) : Color.osaSurface,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.osaPrimary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

private func formatTagText(_ rawTag: String) -> String {
    rawTag
        .replacingOccurrences(of: "scenario:", with: "")
        .replacingOccurrences(of: "season:", with: "")
        .replacingOccurrences(of: "region:", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .split(separator: " ")
        .map { $0.capitalized }
        .joined(separator: " ")
}
