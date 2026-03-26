import Foundation

/// Repository contract for managing queued import pipeline operations.
protocol PendingOperationRepository {
    func listOperations(status: OperationStatus?) throws -> [PendingOperation]
    func operation(id: UUID) throws -> PendingOperation?
    func createOperation(_ operation: PendingOperation) throws
    func updateOperation(_ operation: PendingOperation) throws
    func deleteOperation(id: UUID) throws

    /// Returns the next queued operation, ordered by creation date (FIFO).
    func nextQueued() throws -> PendingOperation?

    /// Returns all failed operations eligible for retry (retryCount < maxRetries).
    func failedOperations(maxRetries: Int) throws -> [PendingOperation]

    /// Removes all completed operations.
    func purgeCompleted() throws
}
