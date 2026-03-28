import SwiftUI

struct CreateChecklistView: View {
    let onSave: (ChecklistRun) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var title = ""
    @State private var contextNote = ""
    @State private var itemTexts: [String] = [""]
    @State private var showSaveError = false

    var body: some View {
        Form {
            Section("Checklist Details") {
                TextField("Title", text: $title)
                TextField("Context note (optional)", text: $contextNote)
            }

            Section("Items") {
                ForEach(itemTexts.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.tertiary)
                            .font(.caption)

                        TextField("Item \(index + 1)", text: $itemTexts[index])
                    }
                }
                .onDelete { offsets in
                    guard itemTexts.count > 1 else { return }
                    itemTexts.remove(atOffsets: offsets)
                }

                Button {
                    itemTexts.append("")
                } label: {
                    Label("Add Item", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("New Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Start") { saveChecklist() }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || validItemTexts.isEmpty)
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The checklist could not be created. Please try again.")
        }
    }

    private var validItemTexts: [String] {
        itemTexts
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func saveChecklist() {
        let now = Date()
        let runID = UUID()
        let items = validItemTexts.enumerated().map { index, text in
            ChecklistRunItem(
                id: UUID(),
                runID: runID,
                templateItemID: nil,
                text: text,
                isComplete: false,
                completedAt: nil,
                sortOrder: (index + 1) * 100
            )
        }

        let run = ChecklistRun(
            id: runID,
            templateID: nil,
            title: title.trimmingCharacters(in: .whitespaces),
            startedAt: now,
            completedAt: nil,
            status: .inProgress,
            contextNote: contextNote.trimmingCharacters(in: .whitespaces).isEmpty ? nil : contextNote.trimmingCharacters(in: .whitespaces),
            items: items
        )

        do {
            try onSave(run)
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
        CreateChecklistView { _ in }
    }
}
