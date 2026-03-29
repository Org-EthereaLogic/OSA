import SwiftUI

struct InventoryScreen: View {
    @Environment(\.inventoryRepository) private var repository
    @Environment(\.inventoryExpiryNotificationService) private var inventoryExpiryNotificationService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var items: [InventoryItem] = []
    @State private var loadFailed = false
    @State private var showArchived = false
    @State private var showingAddItem = false
    @State private var editingItem: InventoryItem?
    @State private var pendingDeleteItem: InventoryItem?
    @State private var sharePayload: ActivitySharePayload?
    @State private var showExportError = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Inventory could not be loaded. Try restarting the app.")
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    "No Items Yet",
                    systemImage: "archivebox",
                    description: Text("Add water, food, lighting, and first aid supplies so you can track what is already on hand offline.")
                )
            } else {
                list
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    exportInventory()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(items.isEmpty)
                .accessibilityLabel("Export inventory")
                .accessibilityHint("Exports the currently visible inventory list as a CSV file.")

                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add inventory item")
                .accessibilityHint("Creates a new inventory item.")
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showArchived.toggle()
                    loadItems()
                } label: {
                    Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(showArchived ? "Hide archived" : "Show archived")
                .accessibilityHint("Shows or hides archived inventory items.")
            }
        }
        .confirmationDialog("Delete Item", isPresented: deleteConfirmationBinding) {
            Button("Delete", role: .destructive) {
                deletePendingItem()
            }
        } message: {
            Text("This item will be permanently deleted.")
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                InventoryItemFormView(mode: .create) { newItem in
                    try repository?.createItem(newItem)
                    loadItems()
                    rescheduleInventoryAlerts()
                }
            }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                InventoryItemFormView(mode: .edit(item)) { updatedItem in
                    try repository?.updateItem(updatedItem)
                    loadItems()
                    rescheduleInventoryAlerts()
                }
            }
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The visible inventory list could not be exported right now.")
        }
        .task { loadItems() }
    }

    private var list: some View {
        let grouped = Dictionary(grouping: items) { $0.category }
        let sortedCategories = grouped.keys.sorted { $0.rawValue < $1.rawValue }

        return List {
            ForEach(sortedCategories, id: \.self) { category in
                Section {
                    ForEach(grouped[category] ?? []) { item in
                        NavigationLink {
                            InventoryItemDetailView(itemID: item.id)
                        } label: {
                            InventoryItemRow(item: item)
                        }
                        .listRowBackground(Color.osaSurface)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                toggleArchive(for: item)
                            } label: {
                                Label(item.isArchived ? "Unarchive" : "Archive", systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                            .tint(.osaPrimary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDeleteItem = item
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                editingItem = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button {
                                toggleArchive(for: item)
                            } label: {
                                Label(
                                    item.isArchived ? "Unarchive" : "Archive",
                                    systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
                                )
                            }

                            Button(role: .destructive) {
                                pendingDeleteItem = item
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Label(category.displayName, systemImage: category.systemImage)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private func loadItems() {
        do {
            items = try repository?.listItems(includeArchived: showArchived) ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func toggleArchive(for item: InventoryItem) {
        do {
            if item.isArchived {
                var unarchived = item
                unarchived.isArchived = false
                unarchived.updatedAt = Date()
                try repository?.updateItem(unarchived)
            } else {
                try repository?.archiveItem(id: item.id)
            }
            hapticFeedbackService?.play(.success)
            loadItems()
            rescheduleInventoryAlerts()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func deletePendingItem() {
        guard let pendingDeleteItem else { return }

        do {
            try repository?.deleteItem(id: pendingDeleteItem.id)
            hapticFeedbackService?.play(.warning)
            self.pendingDeleteItem = nil
            loadItems()
            rescheduleInventoryAlerts()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteItem != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteItem = nil
                }
            }
        )
    }

    private func exportInventory() {
        do {
            let fileURL = try InventoryCSVExporter.exportFile(
                for: items,
                filename: showArchived ? "inventory-with-archived.csv" : "inventory-visible.csv"
            )
            sharePayload = ActivitySharePayload(
                items: [fileURL],
                subject: "OSA Inventory Export"
            )
        } catch {
            hapticFeedbackService?.play(.error)
            showExportError = true
        }
    }

    private func rescheduleInventoryAlerts() {
        Task {
            try? await inventoryExpiryNotificationService?.rescheduleNotifications()
        }
    }
}

// MARK: - Item Row

private struct InventoryItemRow: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(item.name)
                    .font(.cardTitle)
                    .strikethrough(item.isArchived, color: .secondary)

                Spacer()

                Text("\(item.quantity) \(item.unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let expiryDate = item.expiryDate {
                ExpiryLabel(date: expiryDate)
            }

            if !item.location.isEmpty {
                Label(item.location, systemImage: "mappin")
                    .font(.metadataCaption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Expiry Label

private struct ExpiryLabel: View {
    let date: Date

    private var isExpired: Bool {
        date < Date()
    }

    private var isExpiringSoon: Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: Date()) else {
            return false
        }
        return date <= cutoff && !isExpired
    }

    var body: some View {
        Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar.badge.clock")
            .font(.metadataCaption)
            .foregroundStyle(isExpired ? Color.osaCritical : isExpiringSoon ? .osaWarning : Color(.tertiaryLabel))
            .accessibilityLabel(isExpired ? "Expired" : isExpiringSoon ? "Expiring soon" : "Expiry date")
            .accessibilityValue(date.formatted(date: .abbreviated, time: .omitted))
    }
}

// MARK: - Category Helpers

extension InventoryCategory {
    var displayName: String {
        switch self {
        case .water: "Water"
        case .food: "Food"
        case .power: "Power"
        case .firstAid: "First Aid"
        case .lighting: "Lighting"
        case .communication: "Communication"
        case .shelter: "Shelter"
        case .tools: "Tools"
        case .sanitation: "Sanitation"
        case .documents: "Documents"
        case .clothing: "Clothing"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .water: "drop.fill"
        case .food: "fork.knife"
        case .power: "bolt.fill"
        case .firstAid: "cross.case.fill"
        case .lighting: "flashlight.on.fill"
        case .communication: "antenna.radiowaves.left.and.right"
        case .shelter: "tent.fill"
        case .tools: "wrench.and.screwdriver.fill"
        case .sanitation: "hands.and.sparkles.fill"
        case .documents: "doc.text.fill"
        case .clothing: "tshirt.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

#Preview {
    NavigationStack {
        InventoryScreen()
    }
}
