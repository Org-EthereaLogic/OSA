import SwiftUI
import UIKit

struct DocumentVaultDetailView: View {
    let entryID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.documentVaultRepository) private var repository
    @Environment(\.documentVaultFileStore) private var fileStore
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var entry: DocumentVaultEntry?
    @State private var loadFailed = false
    @State private var previewImage: UIImage?
    @State private var previewFileURL: URL?
    @State private var showQuickLook = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "doc.badge.ellipsis",
                    description: Text("This vault entry could not be loaded.")
                )
            } else if let entry {
                content(entry)
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationTitle(entry?.title ?? "Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if entry != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete vault document")
                }
            }
        }
        .confirmationDialog("Delete Vault Document", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("The encrypted file and its local metadata will be removed from this device.")
        }
        .sheet(isPresented: $showQuickLook) {
            if let previewFileURL {
                DocumentVaultQuickLookPreview(fileURL: previewFileURL)
            }
        }
        .alert("Document Vault", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "The vault action failed.")
        }
        .task { loadEntry() }
        .onDisappear {
            if let previewFileURL {
                try? FileManager.default.removeItem(at: previewFileURL)
            }
        }
    }

    @ViewBuilder
    private func content(_ entry: DocumentVaultEntry) -> some View {
        List {
            Section("Metadata") {
                LabeledContent("Category", value: entry.category.displayName)
                LabeledContent("Captured Via", value: entry.captureSource.displayName)
                LabeledContent("Stored Size", value: ByteCountFormatter.string(fromByteCount: Int64(entry.byteCount), countStyle: .file))
                LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            if let ocrSummary = entry.ocrSummary, !ocrSummary.isEmpty {
                Section("Local OCR Summary") {
                    Text(ocrSummary)
                        .font(.body)
                    Text("This summary remains local to the vault and is not indexed into Ask or global search.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Preview") {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .accessibilityLabel("Decrypted document preview")
                } else if previewFileURL != nil {
                    Button {
                        showQuickLook = true
                    } label: {
                        Label("Open Document Preview", systemImage: "doc.text.magnifyingglass")
                    }
                } else {
                    Button {
                        Task { await unlockAndPreparePreview(for: entry) }
                    } label: {
                        Label("Unlock to Preview", systemImage: "faceid")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func loadEntry() {
        do {
            entry = try repository?.entry(id: entryID)
            loadFailed = entry == nil
        } catch {
            loadFailed = true
        }
    }

    private func unlockAndPreparePreview(for entry: DocumentVaultEntry) async {
        guard let fileStore else {
            errorMessage = "The document vault is unavailable in this build."
            return
        }

        do {
            try await DocumentVaultAuthenticator.unlock(reason: "Decrypt this local vault document.")
            let data = try fileStore.decryptedData(for: entry)
            if let image = UIImage(data: data) {
                previewImage = image
                previewFileURL = nil
            } else {
                let temporaryURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(entry.id.uuidString).\(entry.fileExtension)")
                try data.write(to: temporaryURL, options: .atomic)
                previewFileURL = temporaryURL
                previewImage = nil
            }
            hapticFeedbackService?.play(.success)
        } catch {
            errorMessage = error.localizedDescription
            hapticFeedbackService?.play(.error)
        }
    }

    private func deleteEntry() {
        guard let entry else { return }

        do {
            try repository?.deleteEntry(id: entry.id)
            try fileStore?.deleteDocument(for: entry)
            hapticFeedbackService?.play(.warning)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            hapticFeedbackService?.play(.error)
        }
    }
}

#Preview {
    NavigationStack {
        DocumentVaultDetailView(entryID: UUID())
    }
}
