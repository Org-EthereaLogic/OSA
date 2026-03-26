# Refresh

Refresh coordination, staleness checks, and retry behavior for approved sources.

## M4P5: Refresh And Retry Coordination (Complete)

- `RefreshRetryPolicy`: Deterministic bounded backoff — retry 1 at 5 minutes, retry 2 at 15 minutes, retry 3 at 60 minutes. Stops after `maxRetries` (3). Derives eligibility from `PendingOperation.updatedAt` plus backoff interval.
- `ImportedKnowledgeRefreshCoordinator`: Serialized coordinator that detects stale approved sources via `staleSources(asOf:)`, enqueues `refreshKnownSource` operations through `PendingOperationRepository`, and drains the queue when connectivity is `.onlineUsable`. Dedupes against existing queued/in-progress operations. Re-queues retry-eligible failed operations. Starts automatically from `OSAApp.swift` via `.task` — idempotent, does not duplicate observers. Does not use `BGTaskScheduler` or background `URLSession` (deferred to hardening).
