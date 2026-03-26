import Foundation

/// Serialized coordinator that detects approved stale imported sources,
/// enqueues source-level refresh work through `PendingOperation`, and
/// drains the queue when connectivity is usable.
///
/// Runs automatically during the app session. Does not use
/// `BGTaskScheduler` or background `URLSession` — those are deferred
/// to a later hardening phase.
final class ImportedKnowledgeRefreshCoordinator: @unchecked Sendable {

    private let importedKnowledgeRepository: any ImportedKnowledgeRepository
    private let pendingOperationRepository: any PendingOperationRepository
    private let connectivityService: any ConnectivityService
    private let httpClient: any TrustedSourceHTTPClient
    private let importPipeline: ImportedKnowledgeImportPipeline
    private let now: @Sendable () -> Date

    private var isStarted = false

    init(
        importedKnowledgeRepository: any ImportedKnowledgeRepository,
        pendingOperationRepository: any PendingOperationRepository,
        connectivityService: any ConnectivityService,
        httpClient: any TrustedSourceHTTPClient,
        importPipeline: ImportedKnowledgeImportPipeline,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.importedKnowledgeRepository = importedKnowledgeRepository
        self.pendingOperationRepository = pendingOperationRepository
        self.connectivityService = connectivityService
        self.httpClient = httpClient
        self.importPipeline = importPipeline
        self.now = now
    }

    // MARK: - Public API

    /// Starts the coordinator. Idempotent — calling more than once has no effect.
    ///
    /// Performs an immediate stale-source enqueue and queue drain, then
    /// subscribes to connectivity changes to process work when online.
    func start() async {
        guard !isStarted else { return }
        isStarted = true

        // Immediate catch-up pass
        await enqueueAndProcess()

        // Subscribe to connectivity changes
        let stream = await MainActor.run { connectivityService.stateStream() }
        for await state in stream {
            if state == .onlineUsable {
                await enqueueAndProcess()
            }
        }
    }

    // MARK: - Core Loop

    private func enqueueAndProcess() async {
        do {
            try enqueueStaleApprovedSources()
            try requeueEligibleFailures()
            await processQueue()
            try? pendingOperationRepository.purgeCompleted()
        } catch {
            // Non-fatal — coordinator continues observing connectivity
        }
    }

    // MARK: - Stale Source Enqueue

    private func enqueueStaleApprovedSources() throws {
        let currentDate = now()
        let staleSources = try importedKnowledgeRepository.staleSources(asOf: currentDate)

        // Filter to active, approved only
        let eligible = staleSources.filter { $0.isActive && $0.reviewStatus == .approved }

        // Get existing queued/in-progress refresh operations to dedupe
        let existingOps = try pendingOperationRepository.listOperations(status: nil)
        let activeRefreshPayloads = Set(
            existingOps
                .filter { op in
                    op.operationType == .refreshKnownSource &&
                    (op.status == .queued || op.status == .inProgress)
                }
                .map(\.payloadReference)
        )

        for source in eligible {
            let ref = source.id.uuidString
            guard !activeRefreshPayloads.contains(ref) else { continue }

            let operation = PendingOperation(
                id: UUID(),
                operationType: .refreshKnownSource,
                status: .queued,
                payloadReference: ref,
                createdAt: currentDate,
                updatedAt: currentDate,
                retryCount: 0,
                lastError: nil
            )
            try pendingOperationRepository.createOperation(operation)
        }
    }

    // MARK: - Retry Re-queue

    private func requeueEligibleFailures() throws {
        let currentDate = now()
        let failed = try pendingOperationRepository.failedOperations(maxRetries: RefreshRetryPolicy.maxRetries)
        let refreshFailed = failed.filter { $0.operationType == .refreshKnownSource }

        for failedOp in refreshFailed {
            guard RefreshRetryPolicy.canRetry(failedOp, asOf: currentDate) else { continue }
            var updated = failedOp
            updated.status = .queued
            updated.updatedAt = currentDate
            try pendingOperationRepository.updateOperation(updated)
        }
    }

    // MARK: - Queue Processing

    private func processQueue() async {
        while true {
            // Check connectivity before each item
            let state = await MainActor.run { connectivityService.currentState }
            guard state == .onlineUsable else { break }

            guard let operation = try? pendingOperationRepository.nextQueued(),
                  operation.operationType == .refreshKnownSource else { break }

            await processOperation(operation)
        }
    }

    private func processOperation(_ operation: PendingOperation) async {
        let currentDate = now()

        // Mark in-progress
        var op = operation
        op.status = .inProgress
        op.updatedAt = currentDate
        try? pendingOperationRepository.updateOperation(op)

        // Set sync-in-progress
        await MainActor.run { connectivityService.setSyncInProgress() }

        defer {
            Task { @MainActor [connectivityService] in
                connectivityService.clearSyncInProgress()
            }
        }

        // Resolve source
        guard let sourceID = UUID(uuidString: operation.payloadReference),
              let source = try? importedKnowledgeRepository.source(id: sourceID) else {
            op.status = .failed
            op.lastError = "Source not found for ID: \(operation.payloadReference)"
            op.retryCount += 1
            op.updatedAt = now()
            try? pendingOperationRepository.updateOperation(op)
            return
        }

        // Fetch
        guard let url = URL(string: source.sourceURL) else {
            op.status = .failed
            op.lastError = "Invalid source URL: \(source.sourceURL)"
            op.retryCount += 1
            op.updatedAt = now()
            try? pendingOperationRepository.updateOperation(op)
            return
        }

        do {
            let response = try await httpClient.fetch(url)
            try importPipeline.importFetchedContent(response)

            // Success
            op.status = .completed
            op.updatedAt = now()
            try? pendingOperationRepository.updateOperation(op)
        } catch {
            op.status = .failed
            op.lastError = String(describing: error)
            op.retryCount += 1
            op.updatedAt = now()
            try? pendingOperationRepository.updateOperation(op)
        }
    }
}
