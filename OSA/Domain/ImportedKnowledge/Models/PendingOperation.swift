import Foundation

/// A queued unit of work in the import pipeline (fetch, normalize, chunk, or index).
struct PendingOperation: Identifiable, Equatable, Sendable {
    let id: UUID
    var operationType: OperationType
    var status: OperationStatus
    var payloadReference: String
    var createdAt: Date
    var updatedAt: Date
    var retryCount: Int
    var lastError: String?
}
