import SwiftUI

struct SearchResultsView: View {
    let query: String

    @Environment(\.searchService) private var searchService
    @State private var results: [SearchResult] = []
    @State private var searchFailed = false

    var body: some View {
        Group {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("Enter a term to search across all content.")
                )
            } else if searchFailed {
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
        .onChange(of: query) { _, newValue in
            performSearch(newValue)
        }
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
            results = try searchService?.search(query: trimmed, scopes: nil, limit: 50) ?? []
            searchFailed = false
        } catch {
            searchFailed = true
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(result.title)
                .font(.headline)

            if !result.snippet.isEmpty {
                Text(result.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, Spacing.xs)
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
    SearchResultsView(query: "water")
}
