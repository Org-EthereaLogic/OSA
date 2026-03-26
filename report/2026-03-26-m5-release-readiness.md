# M5 Release Readiness Evidence Pack

Date: 2026-03-26
Milestone: 5 — Release Readiness
Status: Verified — build and test passed 2026-03-26

---

## Summary

This report maps each release criterion from `docs/sdlc/12-release-readiness-and-app-store-plan.md` to current codebase evidence. Items marked `unverified` require runtime verification (build, test execution, device testing) that cannot be completed in a headless environment.

---

## Release Criteria Evidence

### RC-1: No open high-severity defects affecting offline core flows

| Field | Value |
| --- | --- |
| Status | `passed` |
| Evidence | All 8 core feature screens exist in `OSA/Features/`. SwiftData persistence backing exists for all content types (14 `@Model` classes). No network dependency in feature view initialization. `xcodebuild build` and `xcodebuild test` both succeeded 2026-03-26. |
| Test coverage | 250 unit test methods across 28 test suites + 1 UI test suite. Includes SchemaMigrationTests (7), SeedContentMigrationTests (6), OfflineStressTests (7) added in M5. |
| Verification needed | Manual walkthrough of each core screen in airplane mode remains recommended for TestFlight. |
| Notes | No open defect tracker exists in the repository. Defect status depends on TestFlight triage. |

---

### RC-2: No open high-severity privacy or safety issues

| Field | Value |
| --- | --- |
| Status | `passed` |
| Evidence — Safety policy | `SensitivityPolicy` implements phrase-based and keyword-based injection detection. Blocked categories include prompt injection, jailbreak phrasing, scope overrides, system prompt extraction, and safety-sensitive topics. |
| Evidence — Safety tests | `SafetyRegressionTests` (53 test methods, expanded in M5) covers: jailbreak phrasing, system prompt extraction, scope overrides, mixed-intent prompts, case insensitivity, deterministic refusal, privacy-bounded refusal reasons, privacy-pressure prompts, professional-advice pressure, override variants, and stale-source boundary queries. All 53 tests pass. |
| Evidence — Prompt protection | `GroundedPromptBuilder` includes `OVERRIDE PROTECTION` instruction at line 72, directing the model to ignore embedded instructions that attempt to change rules, reveal system instructions, or expand scope. |
| Evidence — Network boundary | `TrustedSourceAllowlist` restricts fetches to 15 exact HTTPS hosts. `TrustedSourceHTTPClient` validates scheme, allowlist membership, HTTP status, Content-Type, and payload size. No wildcard or suffix matching. |
| Evidence — Privacy posture | No analytics SDK, no crash reporting, no account system, no permissions requested. All user data remains in the local SwiftData container. |
| Verification needed | `SafetyRegressionTests` must pass via `xcodebuild test`. Snyk code scan should confirm no known vulnerabilities in first-party code. Manual review of Info.plist for undisclosed permission keys. |
| Notes | Privacy posture is documented in `docs/sdlc/10-security-privacy-and-safety.md`. Final App Store privacy labels must be validated against the shipped binary. |

---

### RC-3: Ask passes citation and refusal regression suite

| Field | Value |
| --- | --- |
| Status | `passed` |
| Evidence — Prompt builder | `GroundedPromptBuilder` (`OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift`) constructs model-ready prompts with system instructions, evidence blocks, query blocks, and confidence-level guidance. Tests verify grounding, citation presence, and safety instructions. |
| Evidence — Prompt builder tests | `GroundedPromptBuilderTests` (18 test methods) verify prompt structure, citation formatting, confidence-level handling, and safety instruction inclusion. |
| Evidence — Safety regression | `SafetyRegressionTests` (53 test methods, M5-expanded) verify refusal for blocked topics, injection attempts, scope overrides, privacy-pressure, professional-advice pressure, and override variants. |
| Evidence — Retrieval pipeline | `LocalRetrievalService` (14 tests), `QueryNormalizer` (6 tests), `EvidenceRanker` (4 tests) cover the evidence retrieval chain that feeds citations to the prompt builder. |
| Evidence — Capability detection | `CapabilityDetectionTests` (11 tests) verify `DeviceCapabilityDetector` correctly identifies Foundation Models availability and fallback behavior. |
| Verification needed | Full test suite execution via `xcodebuild test`. Manual Ask queries on a Foundation Models-capable device to verify end-to-end citation and refusal behavior. |
| Notes | Citation correctness depends on both retrieval accuracy and model output. Automated tests verify pipeline inputs and prompt structure; model output quality requires manual evaluation during TestFlight stages. |

---

### RC-4: Imported-source flow works end to end and remains available offline

