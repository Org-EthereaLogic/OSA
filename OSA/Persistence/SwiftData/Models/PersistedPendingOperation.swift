import Foundation
import SwiftData

@Model
final class PersistedPendingOperation {
    @Attribute(.unique) var id: UUID
    var operationTypeRawValue: String
    var statusRawValue: String
    var payloadReference: String
    var createdAt: Date
    var updatedAt: Date
    var retryCount: Int
    var lastError: String?

    init(
        id: UUID,
        operationTypeRawValue: String,
        statusRawValue: String,
        payloadReference: String,
        createdAt: Date,
        updatedAt: Date,
        retryCount: Int,
        lastError: String?
    ) {
        self.id = id
        self.operationTypeRawValue = operationTypeRawValue
        self.statusRawValue = statusRawValue
        self.payloadReference = payloadReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.retryCount = retryCount
        self.lastError = lastError
    }
}
