# M4P5 Enhanced Prompt: Refresh And Retry Coordination For Imported Knowledge

**Date:** 2026-03-26
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This slice adds the first operational coordination layer on top of M4P4. It spans refresh orchestration, stale-source detection, retry semantics, app-bootstrap wiring, and focused tests across networking, imported-knowledge persistence, and lifecycle boundaries. It must preserve offline-first behavior, keep Ask grounded in approved local content only, and avoid overreaching into full OS background-task infrastructure.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow ⏺ M4P5: Refresh and retry coordination — staleness checks and PendingOperation queue.` | M4P5 is the next strict dependency after M4P4. It must operationalize `staleAfter`, durable retry, and automatic refresh coordination so imported knowledge is not a one-shot import. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | The implementation must follow `Plan -> Act -> Verify -> Report`, preserve offline-first guarantees, keep persistence boundaries intact, and mark blocked verification as `unverified`. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M4P1 through M4P4 are complete. M4P5 is explicitly the next dependency before M4P6 Ask online-offer UX can land. |
| `docs/sdlc/05-technical-architecture.md` | `OSA/Networking/Refresh/` is the correct home for refresh coordination. The import pipeline, trusted fetch client, and repository boundaries already exist and should be reused, not redesigned. |
| `docs/sdlc/06-data-model-local-storage.md` | `SourceRecord.staleAfter` and `PendingOperation` already exist in the local data model. M4P5 should consume those fields before adding new schema. |
| `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` | Refresh behavior must be resumable, queued, approval-aware, and must never let partially refreshed or failed remote work corrupt the existing local corpus. Approved imported knowledge may be refreshed automatically; pending sources must not silently enter the assistant corpus. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Ask answers only from approved local evidence. M4P5 must keep refresh backend work behind local persistence and must not introduce live-web answer behavior. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Remote content remains untrusted until it is fetched from an approved source and successfully re-imported into the local store. No user-authored data may be transmitted as part of refresh orchestration. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Stale-content behavior, interrupted imports, queue retry, and online/offline transitions are must-test scenarios, not optional QA. |
| `docs/adr/ADR-0001-offline-first-local-first.md` | Core local functionality must remain available when refresh work is paused, interrupted, or impossible. |
| `docs/adr/ADR-0002-grounded-assistant-only.md` | Imported knowledge remains valid Ask input only after it is approved and stored locally. Refresh must continue to honor that boundary. |
| `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md` | Refresh is allowed only as a local-persistence pipeline; no live page may bypass local commit and citation durability. |
| `docs/prompt/enhanced/27-m4p3-trusted-source-allowlist-and-http-client-enhanced-prompt.md` | M4P3 already solves trusted fetch policy and raw content retrieval. M4P5 must call that client rather than adding a second fetch path. |
| `docs/prompts/enhanced/28-m4p4-import-pipeline-normalization-chunking-local-commit-and-index-extension-enhanced-prompt.md` | M4P4 already normalizes, chunks, persists, dedupes, versions, and indexes approved imported knowledge. M4P5 should orchestrate that pipeline, not duplicate it. |
| `OSA/Domain/ImportedKnowledge/Repositories/ImportedKnowledgeRepository.swift` | `staleSources(asOf:)` already exists and should be the primary stale-source selector. |
| `OSA/Domain/ImportedKnowledge/Repositories/PendingOperationRepository.swift` | Queue storage already supports FIFO queued work, failed-work lookup by retry cap, updates, and purge of completed operations. |
| `OSA/Domain/ImportedKnowledge/Models/OperationType.swift`, `PendingOperation.swift`, `OperationStatus.swift` | The queue currently models stage-oriented operations (`fetch`, `normalize`, `chunk`, `index`) but has no source-level refresh operation or retry semantics for stale known sources. |
| `OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift` | M4P4 centralizes the refreshable unit of work: fetch response in, normalized and indexed local knowledge out, with a 30-day default stale window. |
| `OSA/Domain/Networking/Repositories/ConnectivityRepositories.swift`, `OSA/Networking/Clients/NWPathMonitorConnectivityService.swift` | Connectivity state and the `.syncInProgress` override already exist. M4P5 should reuse them for queue gating and user-visible refresh state. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, `OSA/App/Bootstrap/OSAApp.swift` | The composition root already wires imported-knowledge repository, pending-operation repository, connectivity, trusted fetch client, and import pipeline. M4P5 should add one refresh coordinator and start it from app bootstrap without exposing storage details to feature views. |
| `OSATests/ImportedKnowledgeImportPipelineTests.swift`, `OSATests/PendingOperationRepositoryTests.swift`, `OSATests/ConnectivityServiceTests.swift` | Existing tests already cover the lower layers. M4P5 should add focused coordinator tests and only extend existing suites where the new enum or bootstrap behavior requires it. |

## Mission Statement

Implement M4P5 by adding a serialized refresh coordinator that detects approved stale imported sources from `SourceRecord.staleAfter`, enqueues and retries source-level refresh work through `PendingOperation`, reuses the existing trusted fetch client plus import pipeline to refresh content into the local corpus, and starts automatically on app launch and connectivity recovery without introducing live-web answer behavior or full `BGTaskScheduler` plumbing.

## Technical Context

M4P4 made imported knowledge durable and searchable, but it is still operationally static. `SourceRecord.staleAfter` is written during import and `PendingOperation` is persisted, yet no production code consumes those primitives. That means imported content can age indefinitely, interrupted imports have no retry path, and the app has no automatic way to refresh approved sources when connectivity returns.

M4P5 should solve that narrow but critical gap by adding an automatic in-app coordinator, not a second import pipeline and not a new networking stack. The existing execution chain is already correct:

1. `TrustedSourceHTTPClient` fetches only approved HTTPS sources.
2. `ImportedKnowledgeImportPipeline` normalizes, chunks, persists, dedupes, versions, and indexes local imported knowledge.
3. Ask and local search consume only the approved local corpus.

M4P5 should orchestrate those existing pieces with durable queue semantics:

1. Find active, approved stale sources using `ImportedKnowledgeRepository.staleSources(asOf:)`.
2. Enqueue one source-level refresh operation per stale source if one is not already queued or in progress.
3. Process queued work only when connectivity is `.onlineUsable`.
4. On success, let the existing import pipeline refresh local source metadata and content versions.
5. On failure, persist a retryable failure state with bounded backoff and preserve the last known good local corpus.

Primary assumption for this prompt: M4P5 implements automatic in-app coordination that runs while the app is active, including launch-time catch-up and connectivity-recovery processing. Full `BGTaskScheduler` or `BGAppRefreshTask` registration is deferred because there is no current background-task scaffold in the repository and M4P6 depends on reliable refresh backend behavior, not OS-level scheduling. Make that assumption explicit in the completion report rather than leaving it implicit.

**Rationale:** This keeps the implementation proportional, uses real current seams in the codebase, and avoids entitlements or lifecycle complexity that would obscure the core queue-and-refresh logic.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `SourceRecord.staleAfter` is written by the import pipeline but never consumed by production coordination logic. | Approved stale sources are detected automatically and queued for refresh without requiring the user to manually re-import them. |
| `PendingOperation` persistence exists, but no production service enqueues, drains, retries, or deduplicates refresh work. | The app has one serialized refresh coordinator that owns queue creation, execution, retry, and cleanup. |
| The queue vocabulary is pipeline-stage oriented only and does not represent “refresh this known source”. | The queue can represent source-level refresh work cleanly and durably. |
| Connectivity exposes `.syncInProgress`, but no import-refresh workflow drives it. | Queue execution uses connectivity gating and toggles `.syncInProgress` around actual refresh work. |
| Failed or interrupted imports leave no retry path. | Failures persist a deterministic retry state with bounded retries and explicit backoff. |
| `OSA/Networking/Refresh/` is only a README stub. | `OSA/Networking/Refresh/` contains the concrete coordinator and retry policy for M4P5. |
| There is no automatic refresh trigger in app bootstrap. | App bootstrap starts the refresh coordinator once, and the coordinator reacts to launch plus connectivity recovery. |
| There is no background-task scaffold in current code. | M4P5 stays within in-app automatic coordination and explicitly defers OS-level background task registration. |

## Pre-Flight Checks

1. Confirm the stale-source and queue primitives already exist.

   ```bash
   rg -n "staleSources\(|PendingOperationRepository|enum OperationType|enum OperationStatus" OSA/Domain OSA/Persistence
   ```

   *Success signal: the implementation starts from existing repository and model seams instead of adding a second queue or source-freshness schema.*

2. Confirm the refresh layer is still unimplemented.

   ```bash
   ls OSA/Networking/Refresh
   rg -n "BGTaskScheduler|BGAppRefreshTask" OSA
   ```

   Expected starting point:

   - `OSA/Networking/Refresh` contains only `README.md`
   - No production code references `BGTaskScheduler` or `BGAppRefreshTask`

   *Success signal: M4P5 can stay narrowly focused on a coordinator and queue semantics without refactoring existing background-task code.*

3. Confirm the upstream fetch and import pipeline already exist.

   ```bash
   rg -n "TrustedSourceHTTPClient|ImportedKnowledgeImportPipeline|defaultStaleAfterInterval" OSA/Networking OSA/App
   ```

   *Success signal: the refresh coordinator can reuse the existing fetch and import path instead of duplicating normalization or persistence logic.*

4. Confirm the app bootstrap seam for starting a long-lived service.

   ```bash
   rg -n "struct AppDependencies|@main struct OSAApp|WindowGroup" OSA/App
   ```

   *Success signal: there is one clear place to construct the coordinator and one clear place to start it.*

5. Freeze the milestone boundary before editing.

   *Success signal: the executor can state plainly that M4P5 adds stale checks, queue orchestration, bounded retry, and automatic in-app refresh coordination only. It does not add Ask online-offer UX, candidate-source discovery UI, review UI, or full OS background refresh scheduling.*

## Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the exact imported-knowledge, queue, connectivity, and bootstrap files before coding.

   Required file set:

   - `OSA/Domain/ImportedKnowledge/Repositories/ImportedKnowledgeRepository.swift`
   - `OSA/Domain/ImportedKnowledge/Repositories/PendingOperationRepository.swift`
   - `OSA/Domain/ImportedKnowledge/Models/OperationType.swift`
   - `OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift`
   - `OSA/Domain/Networking/Repositories/ConnectivityRepositories.swift`
   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/App/Bootstrap/OSAApp.swift`

   *Success signal: the implementation plan is grounded in current production seams, not inferred abstractions.*

