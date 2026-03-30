import Foundation

protocol InventoryPhotoStore {
    func savePhoto(
        data: Data,
        preferredFileExtension: String,
        source: InventoryCaptureSource,
        capturedAt: Date
    ) throws -> InventoryPhotoAttachment

    func photoData(for attachment: InventoryPhotoAttachment) throws -> Data
    func deletePhoto(_ attachment: InventoryPhotoAttachment) throws
}
