import SwiftUI

struct SearchResultsView: View {
    let query: String
    var forcedTag: String? = nil

    @Environment(\.searchService) private var searchService
    @State private var results: [SearchResult] = []
    @State private var searchFailed = false
    @State private var selectedTag: String?
    @Binding var selectedKind: SearchResultKind?

    var body: some View {
        Group {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("Enter a term to search across all content.")
                )
            } else {
                VStack(spacing: 0) {
                    filterBar
                    if searchFailed {
                        ContentUnavailableView(
                            "Search Failed",
                            systemImage: "exclamationmark.triangle",
                            description: Text("An error occurred while searching.")
                        )
                    } else if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        list
                    }
                }
            }
        }
        .onAppear {
            if selectedTag == nil {
                selectedTag = forcedTag
            }
        }
        .onChange(of: query) { _, newValue in
            performSearch(newValue)
        }
        .onChange(of: selectedKind) { _, _ in performSearch(query) }
        .onChange(of: selectedTag) { _, _ in performSearch(query) }
        .task { performSearch(query) }
    }

    private var list: some View {
        let grouped = Dictionary(grouping: results) { $0.kind }
        let sortedKinds = grouped.keys.sorted { $0.rawValue < $1.rawValue }

        return List {
            ForEach(sortedKinds, id: \.self) { kind in
                Section {
                    ForEach(grouped[kind] ?? []) { result in
                        SearchResultRow(result: result)
                    }
                } header: {
                    Label(kind.displayName, systemImage: kind.systemImage)
                }
            }
        }
    }

    private func performSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        do {
            results = try searchService?.search(
                query: trimmed,
                scopes: selectedKind.map { [$0] },
                requiredTags: Set([selectedTag].compactMap { $0 }),
                limit: 50
            ) ?? []
            if !results.isEmpty {
                try searchService?.recordSuccessfulQuery(trimmed)
            }
            searchFailed = false
        } catch {
            searchFailed = true
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: selectedKind == nil
                ) {
                    selectedKind = nil
                }

                ForEach(SearchResultKind.allCases, id: \.self) { kind in
                    FilterChip(
                        title: kind.displayName,
                        isSelected: selectedKind == kind
                    ) {
                        selectedKind = selectedKind == kind ? nil : kind
                    }
                }

                ForEach(availableTags, id: \.self) { tag in
                    FilterChip(
                        title: formatTagText(tag),
                        isSelected: selectedTag == tag
                    ) {
                        selectedTag = selectedTag == tag ? forcedTag : tag
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    private var availableTags: [String] {
        var tags = Set(results.flatMap(\.tags).filter {
            $0.hasPrefix("scenario:") || $0.hasPrefix("season:") || $0.hasPrefix("region:")
        })
        if let forcedTag {
            tags.insert(forcedTag)
        }
        return tags.sorted().prefix(8).map { $0 }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        if let destination = destination {
            NavigationLink {
                destination
            } label: {
                rowContent
            }
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(result.title)
                .font(.headline)

            if !result.snippet.isEmpty {
                Text(result.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !displayTags.isEmpty {
                Text(displayTags)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var destination: AnyView? {
        switch result.kind {
        case .handbookSection:
            AnyView(HandbookSectionDetailView(sectionID: result.id))
        case .quickCard:
            AnyView(QuickCardRouteView(cardID: result.id))
        case .inventoryItem:
            AnyView(InventoryItemDetailView(itemID: result.id))
        case .checklistTemplate:
            AnyView(ChecklistTemplateRouteView(templateID: result.id))
        case .noteRecord:
            AnyView(NoteDetailView(noteID: result.id))
        case .importedKnowledge:
            nil
        }
    }

    private var displayTags: String {
        result.tags
            .filter { $0.hasPrefix("scenario:") || $0.hasPrefix("season:") || $0.hasPrefix("region:") }
            .prefix(3)
            .map(formatTagText)
            .joined(separator: " · ")
    }
}

// MARK: - SearchResultKind Display

extension SearchResultKind {
    var displayName: String {
        switch self {
        case .handbookSection: "Handbook"
        case .quickCard: "Quick Cards"
        case .inventoryItem: "Inventory"
        case .checklistTemplate: "Checklists"
        case .noteRecord: "Notes"
        case .importedKnowledge: "Imported Sources"
        }
    }

    var systemImage: String {
        switch self {
        case .handbookSection: "book.fill"
        case .quickCard: "bolt.fill"
        case .inventoryItem: "archivebox.fill"
        case .checklistTemplate: "checklist"
        case .noteRecord: "note.text"
        case .importedKnowledge: "globe"
        }
    }
}

#Preview {
    SearchResultsView(query: "water", selectedKind: .constant(nil))
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

private struct FilterChip: View {
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