2. Lock the primary implementation approach.

   Primary approach for M4P5:

   - Add an automatic in-app coordinator in `OSA/Networking/Refresh/`
   - Start it from `OSA/App/Bootstrap/OSAApp.swift`
   - Reuse `TrustedSourceHTTPClient` plus `ImportedKnowledgeImportPipeline`
   - Reuse `PendingOperationRepository` as the durable queue
   - Defer `BGTaskScheduler` integration

   *Success signal: there is one chosen approach and the implementation does not branch into both app-session coordination and OS-level background scheduling.*

3. Lock the queue granularity.

   Use one source-level queue item per known source refresh. Store the `SourceRecord.id.uuidString` in `PendingOperation.payloadReference`.

   ```swift
   // Required new operation kind for M4P5
   case refreshKnownSource
   ```

   *Success signal: queue items represent “refresh this approved source” rather than exposing the internal fetch-normalize-chunk-index stages as separate queued records.*

### Phase 2: Add Refresh Queue Semantics

1. Update `OSA/Domain/ImportedKnowledge/Models/OperationType.swift` to add a source-level refresh operation.

   Required result:

   ```swift
   enum OperationType: String, Codable, CaseIterable, Equatable, Sendable {
       case fetch
       case normalize
       case chunk
       case index
       case refreshKnownSource
   }
   ```

   *Success signal: the durable queue has an explicit operation type for stale-source refreshes.*

