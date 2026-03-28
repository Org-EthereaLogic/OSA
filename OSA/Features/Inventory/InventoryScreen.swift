import SwiftUI

struct InventoryScreen: View {
    @Environment(\.inventoryRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var items: [InventoryItem] = []
    @State private var loadFailed = false
    @State private var showArchived = false
    @State private var showingAddItem = false

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
                    description: Text("Tap + to add your first supply item.")
                )
            } else {
                list
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                InventoryItemFormView(mode: .create) { newItem in
                    try repository?.createItem(newItem)
                    loadItems()
                }
            }
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
                    }
                    .onDelete { offsets in
                        deleteItems(in: grouped[category] ?? [], at: offsets)
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
        } catch {
            loadFailed = true
        }
    }

    private func deleteItems(in categoryItems: [InventoryItem], at offsets: IndexSet) {
        for index in offsets {
            let item = categoryItems[index]
            try? repository?.deleteItem(id: item.id)
        }
        if !offsets.isEmpty {
            hapticFeedbackService?.play(.warning)
        }
        loadItems()
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
