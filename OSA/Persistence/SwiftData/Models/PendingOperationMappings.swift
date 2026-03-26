import Foundation

extension PersistedPendingOperation {
    convenience init(from operation: PendingOperation) {
        self.init(
            id: operation.id,
            operationTypeRawValue: operation.operationType.rawValue,
            statusRawValue: operation.status.rawValue,
            payloadReference: operation.payloadReference,
            createdAt: operation.createdAt,
            updatedAt: operation.updatedAt,
            retryCount: operation.retryCount,
            lastError: operation.lastError
        )
    }

    func update(from operation: PendingOperation) {
        operationTypeRawValue = operation.operationType.rawValue
        statusRawValue = operation.status.rawValue
        payloadReference = operation.payloadReference
        updatedAt = operation.updatedAt
        retryCount = operation.retryCount
        lastError = operation.lastError
    }

    func toDomain() -> PendingOperation {
        PendingOperation(
            id: id,
            operationType: OperationType(rawValue: operationTypeRawValue) ?? .fetch,
            status: OperationStatus(rawValue: statusRawValue) ?? .queued,
            payloadReference: payloadReference,
            createdAt: createdAt,
            updatedAt: updatedAt,
            retryCount: retryCount,
            lastError: lastError
        )
    }
}