2. Keep `PendingOperation` storage minimal in this phase.

   Do **not** add `nextAttemptAt` or other new persisted fields unless blocked. Derive retry eligibility from `updatedAt` plus a deterministic backoff policy.

   *Success signal: M4P5 reuses the current queue schema and avoids unnecessary migration churn.*

3. Create `OSA/Networking/Refresh/RefreshRetryPolicy.swift` with explicit, testable retry rules.

   Required shape:

   ```swift
   import Foundation

   enum RefreshRetryPolicy {
       static let maxRetries = 3

       static func nextEligibleDate(for operation: PendingOperation) -> Date
       static func canRetry(_ operation: PendingOperation, asOf date: Date) -> Bool
   }
   ```

   Required schedule:

   - retry 1: 5 minutes after failure
   - retry 2: 15 minutes after failure
   - retry 3: 60 minutes after failure
   - stop retrying after `retryCount >= 3`

   *Success signal: retry behavior is deterministic, persisted across relaunch through existing fields, and bounded.*

4. Use existing `PendingOperationRepository` APIs in this phase.

   Reuse:

   - `listOperations(status:)`
   - `nextQueued()`
   - `failedOperations(maxRetries:)`
   - `updateOperation(_:)`
   - `purgeCompleted()`

   Do not add new repository queries unless compilation or duplicate-suppression becomes impossible with the current API.

   *Success signal: repository surface area remains stable and the queue logic stays concentrated in the coordinator.*

