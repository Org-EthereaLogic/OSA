import SwiftUI

struct NotesScreen: View {
    @Environment(\.noteRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var notes: [NoteRecord] = []
    @State private var loadFailed = false
    @State private var filterType: NoteType?
    @State private var searchText = ""
    @State private var composerState: NoteComposerState?

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Notes could not be loaded. Try restarting the app.")
                )
            } else if notes.isEmpty {
                zeroStateView
            } else if filteredNotes.isEmpty {
                noResultsView
            } else {
                list
            }
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        composerState = NoteComposerState(template: nil)
                    } label: {
                        Label("New Note", systemImage: "square.and.pencil")
                    }

                    Button {
                        composerState = NoteComposerState(template: FamilyEmergencyPlanTemplate.draft())
                    } label: {
                        Label("Family Emergency Plan", systemImage: "person.2.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Create note")
                .accessibilityHint("Shows options for a blank note or a family emergency plan.")
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        filterType = nil
                    } label: {
                        Label("All", systemImage: filterType == nil ? "checkmark" : "")
                    }

                    ForEach(NoteType.allCases, id: \.self) { type in
                        Button {
                            filterType = type
                        } label: {
                            Label(type.displayName, systemImage: filterType == type ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Filter notes")
                .accessibilityHint("Filters notes by note type.")
            }
        }
        .sheet(item: $composerState) { state in
            NavigationStack {
                NoteEditorView(mode: .create, initialTemplate: state.template) { newNote in
                    try repository?.createNote(newNote)
                    loadNotes()
                }
            }
        }
        .task { loadNotes() }
    }

    private var list: some View {
        List {
            ForEach(filteredNotes) { note in
                NavigationLink {
                    NoteDetailView(noteID: note.id)
                } label: {
                    NoteRow(note: note)
                }
                .listRowBackground(Color.osaSurface)
            }
            .onDelete { offsets in
                for index in offsets {
                    try? repository?.deleteNote(id: filteredNotes[index].id)
                }
                if !offsets.isEmpty {
                    hapticFeedbackService?.play(.warning)
                }
                loadNotes()
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private var filteredNotes: [NoteRecord] {
        notes.filter { note in
            matchesTypeFilter(note) && matchesSearch(note)
        }
    }

    private var zeroStateView: some View {
        ContentUnavailableView {
            Label("No Notes Yet", systemImage: "note.text")
        } description: {
            Text("Create a family plan, emergency contacts list, or local reference note so it stays readable offline.")
        } actions: {
            Button("Create First Note") {
                composerState = NoteComposerState(template: nil)
            }

            Button("Create Family Emergency Plan") {
                composerState = NoteComposerState(template: FamilyEmergencyPlanTemplate.draft())
            }
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Matching Notes", systemImage: "magnifyingglass")
        } description: {
            Text(noResultsDescription)
        } actions: {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Clear Search") {
                    searchText = ""
                }
            } else if filterType != nil {
                Button("Show All Notes") {
                    filterType = nil
                }
            }
        }
    }

    private func loadNotes() {
        do {
            notes = try repository?.listNotes(type: nil) ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func matchesTypeFilter(_ note: NoteRecord) -> Bool {
        guard let filterType else { return true }
        return note.noteType == filterType
    }

    private func matchesSearch(_ note: NoteRecord) -> Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return [note.title, note.plainText]
            .contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
            || note.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
    }

    private var noResultsDescription: String {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let filterType, !trimmed.isEmpty {
            return "No \(filterType.displayName.lowercased()) notes match \"\(trimmed)\". Try another title, tag, or clear the filter."
        }

        if !trimmed.isEmpty {
            return "No notes match \"\(trimmed)\". Try terms like water, contacts, meeting, or medication."
        }

        if let filterType {
            return "No \(filterType.displayName.lowercased()) notes are available yet. Switch to All or create one now."
        }

        return "No notes match the current filters."
    }
}

// MARK: - Note Row

private struct NoteRow: View {
    let note: NoteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(note.title)
                    .font(.cardTitle)

                Spacer()

                Text(note.noteType.displayName)
                    .font(.categoryLabel)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(note.noteType.brandColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(note.noteType.brandColor)
            }

            if !note.plainText.isEmpty {
                Text(note.plainText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.metadataCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - NoteType Helpers

extension NoteType {
    var displayName: String {
        switch self {
        case .personal: "Personal"
        case .localReference: "Reference"
        case .familyPlan: "Family Plan"
        }
    }

    var color: Color {
        brandColor
    }

    var brandColor: Color {
        switch self {
        case .personal: .osaCalm
        case .localReference: .osaWarning
        case .familyPlan: .osaTrust
        }
    }
}

#Preview {
    NavigationStack {
        NotesScreen()
    }
}

private struct NoteComposerState: Identifiable {
    let id = UUID()
    let template: NoteDraftTemplate?
}