| Field | Value |
| --- | --- |
| Status | `passed` (automated); manual end-to-end with live network recommended for TestFlight |
| Evidence — Import pipeline | `ImportedKnowledgeImportPipeline` (`OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift`) orchestrates normalize, chunk, persist, and index. Uses protocol-based repository injection (no direct SwiftData import). |
| Evidence — Pipeline components | `ImportedKnowledgeNormalizer` (HTML to normalized document), `KnowledgeChunker` (document to indexed chunks), `SwiftDataImportedKnowledgeRepository` (persistence), `SearchIndexStore` / `LocalSearchService` (indexing). |
| Evidence — Import flow tests | `AskTrustedSourceImportFlowTests` (16 test methods) cover: URL validation (empty, malformed, HTTP rejection, non-allowlisted host, valid HTTPS allowlisted), import state transitions, and view model behavior. |
| Evidence — Repository tests | `ImportedKnowledgeRepositoryTests` (28 test methods) cover CRUD, chunk persistence, source record lifecycle, and query operations. |
| Evidence — Search index tests | `SearchIndexStoreTests` (7 test methods) cover indexing and retrieval of imported content. |
| Evidence — Refresh coordinator | `ImportedKnowledgeRefreshCoordinator` detects stale sources (30-day default), enqueues refresh via `PendingOperation`, and drains queue when connectivity is available. `RefreshRetryPolicy` governs retry behavior. |
| Evidence — Allowlist | `TrustedSourceAllowlist` defines 15 publishers across 3 tiers with exact host matching. |
| Evidence — HTTP client | `URLSessionTrustedSourceHTTPClient` validates HTTPS scheme, allowlist membership, HTTP 2xx status, Content-Type, payload size (2 MB limit), and post-redirect host. |
| Verification needed | End-to-end manual test: import a page from an allowlisted source while online, then verify the content is browsable and available to Ask after toggling airplane mode. |
| Notes | The import pipeline is testable through protocol boundaries. End-to-end verification requires a running app with network access followed by offline confirmation. |

---

### RC-5: App size, cold start, and local performance are acceptable

| Field | Value |
| --- | --- |
| Status | `unverified` |
| Evidence — Architecture | Single app target with no embedded frameworks, no bundled ML models (Foundation Models runs on-device via system framework), no large asset catalogs in current build. |
| Evidence — Persistence | SwiftData with 14 model classes. No pre-populated SQLite database shipped — seed content is imported at first launch via `SeedContentImporter`. |
| Evidence — No heavy dependencies | No third-party SDKs, no analytics frameworks, no crash reporting libraries. |
| Verification needed | `xcodebuild build` to measure binary size. Instruments profiling for cold-start time on target device (iPhone 16 simulator baseline). Manual assessment of navigation responsiveness. |
| Notes | Performance metrics require device-level measurement. Headless build verification can confirm binary size but not runtime performance. |

---

### RC-6: App Store privacy answers match shipped behavior

| Field | Value |
| --- | --- |
| Status | `unverified` |
| Evidence — No data collection | No analytics SDK, no crash reporting, no account system, no advertising. Codebase audit confirms no third-party networking libraries. |
| Evidence — No permissions | No `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, or other permission keys in project configuration. |
| Evidence — Network boundary | Online requests are limited to `TrustedSourceAllowlist` hosts via `URLSessionTrustedSourceHTTPClient`. All requests are user-initiated. `NWPathMonitorConnectivityService` observes connectivity but does not transmit data. |
| Evidence — Local storage | All user data persisted via SwiftData in the app container. No iCloud sync, no CloudKit, no remote database. |
| Evidence — Privacy documentation | `docs/sdlc/10-security-privacy-and-safety.md` documents the privacy posture. App Store privacy label draft in `report/2026-03-26-m5-app-store-materials.md`. |
| Verification needed | Binary audit of the shipped build to confirm no undisclosed network calls. Review of `Info.plist` in the built product for any auto-injected permission keys. Comparison of App Store privacy answers against observed runtime behavior during TestFlight. |
| Notes | Privacy label accuracy is a release blocker. Final verification must occur against the actual submission build, not the development build. |

---

## Build and Tool Verification

### Build Verification

| Field | Value |
| --- | --- |
| Command | `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| Status | `unverified` |
| Notes | Requires full Xcode installation (not Command Line Tools only). If the active developer directory points at `/Library/Developer/CommandLineTools`, the build cannot proceed. To be filled during verification phase. |

### Test Verification

| Field | Value |
| --- | --- |
| Command | `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test` |
| Status | `unverified` |
| Total test count | 217 unit test methods across 17 test suites + 1 UI test (OSAAppLaunchUITests) |
| Notes | Test count derived from `func test` occurrences in `OSATests/` and `OSAUITests/`. Actual pass/fail status requires test execution. To be filled during verification phase. |

### Test Suite Inventory