### Phase 3: Implement The Refresh Coordinator

1. Create `OSA/Networking/Refresh/ImportedKnowledgeRefreshCoordinator.swift` as a serialized coordinator.

   Preferred shape:

   ```swift
   import Foundation

   actor ImportedKnowledgeRefreshCoordinator {
       func start() async
   }
   ```

   Required dependencies:

   - `ImportedKnowledgeRepository`
   - `PendingOperationRepository`
   - `ConnectivityService`
   - `TrustedSourceHTTPClient`
   - `ImportedKnowledgeImportPipeline`
   - a testable `now` closure or clock dependency

   *Success signal: refresh orchestration is centralized in one serialized production type and does not leak into views or repositories.*

2. Make `start()` idempotent and responsible for both startup catch-up and connectivity observation.

   Required behavior:

   - perform one immediate stale-source enqueue plus queue-drain pass
   - subscribe to `connectivityService.stateStream()`
   - when state becomes `.onlineUsable`, enqueue stale approved sources and process eligible work
   - ignore `.offline` and `.onlineConstrained` for actual queue execution

   *Success signal: the coordinator starts once, does not duplicate observers, and automatically reacts to launch plus connectivity recovery.*

3. Enqueue stale approved sources only.

   Required selection logic:

   - call `importedKnowledgeRepository.staleSources(asOf: now)`
   - filter to `source.isActive == true`
   - filter to `source.reviewStatus == .approved`
   - do not auto-refresh `.pending` or `.rejected` sources

   Before enqueueing, dedupe against existing queued or in-progress `refreshKnownSource` operations using `payloadReference == source.id.uuidString`.

   *Success signal: only approved stale sources enter automatic refresh, and each stale source gets at most one active queue item.*

