import SwiftUI

struct NotesScreen: View {
    @Environment(\.noteRepository) private var repository
    @State private var notes: [NoteRecord] = []
    @State private var loadFailed = false
    @State private var filterType: NoteType?
    @State private var showingCreateNote = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Notes could not be loaded. Try restarting the app.")
                )
            } else if notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Tap + to create your first note.")
                )
            } else {
                list
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateNote = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        filterType = nil
                        loadNotes()
                    } label: {
                        Label("All", systemImage: filterType == nil ? "checkmark" : "")
                    }

                    ForEach(NoteType.allCases, id: \.self) { type in
                        Button {
                            filterType = type
                            loadNotes()
                        } label: {
                            Label(type.displayName, systemImage: filterType == type ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingCreateNote) {
            NavigationStack {
                NoteEditorView(mode: .create) { newNote in
                    try repository?.createNote(newNote)
                    loadNotes()
                }
            }
        }
        .task { loadNotes() }
    }

    private var list: some View {
        List {
            ForEach(notes) { note in
                NavigationLink {
                    NoteDetailView(noteID: note.id)
                } label: {
                    NoteRow(note: note)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    try? repository?.deleteNote(id: notes[index].id)
                }
                loadNotes()
            }
        }
    }

    private func loadNotes() {
        do {
            notes = try repository?.listNotes(type: filterType) ?? []
        } catch {
            loadFailed = true
        }
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
        switch self {
        case .personal: .blue
        case .localReference: .orange
        case .familyPlan: .purple
        }
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
