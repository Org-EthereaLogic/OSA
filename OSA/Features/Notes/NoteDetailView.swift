import SwiftUI

struct NoteDetailView: View {
    let noteID: UUID

    @Environment(\.noteRepository) private var repository
    @State private var note: NoteRecord?
    @State private var loadFailed = false
    @State private var showingEdit = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This note could not be loaded.")
                )
            } else if let note {
                content(note)
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(note?.title ?? "Note")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if note != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEdit = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let note {
                NavigationStack {
                    NoteEditorView(mode: .edit(note)) { updatedNote in
                        try repository?.updateNote(updatedNote)
                        loadNote()
                    }
                }
            }
        }
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let note {
                    try? repository?.deleteNote(id: note.id)
                    dismiss()
                }
            }
        } message: {
            Text("This note will be permanently deleted.")
        }
        .task { loadNote() }
    }

    @ViewBuilder
    private func content(_ note: NoteRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text(note.noteType.displayName)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(note.noteType.brandColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(note.noteType.brandColor)

                    Spacer()

                    Text("Updated \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let attributed = try? AttributedString(markdown: MarkdownPreprocessor.prepare(note.bodyMarkdown)) {
                    Text(attributed)
                        .font(.body)
                } else {
                    Text(note.plainText)
                        .font(.body)
                }

                if !note.tags.isEmpty {
                    FlowTagsView(tags: note.tags)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(.osaBackground)
    }

    private func loadNote() {
        do {
            note = try repository?.note(id: noteID)
            if note == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }
}

// MARK: - Tags View

private struct FlowTagsView: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(.secondary.opacity(0.1), in: Capsule())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(noteID: UUID())
    }
}