4. Process the queue in FIFO order and reuse the existing import pipeline.

   Required execution flow per operation:

   1. confirm connectivity is `.onlineUsable`
   2. mark operation `.inProgress` and set `updatedAt = now`
   3. set `connectivityService.setSyncInProgress()` on the main actor
   4. resolve the source from `payloadReference`
   5. fetch `source.sourceURL` through `trustedSourceHTTPClient.fetch(_:)`
   6. pass the response into `importPipeline.importFetchedContent(_:)`
   7. mark the operation `.completed`
   8. clear `.syncInProgress` override on the main actor

   *Success signal: refresh work runs through the same trusted fetch and local import path as manual import, with no parallel codepath for persistence or indexing.*

5. Fail safely and preserve the last known good local corpus.

   On failure:

   - set operation `.failed`
   - increment `retryCount`
   - write `lastError`
   - update `updatedAt`
   - clear `.syncInProgress`
   - do **not** delete or alter the existing approved local content for that source

   *Success signal: failed refresh attempts remain visible and retryable, and the current offline corpus stays intact.*

6. Clean up completed work without losing failure evidence.

   After a successful processing cycle, call `pendingOperationRepository.purgeCompleted()`.

   *Success signal: the queue stays small, while failed operations remain persisted for later retry until they exhaust retry budget.*

7. Keep the coordinator fully backend-facing.

   Do not add new feature-layer views, settings toggles, or manual refresh UI in M4P5.

   *Success signal: all changes stay inside `OSA/Networking/Refresh/`, imported-knowledge models, tests, and app bootstrap wiring.*

### Phase 4: Wire The Coordinator Into App Bootstrap

1. Update `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` to construct the refresh coordinator.

   Required addition:

   - one stored `refreshCoordinator` dependency
   - live construction that reuses the already-built imported-knowledge repository, pending-operation repository, connectivity service, trusted fetch client, and import pipeline

   *Success signal: there is one live refresh coordinator in the composition root, and no feature code constructs it directly.*

2. Start the coordinator from `OSA/App/Bootstrap/OSAApp.swift` using a root-level task.

   Required shape:

   ```swift
   .task {
       await dependencies.refreshCoordinator.start()
   }
   ```

   The coordinator itself must be idempotent so the app bootstrap code remains simple.

   *Success signal: refresh coordination begins automatically without user intervention and without adding a new environment key or UI trigger.*

3. Do not expose the coordinator to feature views in this phase.

   *Success signal: `RepositoryEnvironment.swift` remains unchanged unless the compiler requires a minimal no-op surface for previews or testing.*

### Phase 5: Add Focused Tests

1. Create `OSATests/ImportedKnowledgeRefreshCoordinatorTests.swift` using fakes or spies for all coordinator dependencies.

   Cover at least these cases:

   - startup enqueues and refreshes one approved stale source successfully
   - stale but pending source is not enqueued automatically
   - offline or constrained connectivity prevents queue execution
   - failure marks operation failed, increments retry count, and stores `lastError`
   - retry eligibility respects `RefreshRetryPolicy` and `maxRetries`
   - connectivity recovery from offline to online usable triggers processing of previously queued work
   - `start()` is idempotent and does not enqueue duplicate operations or duplicate connectivity listeners

   *Success signal: the coordinator’s behavior is test-covered without depending on live network or real app lifecycle transitions.*

2. Update `OSATests/PendingOperationRepositoryTests.swift` to cover the new `refreshKnownSource` operation type.

   Minimum expectation:

   - create, persist, load, and update a `PendingOperation` whose `operationType == .refreshKnownSource`

   *Success signal: the queue persistence layer explicitly round-trips the new operation type.*

3. Add focused tests for `RefreshRetryPolicy` if that policy is implemented in a separate file.

   Required assertions:

   - retry window 1 is 5 minutes
   - retry window 2 is 15 minutes
   - retry window 3 is 60 minutes
   - retry is denied after `maxRetries`

   *Success signal: backoff behavior is executable documentation, not a comment-only rule.*

4. Reuse existing lower-layer tests rather than duplicating them.

   Do not rewrite M4P3 fetch-guard tests or M4P4 import-pipeline tests in the M4P5 suite.

   *Success signal: the new tests stay focused on coordination, queue semantics, and lifecycle triggers.*

