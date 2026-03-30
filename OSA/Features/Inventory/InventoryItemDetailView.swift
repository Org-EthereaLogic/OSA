import SwiftUI
import UIKit

struct InventoryItemDetailView: View {
    let itemID: UUID

    @Environment(\.inventoryRepository) private var repository
    @Environment(\.inventoryPhotoStore) private var inventoryPhotoStore
    @Environment(\.noteRepository) private var noteRepository
    @Environment(\.inventoryExpiryNotificationService) private var inventoryExpiryNotificationService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var item: InventoryItem?
    @State private var linkedNotes: [NoteRecord] = []
    @State private var photoDataByID: [UUID: Data] = [:]
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
                ProgressView("Loading...")
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Inventory item actions")
                    .accessibilityHint("Shows edit, archive, and delete actions.")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let item {
                NavigationStack {
                    InventoryItemFormView(mode: .edit(item)) { updatedItem in
                        try repository?.updateItem(updatedItem)
                        loadItem()
                        rescheduleInventoryAlerts()
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

            if !item.photoAttachments.isEmpty {
                Section("Local Photos") {
                    ForEach(item.photoAttachments) { attachment in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            if let data = photoDataByID[attachment.id],
                               let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                                    .accessibilityLabel("Inventory photo")
                            } else {
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.osaSecondaryBackground)
                                    .frame(height: 120)
                                    .overlay {
                                        Label("Photo unavailable", systemImage: "photo.badge.exclamationmark")
                                            .foregroundStyle(.secondary)
                                    }
                            }

                            HStack {
                                Label(
                                    attachment.source.displayName,
                                    systemImage: attachment.source.systemImage
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                Spacer()

                                Text(attachment.capturedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Button(role: .destructive) {
                                removePhoto(attachment)
                            } label: {
                                Label("Remove Photo", systemImage: "trash")
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            }

            if item.barcodeScan != nil || item.recognizedText != nil {
                Section("Capture Metadata") {
                    if let barcodeScan = item.barcodeScan {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Captured Code")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(barcodeScan.payload)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                            Text("\(barcodeScan.symbology) via \(barcodeScan.source.displayName)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let recognizedText = item.recognizedText {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Recognized Label")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(recognizedText.summary)
                                .font(.body)
                            Text("Local only. Not indexed into Ask or system surfaces.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
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

            if !linkedNotes.isEmpty {
                Section("Linked Notes") {
                    ForEach(linkedNotes) { note in
                        NavigationLink {
                            NoteDetailView(noteID: note.id)
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(note.title)
                                    .font(.headline)
                                Text(note.plainText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
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
            let loadedItem = try repository?.item(id: itemID)
            item = loadedItem
            loadFailed = loadedItem == nil
            linkedNotes = try noteRepository?.notesLinkedToInventoryItem(id: itemID) ?? []
            loadPhotoData(for: loadedItem?.photoAttachments ?? [])
        } catch {
            loadFailed = true
        }
    }

    private func loadPhotoData(for attachments: [InventoryPhotoAttachment]) {
        photoDataByID = [:]

        guard let inventoryPhotoStore else { return }

        for attachment in attachments {
            photoDataByID[attachment.id] = try? inventoryPhotoStore.photoData(for: attachment)
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
            rescheduleInventoryAlerts()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func deleteItem() {
        guard let item else { return }

        do {
            try repository?.deleteItem(id: item.id)
            for attachment in item.photoAttachments {
                try? inventoryPhotoStore?.deletePhoto(attachment)
            }
            hapticFeedbackService?.play(.warning)
            rescheduleInventoryAlerts()
        } catch {
            hapticFeedbackService?.play(.error)
        }
    }

    private func removePhoto(_ attachment: InventoryPhotoAttachment) {
        guard var item else { return }

        item.photoAttachments.removeAll { $0.id == attachment.id }
        item.updatedAt = Date()

        do {
            try repository?.updateItem(item)
            try inventoryPhotoStore?.deletePhoto(attachment)
            self.item = item
            loadPhotoData(for: item.photoAttachments)
            hapticFeedbackService?.play(.success)
        } catch {
            hapticFeedbackService?.play(.error)
        }
    }

    private func rescheduleInventoryAlerts() {
        Task {
            try? await inventoryExpiryNotificationService?.rescheduleNotifications()
        }
    }
}

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
            .accessibilityLabel(isExpired ? "Expired" : isExpiringSoon ? "Expiring soon" : "Expiry date")
            .accessibilityValue(date.formatted(date: .abbreviated, time: .omitted))
    }
}

private extension InventoryCaptureSource {
    var displayName: String {
        switch self {
        case .camera:
            "Camera"
        case .photoLibrary:
            "Photo Library"
        case .liveScanner:
            "Live Scanner"
        }
    }

    var systemImage: String {
        switch self {
        case .camera:
            "camera"
        case .photoLibrary:
            "photo.on.rectangle"
        case .liveScanner:
            "barcode.viewfinder"
        }
    }
}

#Preview {
    NavigationStack {
        InventoryItemDetailView(itemID: UUID())
    }
}
