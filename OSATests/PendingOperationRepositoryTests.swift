import SwiftData
import XCTest
@testable import OSA

@MainActor
final class PendingOperationRepositoryTests: XCTestCase {

    private static var sharedContainer: ModelContainer = {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedSeedContentState.self,
            PersistedInventoryItem.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self,
            PersistedChecklistRun.self,
            PersistedChecklistRunItem.self,
            PersistedNoteRecord.self,
            PersistedSourceRecord.self,
            PersistedImportedKnowledgeDocument.self,
            PersistedKnowledgeChunk.self,
            PersistedPendingOperation.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    private func makeRepository() -> SwiftDataPendingOperationRepository {
        SwiftDataPendingOperationRepository(modelContext: Self.sharedContainer.mainContext)
    }

    private func cleanStore() throws {
        let context = Self.sharedContainer.mainContext
        let ops = try context.fetch(FetchDescriptor<PersistedPendingOperation>())
        for op in ops { context.delete(op) }
        try context.save()
    }

    func testCreateAndListOperations() throws {
        try cleanStore()
        let repository = makeRepository()

        let operation = makeOperation(type: .fetch, status: .queued)
        try repository.createOperation(operation)

        let operations = try repository.listOperations(status: nil)
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations.first?.operationType, .fetch)
        XCTAssertEqual(operations.first?.status, .queued)
    }

    func testOperationByID() throws {
        try cleanStore()
        let repository = makeRepository()

        let operation = makeOperation(type: .normalize, status: .inProgress)
        try repository.createOperation(operation)

        let fetched = try XCTUnwrap(repository.operation(id: operation.id))
        XCTAssertEqual(fetched.operationType, .normalize)
        XCTAssertEqual(fetched.status, .inProgress)
    }

    func testOperationByIDReturnsNilForUnknownID() throws {
        try cleanStore()
        let repository = makeRepository()

        let result = try repository.operation(id: UUID())
        XCTAssertNil(result)
    }

    func testUpdateOperation() throws {
        try cleanStore()
        let repository = makeRepository()

        var operation = makeOperation(type: .fetch, status: .queued)
        try repository.createOperation(operation)

        operation.status = .completed
        operation.updatedAt = Date()
        try repository.updateOperation(operation)

        let fetched = try XCTUnwrap(repository.operation(id: operation.id))
        XCTAssertEqual(fetched.status, .completed)
    }

    func testDeleteOperation() throws {
        try cleanStore()
        let repository = makeRepository()

        let operation = makeOperation(type: .chunk, status: .queued)
        try repository.createOperation(operation)

        try repository.deleteOperation(id: operation.id)

        let result = try repository.operation(id: operation.id)
        XCTAssertNil(result)
    }

    func testListOperationsFilteredByStatus() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createOperation(makeOperation(type: .fetch, status: .queued))
        try repository.createOperation(makeOperation(type: .normalize, status: .completed))
        try repository.createOperation(makeOperation(type: .chunk, status: .failed))

        let queued = try repository.listOperations(status: .queued)
        XCTAssertEqual(queued.count, 1)
        XCTAssertEqual(queued.first?.operationType, .fetch)

        let completed = try repository.listOperations(status: .completed)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.operationType, .normalize)
    }

    func testNextQueuedReturnsFIFO() throws {
        try cleanStore()
        let repository = makeRepository()

        let earlier = makeOperation(
            type: .fetch,
            status: .queued,
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let later = makeOperation(
            type: .normalize,
            status: .queued,
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        )

        try repository.createOperation(later)
        try repository.createOperation(earlier)

        let next = try XCTUnwrap(repository.nextQueued())
        XCTAssertEqual(next.operationType, .fetch)
    }

    func testNextQueuedReturnsNilWhenEmpty() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createOperation(makeOperation(type: .fetch, status: .completed))

        let next = try repository.nextQueued()
        XCTAssertNil(next)
    }

    func testFailedOperationsRespectMaxRetries() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createOperation(makeOperation(type: .fetch, status: .failed, retryCount: 1))
        try repository.createOperation(makeOperation(type: .normalize, status: .failed, retryCount: 3))
        try repository.createOperation(makeOperation(type: .chunk, status: .failed, retryCount: 5))

        let retryable = try repository.failedOperations(maxRetries: 3)
        XCTAssertEqual(retryable.count, 1)
        XCTAssertEqual(retryable.first?.retryCount, 1)
    }

    func testPurgeCompleted() throws {
        try cleanStore()
        let repository = makeRepository()

        try repository.createOperation(makeOperation(type: .fetch, status: .completed))
        try repository.createOperation(makeOperation(type: .normalize, status: .completed))
        try repository.createOperation(makeOperation(type: .chunk, status: .queued))
        try repository.createOperation(makeOperation(type: .index, status: .failed))

        try repository.purgeCompleted()

        let remaining = try repository.listOperations(status: nil)
        XCTAssertEqual(remaining.count, 2)
        XCTAssertTrue(remaining.allSatisfy { $0.status != .completed })
    }

    func testOperationLastErrorRoundTrip() throws {
        try cleanStore()
        let repository = makeRepository()

        let operation = makeOperation(
            type: .fetch,
            status: .failed,
            lastError: "Network timeout after 30s"
        )
        try repository.createOperation(operation)

        let fetched = try XCTUnwrap(repository.operation(id: operation.id))
        XCTAssertEqual(fetched.lastError, "Network timeout after 30s")
    }

    func testOperationWithNilLastError() throws {
        try cleanStore()
        let repository = makeRepository()

        let operation = makeOperation(type: .fetch, status: .queued, lastError: nil)
        try repository.createOperation(operation)

        let fetched = try XCTUnwrap(repository.operation(id: operation.id))
        XCTAssertNil(fetched.lastError)
    }

    func testUpdateOperationRetryCountAndError() throws {
        try cleanStore()
        let repository = makeRepository()

        var operation = makeOperation(type: .fetch, status: .queued)
        try repository.createOperation(operation)

        operation.status = .failed
        operation.retryCount = 2
        operation.lastError = "Connection refused"
        operation.updatedAt = Date()
        try repository.updateOperation(operation)

        let fetched = try XCTUnwrap(repository.operation(id: operation.id))
        XCTAssertEqual(fetched.status, .failed)
        XCTAssertEqual(fetched.retryCount, 2)
        XCTAssertEqual(fetched.lastError, "Connection refused")
    }

    // MARK: - Helpers

    private func makeOperation(
        type: OperationType,
        status: OperationStatus,
        retryCount: Int = 0,
        lastError: String? = nil,
        createdAt: Date = Date()
    ) -> PendingOperation {
        PendingOperation(
            id: UUID(),
            operationType: type,
            status: status,
            payloadReference: "ref-\(UUID().uuidString.prefix(8))",
            createdAt: createdAt,
            updatedAt: createdAt,
            retryCount: retryCount,
            lastError: lastError
        )
    }
}