### Phase 6: Verification

1. Run the full test suite for the app scheme.

   ```bash
   xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```

   *Success signal: tests pass, or the exact environment blocker is recorded and the affected verification is marked `unverified`.*

2. Run a focused source search to confirm the coordinator is wired exactly once.

   ```bash
   rg -n "ImportedKnowledgeRefreshCoordinator|refreshCoordinator|refreshKnownSource" OSA OSATests
   ```

   *Success signal: one production coordinator exists, one bootstrap wiring path exists, and the new operation type appears only where intended.*

3. Run a security scan because M4P5 adds first-party networking orchestration and background-like automation.

   ```bash
   snyk code test --path="$PWD"
   ```

   *Success signal: no new high-signal security findings are introduced, or exact findings are reported with severity and scope.*

4. Manually verify the milestone boundary.

   ```bash
   rg -n "BGTaskScheduler|BGAppRefreshTask|online search|review UI|candidate source" OSA docs
   ```

   *Success signal: the implementation stays inside M4P5 and does not quietly absorb M4P6 UI work or OS background scheduling.*

### Phase 7: Security And Quality Review

1. Verify that refresh only runs against already-approved local sources.

   *Success signal: `.pending` or unverified imported sources are not auto-refreshed into the approved corpus.*

2. Verify that failures never remove the last good local version of a source.

   *Success signal: queue failures affect operation state only; they do not delete current searchable documents or chunks.*

3. Verify that refresh work does not transmit user-authored notes, inventory, or checklist data.

   *Success signal: only the approved source URL is fetched through `TrustedSourceHTTPClient`.*

4. Verify that the coordinator does not run on constrained networks.

   *Success signal: actual queue execution is limited to `.onlineUsable`, which respects the product guidance to avoid aggressive background-like behavior on constrained connections.*

## Guardrails

- **Forbidden:** Adding Ask online-search offer UI, candidate-source discovery UI, source-review UI, or any other M4P6 user-facing work.
- **Forbidden:** Adding `BGTaskScheduler`, `BGAppRefreshTask`, background `URLSession`, or entitlement/configuration plumbing in this phase.
- **Forbidden:** Introducing a second fetch path, a second import pipeline, or direct SwiftData access in `OSA/Networking/Refresh/`.
- **Forbidden:** Auto-refreshing `.pending`, `.rejected`, inactive, or unknown sources.
- **Forbidden:** Deleting or replacing the last known good local source content when a refresh attempt fails.
- **Required:** Reuse `TrustedSourceHTTPClient`, `ImportedKnowledgeImportPipeline`, `ImportedKnowledgeRepository`, and `PendingOperationRepository`.
- **Required:** Retry behavior must be deterministic, bounded, and test-covered.
- **Required:** Queue execution must be gated on `.onlineUsable` connectivity and must drive `.syncInProgress` during real work.
- **Required:** Any blocked verification must be reported as `unverified` with the exact command and failure mode.
- **Budget:** Prefer one coordinator file, one retry-policy file, minimal model/bootstrap edits, and focused tests. Do not widen the persistence schema unless the current fields are provably insufficient.

## Verification Checklist

- [ ] Prompt type is classified as `Feature`
- [ ] Complexity is classified as `Complex` with justification
- [ ] Mission statement is one sentence and unambiguous
- [ ] Technical context explains why M4P5 should be an in-app automatic coordinator instead of full OS background-task work
- [ ] All production file paths are explicit
- [ ] All terminal commands are complete and copy-pasteable
- [ ] Instructions are phased from investigation through verification and security review
- [ ] Every implementation step includes an explicit success signal in italics
- [ ] Queue semantics use `PendingOperation` durably and do not create a second queue
- [ ] `SourceRecord.staleAfter` is explicitly consumed by the coordinator
- [ ] Approved stale sources are auto-enqueued and pending sources are excluded
- [ ] Retry logic is bounded, deterministic, and test-covered
- [ ] App bootstrap starts the coordinator automatically without exposing it to feature views
- [ ] `BGTaskScheduler` and M4P6 UI work are explicitly out of scope
- [ ] Report format specifies files changed, assumptions, verification, and blockers

