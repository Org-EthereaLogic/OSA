import SwiftUI

struct LibraryScreen: View {
    @Environment(\.handbookRepository) private var repository
    @Environment(\.searchService) private var searchService
    @AppStorage(RecentLibraryHistorySettings.recentSectionIDsKey)
    private var recentSectionIDsRawValue = RecentLibraryHistorySettings.encode(ids: [])
    @State private var chapters: [HandbookChapterSummary] = []
    @State private var recentEntries: [RecentlyViewedEntry] = []
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var suggestions: [SearchSuggestion] = []
    @State private var selectedScenario: HazardScenario?
    @State private var selectedTopic: String?
    @State private var selectedSearchKind: SearchResultKind?

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

                    if !browseTopics.isEmpty {
                        Section("Browse By Topic") {
                            topicBrowseBar
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    if !recentEntries.isEmpty && !isDiscoveryOverlayVisible {
                        Section("Recently Viewed") {
                            ForEach(recentEntries) { entry in
                                NavigationLink {
                                    HandbookSectionDetailView(sectionID: entry.section.id)
                                } label: {
                                    RecentlyViewedRow(entry: entry)
                                }
                                .listRowBackground(Color.osaSurface)
                            }
                        }
                    }

                    Section(chaptersHeaderTitle) {
                        ForEach(filteredChapters) { chapter in
                            NavigationLink {
                                ChapterDetailView(slug: chapter.slug)
                            } label: {
                                ChapterRow(chapter: chapter)
                            }
                            .listRowBackground(Color.osaSurface)
                        }
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
            if isDiscoveryOverlayVisible {
                VStack(spacing: 0) {
                    searchOverlaySummary

                    SearchResultsView(
                        query: !searchText.isEmpty ? searchText : (selectedScenario?.displayName ?? ""),
                        forcedTag: selectedScenario?.tag,
                        selectedKind: $selectedSearchKind
                    )
                }
            }
        }
        .task {
            loadChapters()
            refreshRecentEntries()
        }
        .onAppear {
            refreshRecentEntries()
        }
        .onChange(of: searchText) { _, newValue in
            loadSuggestions(for: newValue)
            if !newValue.isEmpty {
                selectedScenario = nil
                selectedTopic = nil
            }
        }
        .onChange(of: recentSectionIDsRawValue) { _, _ in
            refreshRecentEntries()
        }
    }

    private var filteredChapters: [HandbookChapterSummary] {
        chapters.filter { chapter in
            matchesScenarioFilter(chapter) && matchesTopicFilter(chapter)
        }
    }

    private var browseTopics: [String] {
        let excluded = Set(["essentials", "home", "offline-first", "outage", "power-outage"])
        let topicCounts = chapters
            .flatMap(\.tags)
            .filter { tag in
                !tag.hasPrefix("scenario:")
                    && !tag.hasPrefix("region:")
                    && !tag.hasPrefix("season:")
                    && !excluded.contains(tag)
            }
            .reduce(into: [String: Int]()) { counts, tag in
                counts[tag, default: 0] += 1
            }

        return topicCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return formatTagText(lhs.key) < formatTagText(rhs.key)
                }
                return lhs.value > rhs.value
            }
            .map(\.key)
            .prefix(10)
            .map { $0 }
    }

    private var chaptersHeaderTitle: String {
        if let selectedTopic {
            return "Topic: \(formatTagText(selectedTopic))"
        }
        return "Handbook Chapters"
    }

    private var isDiscoveryOverlayVisible: Bool {
        !searchText.isEmpty || selectedScenario != nil
    }

    private var searchOverlaySummary: some View {
        HStack {
            Text("Content Type: \(selectedSearchKind?.displayName ?? "All Content")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.osaPrimary)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background(.osaBackground)
    }

    private func loadChapters() {
        do {
            chapters = try repository?.listChapters() ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func refreshRecentEntries() {
        guard let repository else {
            recentEntries = []
            return
        }

        let recentIDs = RecentLibraryHistorySettings.ids(from: recentSectionIDsRawValue)
        let resolvedEntries = recentIDs.compactMap { id -> RecentlyViewedEntry? in
            guard let section = (try? repository.section(id: id)) ?? nil else {
                return nil
            }

            let chapterTitle = ((try? repository.chapter(id: section.chapterID)) ?? nil)?.title ?? "Handbook"
            return RecentlyViewedEntry(section: section, chapterTitle: chapterTitle)
        }

        recentEntries = Array(resolvedEntries.prefix(RecentLibraryHistorySettings.maxRecentSections))

        let prunedRawValue = RecentLibraryHistorySettings.prune(
            rawValue: recentSectionIDsRawValue,
            keeping: recentEntries.map(\.section.id)
        )
        if prunedRawValue != recentSectionIDsRawValue {
            recentSectionIDsRawValue = prunedRawValue
        }
    }

    private var scenarioBrowseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                BrowseChip(
                    title: "All Scenarios",
                    isSelected: selectedScenario == nil
                ) {
                    selectedScenario = nil
                }

                ForEach(HazardScenario.allCases) { scenario in
                    BrowseChip(
                        title: scenario.displayName,
                        isSelected: selectedScenario == scenario
                    ) {
                        selectedTopic = nil
                        selectedScenario = selectedScenario == scenario ? nil : scenario
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
    }

    private var topicBrowseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                BrowseChip(
                    title: "All Topics",
                    isSelected: selectedTopic == nil
                ) {
                    selectedTopic = nil
                }

                ForEach(browseTopics, id: \.self) { topic in
                    BrowseChip(
                        title: formatTagText(topic),
                        isSelected: selectedTopic == topic
                    ) {
                        selectedScenario = nil
                        selectedTopic = selectedTopic == topic ? nil : topic
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func matchesScenarioFilter(_ chapter: HandbookChapterSummary) -> Bool {
        guard let selectedScenario else { return true }
        return chapter.tags.contains(selectedScenario.tag)
    }

    private func matchesTopicFilter(_ chapter: HandbookChapterSummary) -> Bool {
        guard let selectedTopic else { return true }
        return chapter.tags.contains(selectedTopic)
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

private struct BrowseChip: View {
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

private struct RecentlyViewedEntry: Identifiable {
    let section: HandbookSection
    let chapterTitle: String

    var id: UUID { section.id }
}

private struct RecentlyViewedRow: View {
    let entry: RecentlyViewedEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(entry.section.heading)
                .font(.cardTitle)

            Text(entry.chapterTitle)
                .font(.metadataCaption)
                .foregroundStyle(.secondary)

            Text(String(entry.section.plainText.prefix(110)) + (entry.section.plainText.count > 110 ? "..." : ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the recently viewed handbook section.")
    }
}

#Preview {
    NavigationStack {
        LibraryScreen()
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
