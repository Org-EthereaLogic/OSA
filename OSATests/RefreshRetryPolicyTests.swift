import Foundation
import Testing
@testable import OSA

@Suite("RefreshRetryPolicy")
struct RefreshRetryPolicyTests {

    private func makeOperation(retryCount: Int, updatedAt: Date = Date()) -> PendingOperation {
        PendingOperation(
            id: UUID(),
            operationType: .refreshKnownSource,
            status: .failed,
            payloadReference: UUID().uuidString,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            retryCount: retryCount,
            lastError: "test error"
        )
    }

    @Test("Retry 1 window is 5 minutes")
    func retryWindow1() {
        let op = makeOperation(retryCount: 0)
        let eligible = RefreshRetryPolicy.nextEligibleDate(for: op)
        let expected = op.updatedAt.addingTimeInterval(5 * 60)
        #expect(abs(eligible.timeIntervalSince(expected)) < 1)
    }

    @Test("Retry 2 window is 15 minutes")
    func retryWindow2() {
        let op = makeOperation(retryCount: 1)
        let eligible = RefreshRetryPolicy.nextEligibleDate(for: op)
        let expected = op.updatedAt.addingTimeInterval(15 * 60)
        #expect(abs(eligible.timeIntervalSince(expected)) < 1)
    }

    @Test("Retry 3 window is 60 minutes")
    func retryWindow3() {
        let op = makeOperation(retryCount: 2)
        let eligible = RefreshRetryPolicy.nextEligibleDate(for: op)
        let expected = op.updatedAt.addingTimeInterval(60 * 60)
        #expect(abs(eligible.timeIntervalSince(expected)) < 1)
    }

    @Test("Retry denied after maxRetries")
    func retryDeniedAfterMax() {
        let op = makeOperation(retryCount: 3)
        let canRetry = RefreshRetryPolicy.canRetry(op, asOf: Date.distantFuture)
        #expect(!canRetry)
    }

    @Test("canRetry returns false before eligible date")
    func canRetryBeforeEligible() {
        let past = Date().addingTimeInterval(-10)
        let op = makeOperation(retryCount: 0, updatedAt: past)
        // Too early — only 10 seconds have passed, need 5 minutes
        let canRetry = RefreshRetryPolicy.canRetry(op, asOf: Date())
        #expect(!canRetry)
    }

    @Test("canRetry returns true after eligible date")
    func canRetryAfterEligible() {
        let past = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let op = makeOperation(retryCount: 0, updatedAt: past)
        let canRetry = RefreshRetryPolicy.canRetry(op, asOf: Date())
        #expect(canRetry)
    }
}
