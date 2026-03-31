import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DocumentVaultCaptureView: View {
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.documentVaultRepository) private var repository
    @Environment(\.documentVaultFileStore) private var fileStore
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var title = ""
    @State private var category: DocumentVaultCategory = .identity
    @State private var selectedDocumentData: Data?
    @State private var previewImage: UIImage?
    @State private var fileExtension = "jpg"
    @State private var captureSource: DocumentCaptureSource = .camera
    @State private var byteCount = 0
    @State private var ocrSummary: String?
    @State private var captureMessage: String?
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var showCameraCapture = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Document Details") {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(DocumentVaultCategory.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
            }

            Section("Capture & Import") {
                Button {
                    startCameraCapture()
                } label: {
                    Label("Capture Document", systemImage: "camera")
                }

                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Import Photo", systemImage: "photo.on.rectangle")
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("Import File", systemImage: "doc.badge.plus")
                }

                if let captureMessage {
                    Text(captureMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if selectedDocumentData != nil {
                Section("Preview") {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            .accessibilityLabel("Document preview")
                    } else {
                        Label("Preview available after unlock", systemImage: "lock.doc")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Source", value: captureSource.displayName)
                    LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file))

                    if let ocrSummary, !ocrSummary.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Local OCR Summary")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(ocrSummary)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Vault Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveEntry() }
                    .disabled(selectedDocumentData == nil)
            }
        }
        .sheet(isPresented: $showCameraCapture) {
            InventoryCameraPhotoCaptureView(
                onCaptured: { data in
                    showCameraCapture = false
                    Task { await processImportedData(data, fileExtension: InventoryCaptureSupport.preferredImageExtension(for: data), source: .camera) }
                },
                onCancel: {
                    showCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoPickerItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .task(id: selectedPhotoPickerItem) {
            await handlePhotoSelection()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handleImportedFile(result)
        }
        .alert("Document Vault", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "The vault action could not be completed.")
        }
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

    private func startCameraCapture() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = InventoryRecognitionError.cameraUnavailable.localizedDescription
            return
        }

        showCameraCapture = true
    }

    private func handlePhotoSelection() async {
        guard let selectedPhotoPickerItem else { return }
        defer { self.selectedPhotoPickerItem = nil }

        do {
            guard let data = try await selectedPhotoPickerItem.loadTransferable(type: Data.self) else {
                errorMessage = InventoryRecognitionError.invalidImage.localizedDescription
                return
            }

            await processImportedData(
                data,
                fileExtension: InventoryCaptureSupport.preferredImageExtension(for: data),
                source: .photoLibrary
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleImportedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                Task {
                    await processImportedData(
                        data,
                        fileExtension: url.pathExtension.isEmpty ? "pdf" : url.pathExtension.lowercased(),
                        source: .fileImport
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func processImportedData(
        _ data: Data,
        fileExtension: String,
        source: DocumentCaptureSource
    ) async {
        selectedDocumentData = data
        self.fileExtension = fileExtension
        captureSource = source
        byteCount = data.count
        previewImage = UIImage(data: data)
        ocrSummary = nil

        if previewImage != nil,
           let recognized = try? InventoryTextImageRecognizer.recognize(
                in: data,
                source: source.inventoryCaptureSource
           ) {
            ocrSummary = recognized.summary
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let suggestedTitle = InventoryCaptureSupport.suggestedName(from: recognized) {
                title = suggestedTitle
            }
        }

        captureMessage = "Document prepared for local encryption on save."
    }

    private func saveEntry() {
        guard let selectedDocumentData,
              let fileStore,
              let repository
        else {
            errorMessage = "The document vault is unavailable in this build."
            return
        }

        do {
            let storedFile = try fileStore.storeDocument(
                data: selectedDocumentData,
                preferredFileExtension: fileExtension
            )
            let now = AppClock.now()
            let effectiveTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let entry = DocumentVaultEntry(
                id: UUID(),
                title: effectiveTitle.isEmpty ? category.displayName : effectiveTitle,
                category: category,
                captureSource: captureSource,
                encryptedFileIdentifier: storedFile.encryptedFileIdentifier,
                fileExtension: fileExtension,
                byteCount: storedFile.byteCount,
                ocrSummary: ocrSummary,
                createdAt: now,
                updatedAt: now
            )
            try repository.createEntry(entry)
            onSaved()
            hapticFeedbackService?.play(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            hapticFeedbackService?.play(.error)
        }
    }
}

private extension DocumentCaptureSource {
    var inventoryCaptureSource: InventoryCaptureSource {
        switch self {
        case .camera:
            .camera
        case .photoLibrary:
            .photoLibrary
        case .fileImport:
            .photoLibrary
        }
    }
}

#Preview {
    NavigationStack {
        DocumentVaultCaptureView(onSaved: {})
    }
}
