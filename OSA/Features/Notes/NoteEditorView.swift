import SwiftUI

struct NoteEditorView: View {
    enum Mode {
        case create
        case edit(NoteRecord)
    }

    let mode: Mode
    let initialTemplate: NoteDraftTemplate?
    let onSave: (NoteRecord) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var title = ""
    @State private var bodyMarkdown = ""
    @State private var noteType: NoteType = .personal
    @State private var showSaveError = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingNote: NoteRecord? {
        if case .edit(let note) = mode { return note }
        return nil
    }

    var body: some View {
        Form {
            Section("Note Details") {
                TextField("Title", text: $title)

                Picker("Type", selection: $noteType) {
                    ForEach(NoteType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Content") {
                TextEditor(text: $bodyMarkdown)
                    .frame(minHeight: 200)
                    .accessibilityLabel("Note content")
            }
        }
        .navigationTitle(isEditing ? "Edit Note" : "New Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityHint("Discards changes and closes the note editor.")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveNote() }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityHint("Saves this note on the device.")
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The note could not be saved. Please try again.")
        }
        .onAppear { populateFromExisting() }
    }

    private func populateFromExisting() {
        if let note = existingNote {
            title = note.title
            bodyMarkdown = note.bodyMarkdown
            noteType = note.noteType
            return
        }

        guard let initialTemplate else { return }
        title = initialTemplate.title
        bodyMarkdown = initialTemplate.bodyMarkdown
        noteType = initialTemplate.noteType
    }

    private func saveNote() {
        let now = Date()
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedBody = bodyMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        let plainText = NoteExportFormatter.storedPlainText(fromMarkdown: trimmedBody)

        let note = NoteRecord(
            id: existingNote?.id ?? UUID(),
            title: trimmedTitle,
            bodyMarkdown: trimmedBody,
            plainText: plainText,
            noteType: noteType,
            tags: existingNote?.tags ?? [],
            linkedSectionIDs: existingNote?.linkedSectionIDs ?? [],
            linkedInventoryItemIDs: existingNote?.linkedInventoryItemIDs ?? [],
            createdAt: existingNote?.createdAt ?? now,
            updatedAt: now
        )

        do {
            try onSave(note)
            hapticFeedbackService?.play(.success)
            dismiss()
        } catch {
            hapticFeedbackService?.play(.error)
            showSaveError = true
        }
    }
}

#Preview {
    NavigationStack {
        NoteEditorView(mode: .create, initialTemplate: nil) { _ in }
    }
}
