import Foundation

enum InventoryPhotoStoreError: LocalizedError, Equatable {
    case invalidFileExtension
    case missingPhoto(UUID)
    case unreadablePhoto(UUID)

    var errorDescription: String? {
        switch self {
        case .invalidFileExtension:
            "The selected photo format is not supported."
        case .missingPhoto(let id):
            "The inventory photo \(id.uuidString) is missing from local storage."
        case .unreadablePhoto(let id):
            "The inventory photo \(id.uuidString) could not be read from local storage."
        }
    }
}

final class FileBackedInventoryPhotoStore: InventoryPhotoStore, @unchecked Sendable {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) {
        self.fileManager = fileManager

        let appSupport = baseDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("OSA", isDirectory: true)
        self.directoryURL = appSupport.appendingPathComponent("InventoryPhotos", isDirectory: true)

        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func savePhoto(
        data: Data,
        preferredFileExtension: String,
        source: InventoryCaptureSource,
        capturedAt: Date
    ) throws -> InventoryPhotoAttachment {
        let sanitizedExtension = preferredFileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !sanitizedExtension.isEmpty,
              sanitizedExtension.range(of: #"^[a-z0-9]+$"#, options: .regularExpression) != nil
        else {
            throw InventoryPhotoStoreError.invalidFileExtension
        }

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let identifier = UUID()
        let attachment = InventoryPhotoAttachment(
            id: identifier,
            fileName: "\(identifier.uuidString).\(sanitizedExtension)",
            capturedAt: capturedAt,
            source: source
        )

        let fileURL = url(for: attachment)
        try data.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )

        return attachment
    }

    func photoData(for attachment: InventoryPhotoAttachment) throws -> Data {
        let fileURL = url(for: attachment)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw InventoryPhotoStoreError.missingPhoto(attachment.id)
        }

        guard let data = fileManager.contents(atPath: fileURL.path) else {
            throw InventoryPhotoStoreError.unreadablePhoto(attachment.id)
        }

        return data
    }

    func deletePhoto(_ attachment: InventoryPhotoAttachment) throws {
        let fileURL = url(for: attachment)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private func url(for attachment: InventoryPhotoAttachment) -> URL {
        directoryURL.appendingPathComponent(attachment.fileName, isDirectory: false)
    }
}
