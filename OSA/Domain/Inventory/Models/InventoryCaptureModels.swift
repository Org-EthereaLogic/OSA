import Foundation

enum InventoryCaptureSource: String, Codable, CaseIterable, Equatable, Sendable {
    case camera
    case photoLibrary = "photo-library"
    case liveScanner = "live-scanner"
}

struct InventoryBarcodeScan: Equatable, Codable, Sendable {
    let payload: String
    let symbology: String
    let capturedAt: Date
    let source: InventoryCaptureSource
}

struct RecognizedInventoryText: Equatable, Codable, Sendable {
    let rawText: String
    let summary: String
    let capturedAt: Date
    let source: InventoryCaptureSource
}

struct InventoryPhotoAttachment: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let fileName: String
    let capturedAt: Date
    let source: InventoryCaptureSource
}
