# Quality Strategy, Test Plan, And Acceptance

Status: Initial draft complete.  
Related docs: [PRD](./02-prd.md), [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Release Readiness](./12-release-readiness-and-app-store-plan.md), [Risk Register](./risk-register.md)

## Confirmed Facts

- Offline reliability, grounding quality, and safety boundaries are first-order quality concerns.
- The repository contains complete Milestone 1, 2, 3, and M4P1–P5 implementations. Unit-test and UI-test target scaffolding are in place. Repository-contract tests exist for editorial content (`OSATests/SeedContentRepositoryTests.swift`), inventory (`OSATests/InventoryRepositoryTests.swift`), checklists (`OSATests/ChecklistRepositoryTests.swift`), notes (`OSATests/NoteRepositoryTests.swift`), imported knowledge (`OSATests/ImportedKnowledgeRepositoryTests.swift`), pending operations (`OSATests/PendingOperationRepositoryTests.swift`), and the FTS5 search index (`OSATests/SearchIndexStoreTests.swift`). Connectivity tests (`OSATests/ConnectivityServiceTests.swift`) cover NWPathMonitor state mapping, stream multicasting, sync override, and preview service behavior. Trusted-source allowlist tests (`OSATests/TrustedSourceAllowlistTests.swift`) cover allowlist resolution across all three tiers, unknown domain rejection, subdomain rejection, missing host handling, and case-insensitive lookup. Trusted-source HTTP client tests (`OSATests/TrustedSourceHTTPClientTests.swift`) cover successful fetch, offline rejection, non-HTTPS rejection, unknown host rejection, bad status code, unsupported content type, oversized payload, redirect to unapproved host, redirect to approved host, and text/plain content type — all via stubbed `URLProtocol` with no live network dependency. Import pipeline tests: normalizer tests (`OSATests/ImportedKnowledgeNormalizerTests.swift`) cover HTML and plain-text normalization, title derivation (title tag, h1, URL fallback), document-type classification, content-hash stability, empty content, and unsupported content type; chunker tests (`OSATests/KnowledgeChunkerTests.swift`) cover heading-aware splitting, paragraph fallback, sort order, non-empty chunks, deterministic local chunk IDs, searchable gating, trust-level inheritance, and tag application; pipeline integration tests (`OSATests/ImportedKnowledgeImportPipelineTests.swift`) cover first import with indexing, pending source gating, same-hash dedupe, changed-content versioning, empty content failure, and source field population. Refresh and retry tests: `RefreshRetryPolicyTests` (6 tests) cover backoff windows (5/15/60 minute intervals), retry denial after max retries, and eligibility date-based gating; `ImportedKnowledgeRefreshCoordinatorTests` (6 tests) cover startup stale-source enqueue, pending-source filtering, offline connectivity gating, failure handling with retry state, idempotency, and duplicate-enqueue prevention. Retrieval pipeline tests cover query normalization (`OSATests/QueryNormalizerTests.swift`), sensitivity policy (`OSATests/SensitivityPolicyTests.swift`), evidence ranking (`OSATests/EvidenceRankerTests.swift`), and end-to-end retrieval with stub dependencies including imported-knowledge scope mapping, confidence contribution, and citation display (`OSATests/LocalRetrievalServiceTests.swift`). Capability detection and adapter routing tests (`OSATests/CapabilityDetectionTests.swift`) cover both grounded-generation and extractive paths, generation failure fallback, citation integrity across both paths, and real detector behavior on the current platform. Prompt-shaping tests (`OSATests/GroundedPromptBuilderTests.swift`) verify system instructions, evidence formatting, confidence guidance, and full prompt composition. Safety regression tests (`OSATests/SafetyRegressionTests.swift`) cover jailbreak phrasing, scope overrides, prompt injection detection, mixed-intent prompts, routing verification, deterministic refusal, and privacy-bounded refusal reasons. An app bootstrap smoke test (`OSATests/OSAAppSmokeTests.swift`) and a UI launch test (`OSAUITests/OSAAppLaunchUITests.swift`) round out the scaffolding. **Total: 212 unit tests across 23 suites + 1 UI test.** Feature UI surfaces consume repository and retrieval protocols through SwiftUI environment injection.
- The app must behave correctly across offline, degraded, and online transition states.

## Assumptions

- The app will use SwiftUI, SwiftData, and Apple testing frameworks or XCTest-based tooling.
- Manual QA will still be required because stress-state UX and citation quality are hard to validate purely with unit tests.
- Multiple device capability tiers must be tested because Ask behavior changes with model support.

## Recommendations

- Build quality gates around retrieval and safety before polishing answer fluency.
- Treat migration, stale-content handling, and interrupted imports as must-test scenarios, not edge cases.
- Keep a curated prompt and content regression set in the repo.

## Open Questions

- Which physical device matrix is available for testing?
- Will CI have access to any model-capability simulation or only fallback-path tests?
- How much automated content-linting is practical before launch?

## Test Strategy By Layer

### Unit Tests

- taxonomy and content parsing
- chunking and indexing
- repository CRUD behavior
- retrieval ranking heuristics
- policy classification and blocked-category rules
- stale-content and deduplication logic