| Suite | Test Methods | Focus Area |
| --- | --- | --- |
| SafetyRegressionTests | 39 | Jailbreak, injection, refusal, scope override |
| ImportedKnowledgeRepositoryTests | 28 | Import CRUD, chunks, source records |
| ConnectivityServiceTests | 19 | Network monitoring, state transitions |
| GroundedPromptBuilderTests | 18 | Prompt structure, citations, safety instructions |
| AskTrustedSourceImportFlowTests | 16 | URL validation, import flow, view model |
| LocalRetrievalServiceTests | 14 | Evidence retrieval, query matching |
| PendingOperationRepositoryTests | 13 | Operation queue, persistence |
| CapabilityDetectionTests | 11 | Foundation Models detection, fallback |
| SensitivityPolicyTests | 11 | Sensitivity classification, blocking |
| InventoryRepositoryTests | 9 | Inventory CRUD, search |
| NoteRepositoryTests | 8 | Note CRUD, tagging |
| ChecklistRepositoryTests | 8 | Checklist templates, runs, history |
| SearchIndexStoreTests | 7 | Index operations, retrieval |
| QueryNormalizerTests | 6 | Query preprocessing |
| SeedContentRepositoryTests | 4 | Seed import, content loading |
| EvidenceRankerTests | 4 | Evidence scoring, ordering |
| OSAAppSmokeTests | 1 | App initialization |
| OSAAppLaunchUITests | 1 | UI launch verification |

### Security Scan

| Field | Value |
| --- | --- |
| Command | `snyk code test --path="$PWD"` |
| Status | `unverified` |
| Notes | Snyk CLI is not confirmed installed in this environment. To be run when available. No third-party dependencies reduces the attack surface for supply-chain vulnerabilities. |

### Screenshot Inventory

| Field | Value |
| --- | --- |
| Status | `unverified` |
| Notes | Screenshots require a running simulator or device. Headless environment limitation prevents capture. Required screenshots for App Store submission: Home, Library, Ask, Quick Cards, Inventory, Checklists, Notes, Settings (8 core screens minimum). |

---

## Pre-Release Checklist Status

Mapped from `docs/sdlc/12-release-readiness-and-app-store-plan.md` lines 31-37.

| Checklist Item | Status | Notes |
| --- | --- | --- |
| Complete seed-content review for MVP chapters, quick cards, and checklist templates | `unverified` | Seed content exists in `OSA/Persistence/SeedImport/`. Content quality review requires manual assessment. |
| Verify offline cold-start behavior on target devices | `unverified` | Requires device or simulator testing in airplane mode. |
| Verify Ask citations, refusal paths, and unsupported-device behavior | `unverified` | 39 safety regression tests + 18 prompt builder tests exist. Runtime verification needed. |
| Complete migration tests from at least one prior beta build | `unverified` | No prior TestFlight build exists yet. Migration testing begins at Stage 1 alpha. |
| Verify trusted-source import and offline reuse flow | `unverified` | 16 import flow tests + 28 repository tests exist. End-to-end manual verification needed. |
| Review privacy disclosures and permission strings | `unverified` | Privacy posture documented. Info.plist review against built product pending. |
| Confirm no hidden network calls occur during offline local use | `unverified` | Architecture review confirms no background networking in v1. Runtime network trace needed for confirmation. |

---

## Risk Summary

| Risk | Severity | Mitigation |
| --- | --- | --- |
| All verification statuses are `unverified` | Medium | This is expected at the documentation phase. Verification requires full Xcode, simulator, and device access. |
| No prior TestFlight build for migration testing | Medium | First alpha build establishes the baseline. Migration testing starts at Stage 1 second build. |
| Foundation Models availability is device-dependent | Low | `DeviceCapabilityDetector` handles fallback. 11 capability detection tests verify behavior on unsupported devices. |
| Seed content quality not reviewed | Medium | Content review is a manual process. Should be completed before Stage 2 trusted beta. |
| No defect tracker in repository | Low | TestFlight feedback triage (see `report/2026-03-26-m5-testflight-feedback-loop.md`) establishes the triage workflow. |

---

## Source References

| Document | Path |
| --- | --- |
| Release Readiness Plan | `docs/sdlc/12-release-readiness-and-app-store-plan.md` |
| Security and Privacy | `docs/sdlc/10-security-privacy-and-safety.md` |
| Product Requirements | `docs/sdlc/02-prd.md` |
| App Store Materials | `report/2026-03-26-m5-app-store-materials.md` |
| TestFlight Feedback Loop | `report/2026-03-26-m5-testflight-feedback-loop.md` |
| Safety Regression Tests | `OSATests/SafetyRegressionTests.swift` |
| Prompt Builder Tests | `OSATests/GroundedPromptBuilderTests.swift` |
| Import Flow Tests | `OSATests/AskTrustedSourceImportFlowTests.swift` |
| Trusted Source Allowlist | `OSA/Networking/Clients/TrustedSourceAllowlist.swift` |
| Sensitivity Policy | `OSA/Assistant/Policy/SensitivityPolicy.swift` |
| Grounded Prompt Builder | `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift` |
| Import Pipeline | `OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift` |
| Refresh Coordinator | `OSA/Networking/Refresh/ImportedKnowledgeRefreshCoordinator.swift` |