## Error Handling

| Error Condition | Resolution |
| --- | --- |
| Source URL in `payloadReference` cannot be parsed back to a valid source ID | Mark the operation `.failed`, write a precise `lastError`, increment `retryCount`, and continue processing other work. Do not crash the coordinator. |
| `ImportedKnowledgeRepository.source(id:)` returns `nil` for a queued refresh | Mark the operation `.failed` with a missing-source error and continue. Purge only completed items, not failed diagnostics. |
| Connectivity becomes offline mid-refresh | Clear `.syncInProgress`, mark the operation `.failed`, persist the error, and rely on retry plus connectivity recovery to resume later. |
| Fetch returns a trusted-client error | Persist the failure on the operation and let `RefreshRetryPolicy` decide the next eligible attempt. |
| Import pipeline throws during normalization or persistence | Persist the failure on the operation and preserve the current local searchable version for that source. |
| Duplicate stale-source operations are about to be enqueued | Skip enqueue for any source that already has a queued or in-progress `refreshKnownSource` operation. |
| Retry budget is exhausted | Leave the operation failed, do not auto-requeue it again, and report the exhausted item in completion output as deferred or manual-follow-up. |
| `xcodebuild` cannot run because full Xcode is unavailable or simulator tooling is blocked | Report the exact command, failure text, and date; keep verification `unverified` rather than claiming pass. |
| `snyk` is unavailable | Report the missing tool explicitly and keep the security verification `unverified`. |

## Out Of Scope

- `BGTaskScheduler`, `BGAppRefreshTask`, or background-entitlement plumbing
- Manual refresh buttons or refresh status UI beyond existing connectivity state
- Candidate-source discovery and Ask online-offer UX for M4P6
- Source-review or approval UI for pending Tier 3 sources
- Telemetry, analytics, or remote diagnostics export
- Changes to the default 30-day stale window beyond central reuse of the existing import-pipeline constant
- New persistence fields or migrations unless the current queue schema proves insufficient during implementation

## Alternative Solutions

1. **Fallback A: Reuse `OperationType.fetch` instead of adding `refreshKnownSource`.** Pros: no enum expansion and zero persistence-schema ripple. Cons: refresh queue intent becomes opaque, stage-level and source-level work blur together, and tests become less readable.
2. **Fallback B: Trigger the coordinator from scene-activation events instead of a root `.task`.** Pros: slightly more explicit lifecycle control. Cons: more app-lifecycle plumbing and more moving parts than needed if `start()` is already idempotent.
3. **Fallback C: Add a persisted `nextAttemptAt` field if `updatedAt`-based backoff proves too ambiguous.** Pros: retry eligibility becomes queryable directly. Cons: introduces schema churn and broader M4P5 scope. Use only if the current fields are demonstrably insufficient.

## Report Format

When completing the M4P5 task, report in this exact structure:

1. **Mission outcome:** one sentence stating whether stale checks, queue retry, and automatic refresh coordination were implemented.
2. **Files changed:** list every production and test file modified or created.
3. **Queue semantics:** state the chosen `OperationType`, `payloadReference` format, retry schedule, and retry cap.
4. **Bootstrap behavior:** state where the coordinator is constructed and where it is started.
5. **Verification evidence:** list each command run and whether it passed or is `unverified`.
6. **Security status:** summarize the `snyk` result or the exact blocker.
7. **Assumptions:** explicitly restate that M4P5 uses in-app automatic coordination and defers full OS background-task scheduling.
8. **Deferred work:** list any follow-up items left for M4P6 or a later hardening pass.
