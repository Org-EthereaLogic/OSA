import SwiftUI

struct InventoryItemDetailView: View {
    let itemID: UUID

    @Environment(\.inventoryRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var item: InventoryItem?
    @State private var loadFailed = false
    @State private var showingEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This item could not be loaded.")
                )
            } else if let item {
                content(item)
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(item?.name ?? "Item")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if item != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEdit = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            archiveItem()
                        } label: {
                            Label(
                                item?.isArchived == true ? "Unarchive" : "Archive",
                                systemImage: item?.isArchived == true ? "tray.and.arrow.up" : "archivebox"
                            )
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
            if let item {
                NavigationStack {
                    InventoryItemFormView(mode: .edit(item)) { updatedItem in
                        try repository?.updateItem(updatedItem)
                        loadItem()
                    }
                }
            }
        }
        .confirmationDialog("Delete Item", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteItem() }
        } message: {
            Text("This item will be permanently deleted.")
        }
        .task { loadItem() }
    }

    @ViewBuilder
    private func content(_ item: InventoryItem) -> some View {
        List {
            Section("Details") {
                LabeledContent("Category") {
                    Label(item.category.displayName, systemImage: item.category.systemImage)
                }
                LabeledContent("Quantity", value: "\(item.quantity) \(item.unit)")
                if !item.location.isEmpty {
                    LabeledContent("Location", value: item.location)
                }
            }

            if item.expiryDate != nil || item.reorderThreshold != nil {
                Section("Alerts") {
                    if let expiry = item.expiryDate {
                        LabeledContent("Expires") {
                            ExpiryBadge(date: expiry)
                        }
                    }
                    if let threshold = item.reorderThreshold {
                        LabeledContent("Reorder At") {
                            Text("\(threshold) \(item.unit)")
                                .foregroundStyle(item.quantity <= threshold ? .osaWarning : .secondary)
                        }
                    }
                }
            }

            if !item.notes.isEmpty {
                Section("Notes") {
                    Text(item.notes)
                        .font(.body)
                }
            }

            Section {
                LabeledContent("Created", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                if item.isArchived {
                    Label("Archived", systemImage: "archivebox.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private func loadItem() {
        do {
            item = try repository?.item(id: itemID)
            if item == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }

    private func archiveItem() {
        guard let item else { return }
        do {
            if item.isArchived {
                var unarchived = item
                unarchived.isArchived = false
                unarchived.updatedAt = Date()
                try repository?.updateItem(unarchived)
            } else {
                try repository?.archiveItem(id: item.id)
            }
            loadItem()
            hapticFeedbackService?.play(.success)
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func deleteItem() {
        guard let item else { return }
        try? repository?.deleteItem(id: item.id)
        hapticFeedbackService?.play(.warning)
    }
}

// MARK: - Expiry Badge

private struct ExpiryBadge: View {
    let date: Date

    private var isExpired: Bool { date < Date() }

    private var isExpiringSoon: Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: Date()) else {
            return false
        }
        return date <= cutoff && !isExpired
    }

    var body: some View {
        Text(date.formatted(date: .abbreviated, time: .omitted))
            .foregroundStyle(isExpired ? .osaCritical : isExpiringSoon ? .osaWarning : .primary)
    }
}

#Preview {
    NavigationStack {
        InventoryItemDetailView(itemID: UUID())
    }
}