### Integration Tests

- seed-content import into the local store
- search index rebuilds
- Ask retrieval plus citation packaging
- import pipeline from source metadata through local persistence
- migrations across schema and seed versions

### UI Tests

- first launch
- offline navigation
- inventory CRUD
- checklist completion
- Ask answer and refusal rendering
- online refresh state transitions

### Manual QA

- stress-state quick-card usability
- readability in low-light or hurried usage
- citation clarity
- unsupported-device Ask behavior
- privacy and disclosure review

## Acceptance Criteria

- Core offline features work after a fully offline cold start.
- Ask answers only from approved local sources and includes citations or a clear refusal/not-found response.
- Online source import never creates assistant-usable content until the local commit finishes successfully.
- Data persists correctly across relaunch, update, and interrupted online tasks.
- Sensitive-topic prompts trigger correct static-only or refusal behavior.

## Offline Test Matrix

| Scenario | Expected Result |
| --- | --- |
| Fully offline cold start | App launches, seed content loads, all local screens usable, no blocking network errors. |
| Offline handbook search | Relevant local results return quickly with content type labels. |
| Offline Ask using known handbook topic | Answer is cited and clearly marked local. |
| Offline Ask with unsupported topic | "Not found locally" or refusal response, no fake answer. |
| Offline inventory create/edit | Changes persist across relaunch. |
| Offline checklist run | Completion state persists and appears on Home. |
| Offline note creation | Note saves locally and is searchable. |

## Online And Offline Transition Test Matrix

| Scenario | Expected Result |
| --- | --- |
| Degraded connectivity during source search | UI reflects network issue without losing local usability. |
| Knowledge refresh interrupted mid-download | Operation pauses or fails into retryable state; existing local corpus unchanged. |
| App goes offline during Ask after online offer | Online option disappears or pauses; local answer path still works. |
| App comes back online with pending refresh | Pending operation resumes only when safe and valid. |
| Source import finishes after reconnect | Imported content appears locally with citations and offline availability. |

## Performance Tests

- cold start from terminated state with network unavailable
- local search latency on seed corpus and moderate imported corpus
- Ask end-to-end latency on supported and unsupported model devices
- index rebuild time after seed-content update
- import and normalization time for representative trusted sources

Target starting points:

- app cold start under 2 seconds on recent supported devices
- local search results under 500 ms for typical queries
- Ask answer under 2 seconds for ordinary local questions on supported devices

## Storage And Migration Tests

- first-launch seed import
- app update with seed-content version bump
- app update with schema migration
- corrupted or stale local knowledge entries
- reindex after interrupted import
- large store growth and cleanup behavior

## Content-Retrieval Evaluation

Maintain a benchmark set of representative questions across all initial content domains:

- expected top sources
- expected citation IDs
- expected refusal or not-found responses where appropriate

Review metrics:

- top-k retrieval accuracy
- citation correctness
- answer completeness within product scope
- stale-content handling correctness

## Hallucination And Failure Tests

Must include explicit scenarios for:

- missing or unsupported on-device model
- wrong or missing citations
- empty evidence set
- adversarial prompt asking for unsupported general-chat behavior
- prompt requesting unsafe improvisation
- prompt attempting to override scope or policy

Pass condition: the app refuses, falls back, or cites correctly rather than inventing.

## Safety Regression Tests

Implemented in `OSATests/SafetyRegressionTests.swift`:

- high-risk medical prompts
- weapon or tactical prompts
- foraging and plant-identification prompts
- unsafe fire or utility improvisation prompts
- ambiguous phrasing that could route into risky advice
- prompt injection phrases (jailbreak, ignore instructions, system prompt extraction)
- scope-override attempts (role-play, bypass, unrestricted mode)
- mixed-intent prompts (safe topic + blocked keyword, safe topic + injection)
- routing verification (blocked queries never reach generation, sensitive-static-only restricts to static content)
- deterministic refusal (same input yields same refusal)
- privacy-bounded refusal reasons (refusal messages do not contain raw user content)

## Manual QA Scenarios

1. Install fresh build, disable network, and complete a full cold-start walkthrough.
2. Add inventory and notes, then verify Ask can use them only according to settings.
3. Import a trusted source, go offline, and verify the new material remains searchable and citeable.
4. Simulate stale imported knowledge and verify stale cues appear where required.
5. Force unsupported-model capability and verify Ask still behaves predictably.

## Device Coverage Assumptions

Minimum device coverage should include:

- one modern device with Foundation Models support
- one device or simulator path without usable model support
- at least one lower-storage or lower-memory device profile if supported by the target OS decision

## Done Means

- The test plan covers the highest-risk areas, not just happy-path UI.
- Explicit offline, transition, and safety scenarios are defined.
- Acceptance criteria can gate milestones and release readiness.

## Next-Step Recommendations

1. Create a prompt regression suite before Ask implementation starts.
2. Build migration and import interruption tests early; they are easy to defer and expensive to fix late.
3. Tie each milestone in the roadmap to a subset of these acceptance criteria.
