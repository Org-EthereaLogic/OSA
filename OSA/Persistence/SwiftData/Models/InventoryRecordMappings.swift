import Foundation

extension PersistedInventoryItem {
    convenience init(from item: InventoryItem) {
        self.init(
            id: item.id,
            name: item.name,
            categoryRawValue: item.category.rawValue,
            quantity: item.quantity,
            unit: item.unit,
            location: item.location,
            notes: item.notes,
            expiryDate: item.expiryDate,
            reorderThreshold: item.reorderThreshold,
            tagsJSON: PersistenceValueCoding.encode(item.tags),
            barcodeScanJSON: PersistenceValueCoding.encodeOptionalCodable(item.barcodeScan),
            recognizedTextJSON: PersistenceValueCoding.encodeOptionalCodable(item.recognizedText),
            photoAttachmentsJSON: PersistenceValueCoding.encodeCodable(item.photoAttachments),
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            isArchived: item.isArchived
        )
    }

    func update(from item: InventoryItem) {
        name = item.name
        categoryRawValue = item.category.rawValue
        quantity = item.quantity
        unit = item.unit
        location = item.location
        notes = item.notes
        expiryDate = item.expiryDate
        reorderThreshold = item.reorderThreshold
        tagsJSON = PersistenceValueCoding.encode(item.tags)
        barcodeScanJSON = PersistenceValueCoding.encodeOptionalCodable(item.barcodeScan)
        recognizedTextJSON = PersistenceValueCoding.encodeOptionalCodable(item.recognizedText)
        photoAttachmentsJSON = PersistenceValueCoding.encodeCodable(item.photoAttachments)
        updatedAt = item.updatedAt
        isArchived = item.isArchived
    }

    func toDomain() -> InventoryItem {
        InventoryItem(
            id: id,
            name: name,
            category: InventoryCategory(rawValue: categoryRawValue) ?? .other,
            quantity: quantity,
            unit: unit,
            location: location,
            notes: notes,
            expiryDate: expiryDate,
            reorderThreshold: reorderThreshold,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            barcodeScan: PersistenceValueCoding.decodeOptionalCodable(InventoryBarcodeScan.self, from: barcodeScanJSON),
            recognizedText: PersistenceValueCoding.decodeOptionalCodable(RecognizedInventoryText.self, from: recognizedTextJSON),
            photoAttachments: PersistenceValueCoding.decodeCodable([InventoryPhotoAttachment].self, from: photoAttachmentsJSON) ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived
        )
    }
}
