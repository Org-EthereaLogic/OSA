import SwiftUI
import UIKit
import Vision

#if canImport(VisionKit)
import VisionKit
#endif

enum InventoryCaptureSupport {
    static func preferredImageExtension(for data: Data) -> String {
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47])
        if data.starts(with: pngSignature) {
            return "png"
        }

        return "jpg"
    }

    static func suggestedName(from recognizedText: RecognizedInventoryText) -> String? {
        let firstLine = recognizedText.summary
            .split(separator: "\n")
            .map(String.init)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return firstLine?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum InventoryRecognitionError: LocalizedError, Equatable {
    case invalidImage
    case noBarcodeDetected
    case noTextDetected
    case cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "The selected image could not be analyzed."
        case .noBarcodeDetected:
            "No barcode or QR code was detected in that image."
        case .noTextDetected:
            "No readable label text was detected in that image."
        case .cameraUnavailable:
            "Camera capture is unavailable on this device."
        }
    }
}

enum InventoryBarcodeImageRecognizer {
    static func recognize(
        in data: Data,
        source: InventoryCaptureSource,
        capturedAt: Date = Date()
    ) throws -> InventoryBarcodeScan {
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(data: data)
        try handler.perform([request])

        guard let observation = (request.results ?? [])
            .map({ $0 })
            .first,
              let payload = observation.payloadStringValue,
              !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw InventoryRecognitionError.noBarcodeDetected
        }

        return InventoryBarcodeScan(
            payload: payload,
            symbology: observation.symbology.rawValue,
            capturedAt: capturedAt,
            source: source
        )
    }
}

enum InventoryTextImageRecognizer {
    static func recognize(
        in data: Data,
        source: InventoryCaptureSource,
        capturedAt: Date = Date()
    ) throws -> RecognizedInventoryText {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(data: data)
        try handler.perform([request])

        let recognizedLines = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !recognizedLines.isEmpty else {
            throw InventoryRecognitionError.noTextDetected
        }

        let rawText = recognizedLines.joined(separator: "\n")
        let summary = recognizedLines.prefix(3).joined(separator: "\n")

        return RecognizedInventoryText(
            rawText: rawText,
            summary: summary,
            capturedAt: capturedAt,
            source: source
        )
    }
}

struct InventoryCameraPhotoCaptureView: UIViewControllerRepresentable {
    let onCaptured: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCaptured: onCaptured, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onCaptured: (Data) -> Void
        private let onCancel: () -> Void

        init(
            onCaptured: @escaping (Data) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onCaptured = onCaptured
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.86) else {
                onCancel()
                return
            }

            onCaptured(data)
        }
    }
}

#if canImport(VisionKit)
@available(iOS 16.0, *)
struct InventoryBarcodeScannerView: UIViewControllerRepresentable {
    let onRecognized: (InventoryBarcodeScan) -> Void
    let onCancel: () -> Void

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecognized: onRecognized, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce, .qr, .code128, .code39, .pdf417])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator

        do {
            try controller.startScanning()
        } catch {
            context.coordinator.onCancel()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onRecognized: (InventoryBarcodeScan) -> Void
        fileprivate let onCancel: () -> Void
        private var hasResolved = false

        init(
            onRecognized: @escaping (InventoryBarcodeScan) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onRecognized = onRecognized
            self.onCancel = onCancel
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasResolved else { return }

            for item in addedItems {
                guard case .barcode(let barcode) = item,
                      let payload = barcode.payloadStringValue,
                      !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    continue
                }

                hasResolved = true
                dataScanner.stopScanning()
                onRecognized(
                    InventoryBarcodeScan(
                        payload: payload,
                        symbology: "live-scanner-barcode",
                        capturedAt: Date(),
                        source: .liveScanner
                    )
                )
                return
            }
        }
    }
}
#endif
