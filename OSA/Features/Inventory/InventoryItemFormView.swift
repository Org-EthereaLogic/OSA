import PhotosUI
import SwiftUI

struct InventoryItemFormView: View {
    enum Mode {
        case create
        case edit(InventoryItem)
    }

    private enum PhotoPickerMode {
        case attachPhoto
        case recognizeLabel
        case scanBarcode
    }

    let mode: Mode
    let onSave: (InventoryItem) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.inventoryCompletionService) private var completionService
    @Environment(\.inventoryPhotoStore) private var inventoryPhotoStore
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
    @State private var barcodeScan: InventoryBarcodeScan?
    @State private var recognizedText: RecognizedInventoryText?
    @State private var photoAttachments: [InventoryPhotoAttachment] = []
    @State private var originalPhotoAttachmentIDs: Set<UUID> = []
    @State private var showSaveError = false
    @State private var isSuggesting = false
    @State private var suggestionMessage: String?
    @State private var captureMessage: String?
    @State private var showBarcodeScanner = false
    @State private var showCameraCapture = false
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
    @State private var photoPickerMode: PhotoPickerMode?
    @State private var captureErrorMessage: String?
    @State private var didSaveItem = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingItem: InventoryItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    private var hasCaptureMetadata: Bool {
        barcodeScan != nil || recognizedText != nil || !photoAttachments.isEmpty
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

            Section("Capture & Scan") {
                Button {
                    startBarcodeCapture()
                } label: {
                    Label("Scan Code", systemImage: "barcode.viewfinder")
                }
                .accessibilityIdentifier("inventory-form-scan-code")
                .accessibilityHint("Captures a barcode or QR code locally on this device.")

                Button {
                    startCameraCapture()
                } label: {
                    Label("Capture Photo", systemImage: "camera")
                }
                .accessibilityIdentifier("inventory-form-capture-photo")
                .accessibilityHint("Captures a local inventory photo with the device camera.")

                Button {
                    photoPickerMode = .attachPhoto
                } label: {
                    Label("Import Photo", systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("inventory-form-import-photo")
                .accessibilityHint("Imports a local photo from your library without uploading it.")

                Button {
                    photoPickerMode = .recognizeLabel
                } label: {
                    Label("Recognize Label", systemImage: "text.viewfinder")
                }
                .accessibilityIdentifier("inventory-form-recognize-label")
                .accessibilityHint("Uses on-device text recognition to suggest label details from a still image.")

                if let captureMessage {
                    Text(captureMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if hasCaptureMetadata {
                Section("Captured Metadata") {
                    if let barcodeScan {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Code")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(barcodeScan.payload)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                                .lineLimit(3)
                            Text(barcodeScan.symbology)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let recognizedText {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Recognized Label")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(recognizedText.summary)
                                .font(.body)
                                .lineLimit(4)
                            Text("Stored locally for this inventory item only.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if !photoAttachments.isEmpty {
                        HStack {
                            Label(
                                "\(photoAttachments.count) \(photoAttachments.count == 1 ? "local photo attached" : "local photos attached")",
                                systemImage: "photo.stack"
                            )
                            Spacer()
                            Text(photoAttachments.last?.capturedAt.formatted(date: .abbreviated, time: .shortened) ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Quantity") {
                Stepper("\(quantity)", value: $quantity, in: 0...9999)
                    .accessibilityLabel("Quantity")
                    .accessibilityValue("\(quantity)")
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
                        .accessibilityLabel("Reorder threshold")
                        .accessibilityValue("\(reorderThreshold)")
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
                    .accessibilityHint("Uses local suggestions to fill category, quantity, unit, and location.")

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
                    .accessibilityHint("Discards changes and closes the form.")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveItem() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityHint("Saves this inventory item on the device.")
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The item could not be saved. Please try again.")
        }
        .alert("Inventory Capture", isPresented: captureAlertBinding) {
            Button("OK", role: .cancel) {
                captureErrorMessage = nil
            }
        } message: {
            Text(captureErrorMessage ?? "Capture is unavailable right now.")
        }
        .sheet(isPresented: $showCameraCapture) {
            InventoryCameraPhotoCaptureView(
                onCaptured: { data in
                    showCameraCapture = false
                    handleCapturedPhotoData(data, source: .camera)
                },
                onCancel: {
                    showCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showBarcodeScanner) {
            barcodeScannerSheet
        }
        .photosPicker(
            isPresented: photoPickerPresentationBinding,
            selection: $selectedPhotoPickerItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .task(id: selectedPhotoPickerItem) {
            await handleSelectedPhotoPickerItem()
        }
        .onAppear { populateFromExisting() }
        .onDisappear { cleanupUnsavedNewAttachmentsIfNeeded() }
    }

    @ViewBuilder
    private var barcodeScannerSheet: some View {
        #if canImport(VisionKit)
        if #available(iOS 16.0, *), InventoryBarcodeScannerView.isSupported {
            InventoryBarcodeScannerView(
                onRecognized: { scan in
                    showBarcodeScanner = false
                    applyBarcodeScan(scan)
                },
                onCancel: {
                    showBarcodeScanner = false
                }
            )
            .ignoresSafeArea()
        } else {
            scannerFallbackView
        }
        #else
        scannerFallbackView
        #endif
    }

    private var scannerFallbackView: some View {
        NavigationStack {
            ContentUnavailableView(
                "Live Scanner Unavailable",
                systemImage: "barcode.viewfinder",
                description: Text("Import a still image instead and OSA will analyze it locally on device.")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showBarcodeScanner = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import Image") {
                        showBarcodeScanner = false
                        photoPickerMode = .scanBarcode
                    }
                }
            }
        }
    }

    private var captureAlertBinding: Binding<Bool> {
        Binding(
            get: { captureErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    captureErrorMessage = nil
                }
            }
        )
    }

    private var photoPickerPresentationBinding: Binding<Bool> {
        Binding(
            get: { photoPickerMode != nil },
            set: { isPresented in
                if !isPresented {
                    photoPickerMode = nil
                    selectedPhotoPickerItem = nil
                }
            }
        )
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
        barcodeScan = item.barcodeScan
        recognizedText = item.recognizedText
        photoAttachments = item.photoAttachments
        originalPhotoAttachmentIDs = Set(item.photoAttachments.map(\.id))
    }

    private func suggestDetails() async {
        let didApplySuggestion = await applyCompletionSuggestion(using: name)
        suggestionMessage = didApplySuggestion
            ? "Details updated from suggestions."
            : "No suggestions available for this input."
    }

    private func applyCompletionSuggestion(using input: String) async -> Bool {
        guard let completionService else { return false }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return false }

        isSuggesting = true
        defer { isSuggesting = false }

        let request = InventoryCompletionRequest(
            name: trimmedInput,
            currentCategory: category,
            currentQuantity: quantity,
            currentUnit: unit,
            currentLocation: location
        )

        let suggestion = await completionService.suggest(for: request)
        guard !suggestion.isEmpty else { return false }

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
        return true
    }

    private func startBarcodeCapture() {
        #if canImport(VisionKit)
        if #available(iOS 16.0, *), InventoryBarcodeScannerView.isSupported {
            showBarcodeScanner = true
            return
        }
        #endif

        photoPickerMode = .scanBarcode
    }

    private func startCameraCapture() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            captureErrorMessage = InventoryRecognitionError.cameraUnavailable.localizedDescription
            return
        }

        showCameraCapture = true
    }

    private func handleCapturedPhotoData(_ data: Data, source: InventoryCaptureSource) {
        persistPhotoAttachment(data: data, source: source)
    }

    private func handleSelectedPhotoPickerItem() async {
        guard let selectedPhotoPickerItem,
              let mode = photoPickerMode
        else {
            return
        }

        defer {
            self.selectedPhotoPickerItem = nil
            self.photoPickerMode = nil
        }

        do {
            guard let data = try await selectedPhotoPickerItem.loadTransferable(type: Data.self) else {
                captureErrorMessage = InventoryRecognitionError.invalidImage.localizedDescription
                return
            }

            switch mode {
            case .attachPhoto:
                persistPhotoAttachment(data: data, source: .photoLibrary)
            case .recognizeLabel:
                let recognition = try InventoryTextImageRecognizer.recognize(
                    in: data,
                    source: .photoLibrary
                )
                await applyRecognizedText(recognition)
            case .scanBarcode:
                let scan = try InventoryBarcodeImageRecognizer.recognize(
                    in: data,
                    source: .photoLibrary
                )
                applyBarcodeScan(scan)
            }
        } catch {
            captureErrorMessage = error.localizedDescription
        }
    }

    private func persistPhotoAttachment(data: Data, source: InventoryCaptureSource) {
        guard let inventoryPhotoStore else {
            captureErrorMessage = "Inventory photo storage is unavailable in this build."
            return
        }

        do {
            let attachment = try inventoryPhotoStore.savePhoto(
                data: data,
                preferredFileExtension: InventoryCaptureSupport.preferredImageExtension(for: data),
                source: source,
                capturedAt: Date()
            )
            photoAttachments.append(attachment)
            captureMessage = "\(photoAttachments.count) local \(photoAttachments.count == 1 ? "photo is" : "photos are") ready to save."
        } catch {
            captureErrorMessage = error.localizedDescription
        }
    }

    private func applyBarcodeScan(_ scan: InventoryBarcodeScan) {
        barcodeScan = scan
        captureMessage = "Code captured locally and attached to this inventory item."
    }

    private func applyRecognizedText(_ recognition: RecognizedInventoryText) async {
        recognizedText = recognition

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggestedName = InventoryCaptureSupport.suggestedName(from: recognition) {
            name = suggestedName
        }

        let didApplySuggestion = await applyCompletionSuggestion(using: recognition.rawText)
        captureMessage = didApplySuggestion
            ? "Label recognized locally and used to prefill available fields."
            : "Label recognized locally. Review the extracted text and finish entry manually if needed."
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
            barcodeScan: barcodeScan,
            recognizedText: recognizedText,
            photoAttachments: photoAttachments,
            createdAt: existingItem?.createdAt ?? now,
            updatedAt: now,
            isArchived: existingItem?.isArchived ?? false
        )

        do {
            try onSave(item)
            didSaveItem = true
            hapticFeedbackService?.play(.success)
            dismiss()
        } catch {
            hapticFeedbackService?.play(.error)
            showSaveError = true
        }
    }

    private func cleanupUnsavedNewAttachmentsIfNeeded() {
        guard !didSaveItem, let inventoryPhotoStore else { return }

        let orphanedAttachments = photoAttachments.filter { !originalPhotoAttachmentIDs.contains($0.id) }
        guard !orphanedAttachments.isEmpty else { return }

        for attachment in orphanedAttachments {
            try? inventoryPhotoStore.deletePhoto(attachment)
        }
    }
}

#Preview {
    NavigationStack {
        InventoryItemFormView(mode: .create) { _ in }
    }
}
