import Foundation
import XCTest
@testable import OSA

final class InventoryPhotoStoreTests: XCTestCase {
    func testSaveLoadAndDeletePhotoData() throws {
        let directoryURL = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let store = FileBackedInventoryPhotoStore(baseDirectory: directoryURL)
        let photoData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D])
        let capturedAt = Date(timeIntervalSince1970: 1_743_206_400)

        let attachment = try store.savePhoto(
            data: photoData,
            preferredFileExtension: "png",
            source: .camera,
            capturedAt: capturedAt
        )

        XCTAssertEqual(attachment.source, .camera)
        XCTAssertEqual(attachment.capturedAt, capturedAt)
        XCTAssertTrue(attachment.fileName.hasSuffix(".png"))
        XCTAssertEqual(try store.photoData(for: attachment), photoData)

        try store.deletePhoto(attachment)

        XCTAssertThrowsError(try store.photoData(for: attachment)) { error in
            XCTAssertEqual(error as? InventoryPhotoStoreError, .missingPhoto(attachment.id))
        }
    }

    func testSavePhotoRejectsInvalidExtension() throws {
        let directoryURL = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let store = FileBackedInventoryPhotoStore(baseDirectory: directoryURL)

        XCTAssertThrowsError(
            try store.savePhoto(
                data: Data([0x00, 0x01]),
                preferredFileExtension: "jp*g",
                source: .photoLibrary,
                capturedAt: Date()
            )
        ) { error in
            XCTAssertEqual(error as? InventoryPhotoStoreError, .invalidFileExtension)
        }
    }

    private func makeTemporaryDirectory() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("InventoryPhotoStoreTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}
