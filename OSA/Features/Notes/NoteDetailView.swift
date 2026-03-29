import SwiftUI

struct NoteDetailView: View {
    let noteID: UUID

    @Environment(\.noteRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var note: NoteRecord?
    @State private var loadFailed = false
    @State private var showingEdit = false
    @State private var showDeleteConfirmation = false
    @State private var sharePayload: ActivitySharePayload?
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
                            exportMarkdown()
                        } label: {
                            Label("Export as Markdown", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            exportPlainText()
                        } label: {
                            Label("Export as Plain Text", systemImage: "doc.plaintext")
                        }

                        Divider()

                        Button {
                            showingEdit = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Note actions")
                    .accessibilityHint("Shows edit and delete actions for this note.")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let note {
                NavigationStack {
                    NoteEditorView(mode: .edit(note), initialTemplate: nil) { updatedNote in
                        try repository?.updateNote(updatedNote)
                        loadNote()
                    }
                }
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let note {
                    try? repository?.deleteNote(id: note.id)
                    hapticFeedbackService?.play(.warning)
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

    private func exportMarkdown() {
        guard let note else { return }
        sharePayload = ActivitySharePayload(
            items: [NoteExportFormatter.markdownContent(for: note)],
            subject: note.title
        )
    }

    private func exportPlainText() {
        guard let note else { return }
        sharePayload = ActivitySharePayload(
            items: [NoteExportFormatter.plainTextContent(for: note)],
            subject: note.title
        )
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
