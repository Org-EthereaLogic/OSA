import Foundation

/// Deterministic, bounded retry policy for imported-knowledge refresh operations.
///
/// Schedule:
/// - Retry 1: 5 minutes after failure
/// - Retry 2: 15 minutes after failure
/// - Retry 3: 60 minutes after failure
/// - No further retries after `maxRetries` (3)
enum RefreshRetryPolicy {

    static let maxRetries = 3

    /// Backoff intervals indexed by retry attempt (0-based).
    private static let backoffIntervals: [TimeInterval] = [
        5 * 60,     // 5 minutes
        15 * 60,    // 15 minutes
        60 * 60,    // 60 minutes
    ]

    /// Returns the earliest date at which the operation becomes eligible for retry.
    static func nextEligibleDate(for operation: PendingOperation) -> Date {
        let index = min(operation.retryCount, backoffIntervals.count - 1)
        let interval = backoffIntervals[index]
        return operation.updatedAt.addingTimeInterval(interval)
    }

    /// Returns `true` if the operation is eligible for retry at the given date.
    static func canRetry(_ operation: PendingOperation, asOf date: Date) -> Bool {
        guard operation.retryCount < maxRetries else { return false }
        return date >= nextEligibleDate(for: operation)
    }
}
