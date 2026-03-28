import SwiftUI

struct InventoryItemFormView: View {
    enum Mode {
        case create
        case edit(InventoryItem)
    }

    let mode: Mode
    let onSave: (InventoryItem) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.inventoryCompletionService) private var completionService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var name: String = ""
    @State private var category: InventoryCategory = .other
    @State private var quantity: Int = 1
    @State private var unit: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var hasExpiry: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var hasReorderThreshold: Bool = false
    @State private var reorderThreshold: Int = 1
    @State private var showSaveError = false
    @State private var isSuggesting = false
    @State private var suggestionMessage: String?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingItem: InventoryItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    var body: some View {
        Form {
            Section("Item Details") {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(InventoryCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section("Quantity") {
                Stepper("\(quantity)", value: $quantity, in: 0...9999)
                TextField("Unit (e.g., gallons, boxes)", text: $unit)
            }

            Section("Location") {
                TextField("Where is this stored?", text: $location)
            }

            Section("Expiration") {
                Toggle("Track Expiry Date", isOn: $hasExpiry)
                if hasExpiry {
                    DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                }
            }

            Section("Reorder Alert") {
                Toggle("Alert When Low", isOn: $hasReorderThreshold)
                if hasReorderThreshold {
                    Stepper("Threshold: \(reorderThreshold)", value: $reorderThreshold, in: 1...9999)
                }
            }

            Section("Notes") {
                TextField("Additional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if completionService != nil {
                Section {
                    Button {
                        Task { await suggestDetails() }
                    } label: {
                        HStack {
                            Label("Suggest Details", systemImage: "wand.and.stars")
                            if isSuggesting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSuggesting || name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if let suggestionMessage {
                        Text(suggestionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Item" : "New Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveItem() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The item could not be saved. Please try again.")
        }
        .onAppear { populateFromExisting() }
    }

    private func populateFromExisting() {
        guard let item = existingItem else { return }
        name = item.name
        category = item.category
        quantity = item.quantity
        unit = item.unit
        location = item.location
        notes = item.notes
        hasExpiry = item.expiryDate != nil
        expiryDate = item.expiryDate ?? expiryDate
        hasReorderThreshold = item.reorderThreshold != nil
        reorderThreshold = item.reorderThreshold ?? 1
    }

    private func suggestDetails() async {
        guard let completionService else { return }

        isSuggesting = true
        suggestionMessage = nil

        let request = InventoryCompletionRequest(
            name: name,
            currentCategory: category,
            currentQuantity: quantity,
            currentUnit: unit,
            currentLocation: location
        )

        let suggestion = await completionService.suggest(for: request)

        if suggestion.isEmpty {
            suggestionMessage = "No suggestions available for this input."
        } else {
            let merged = InventoryCompletionMerger.merge(
                suggestion: suggestion,
                into: InventoryCompletionMerger.FormState(
                    category: category,
                    quantity: quantity,
                    unit: unit,
                    location: location
                )
            )
            category = merged.category
            quantity = merged.quantity
            unit = merged.unit
            location = merged.location
            suggestionMessage = "Details updated from suggestions."
        }

        isSuggesting = false
    }

    private func saveItem() {
        let now = Date()
        let item = InventoryItem(
            id: existingItem?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            quantity: quantity,
            unit: unit.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            expiryDate: hasExpiry ? expiryDate : nil,
            reorderThreshold: hasReorderThreshold ? reorderThreshold : nil,
            tags: [],
            createdAt: existingItem?.createdAt ?? now,
            updatedAt: now,
            isArchived: existingItem?.isArchived ?? false
        )

        do {
            try onSave(item)
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
        InventoryItemFormView(mode: .create) { _ in }
    }
}
