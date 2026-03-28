# OSA SDLC Document Suite Index

Status: Initial draft complete, verification and cross-link pass complete.
Primary audience: solo developer or very small iOS team.
Related docs: [Problem Brief](./01-problem-brief.md), [PRD](./02-prd.md), [Technical Architecture](./05-technical-architecture.md), [Risk Register](./risk-register.md)

## Purpose Of This Suite

This suite defines the initial product, architecture, data, safety, quality, and release baseline for OSA, an offline-first iPhone preparedness handbook app with a grounded local assistant and optional online knowledge enrichment. The goal is implementation usefulness, not generic process coverage.

## Confirmed Facts

- The repository contains the SDLC documentation suite, an Xcode project, a reorganized navigation shell, and explicit workspace maps across `OSA/App/`, `OSA/Features/`, `OSA/Shared/`, `OSA/Domain/`, `OSA/Persistence/`, `OSA/Retrieval/`, `OSA/Assistant/`, and `OSA/Networking/`.
- Milestone 1 Phase 1 is complete: app shell, tab navigation (4 primary tabs + More section), design-system scaffolding, and connectivity state modeling are in the codebase.
- Milestone 1 Phase 2 now has an implemented editorial-content persistence foundation: domain-facing content models and repository protocols, SwiftData models and mappings, bundled seed import, and focused repository tests for handbook chapters, sections, and quick cards.
- Milestone 2 (Core Organizer) implementation is substantially complete: domain models, repository protocols, SwiftData persistence, environment-key DI, and CRUD UI for Inventory, Checklists, and Notes are implemented. A sidecar SQLite FTS5 search index (`SearchIndexStore`) and `LocalSearchService` are wired, with Library search results UI. Repository-contract tests cover inventory, checklists, notes, and the search index.
- Milestone 3 Phase 1 (Grounded Ask retrieval pipeline) is implemented: domain-facing retrieval and citation models (`EvidenceItem`, `CitationReference`, `RetrievalOutcome`, `AnswerMode`, `ConfidenceLevel`, `RefusalReason`), `RetrievalService`, `SensitivityClassifier`, and `CapabilityDetector` protocols, `LocalRetrievalService` pipeline (normalize → classify → search → rank → cite → assemble), `SensitivityPolicy` for blocked/sensitive topic enforcement, deterministic `EvidenceRanker`, and a retrieval-backed Ask UI with answer/citation/refusal states. Focused tests cover normalization, sensitivity, ranking, and end-to-end retrieval.
- Milestone 3 Phase 3 (Capability detection and model adapter) is implemented: real runtime detection via `DeviceCapabilityDetector` using `#if canImport(FoundationModels)` and `SystemLanguageModel.default.availability`, `GroundedAnswerGenerator` protocol, `FoundationModelAdapter` concrete implementation behind compile-time guards, `LocalRetrievalService` async routing with automatic extractive fallback on generation failure. `CapabilityDetectionTests` covers both capability paths, generation failure fallback, and citation integrity.
- Milestone 3 Phase 5 (Assistant policy, prompt shaping, and safety guardrails) is implemented: `GroundedPromptBuilder` dedicated prompt-shaping layer with grounding rules, citation requirements, scope limits, safety boundaries, style constraints, and override protection. `SensitivityPolicy` extended with phrase-based and keyword-based prompt injection detection. `FoundationModelAdapter` delegates all prompt construction to `GroundedPromptBuilder`. `SafetyRegressionTests` covers jailbreak phrasing, scope overrides, mixed-intent prompts, routing verification, deterministic refusal, and privacy-bounded refusal reasons. `GroundedPromptBuilderTests` verifies all prompt sections. `SensitivityPolicyTests` expanded with adversarial variants.
- M3 Polish sprint is complete: HomeScreen wired to live repositories (quick cards, active checklists, inventory reminders, recent notes from real data), SettingsScreen shows real capability detection via `capabilityDetector` environment key, AskScreen has `navigationDestination` routing to `QuickCardRouteView` and `HandbookSectionDetailView`, and `AskScopeSettings` (`@AppStorage`-backed) controls the personal-notes-in-Ask toggle across both AskScreen and SettingsScreen. Seed corpus expanded to 11 chapters with 35 sections and 14 quick cards with content hashes populated.
- Milestone 4 Phase 1 (ConnectivityService) is implemented: `ConnectivityService` protocol with `NWPathMonitor` in `OSA/Networking/Clients/`, reactive state publishing, sync-in-progress override, and SwiftUI environment injection. `ConnectivityServiceTests` (19 tests) covers state transitions and multicasting.
- Milestone 4 Phase 2 (Import domain models and persistence) is implemented: `SourceRecord`, `ImportedKnowledgeDocument`, `KnowledgeChunk`, and `PendingOperation` domain models with SwiftData persistence, cascade relationships, and repository protocols. `ImportedKnowledgeRepositoryTests` (28 tests) and `PendingOperationRepositoryTests` (13 tests) verify CRUD, relationships, and queue management.
- Milestone 4 Phase 3 (Trusted-source allowlist and HTTP client) is implemented: `TrustedSourceAllowlist` with 15 PNW-focused publishers across three trust tiers, `TrustedSourceHTTPClient` protocol with `URLSessionTrustedSourceHTTPClient` in `Clients/`, and `TrustedSourceFetchResponse` DTO. `TrustedSourceAllowlistTests` (9 tests) and `TrustedSourceHTTPClientTests` (10 tests) verify tier resolution, fetch lifecycle, and security enforcement.
- Milestone 4 Phase 4 (Import pipeline) is implemented: `ImportedKnowledgeNormalizer`, `KnowledgeChunker`, and `ImportedKnowledgeImportPipeline` in `ImportPipeline/`. FTS5 search index extended with `.importedKnowledge` kind. Ask retrieval extended for approved imported knowledge. `ImportedKnowledgeNormalizerTests` (6 tests), `KnowledgeChunkerTests` (8 tests), `ImportedKnowledgeImportPipelineTests` (6 tests).
- Milestone 4 Phase 5 (Refresh and retry coordination) is implemented: `RefreshRetryPolicy` and `ImportedKnowledgeRefreshCoordinator` in `Refresh/`. `RefreshRetryPolicyTests` (6 tests) and `ImportedKnowledgeRefreshCoordinatorTests` (6 tests) verify backoff, connectivity gating, and idempotent startup.
- Milestone 4 Phase 6 (Ask online-offer UX and import sheet) is implemented: `TrustedSourceImportViewModel` and `TrustedSourceImportSheet` in `Features/Ask/` provide user-driven import from approved publishers when local evidence is insufficient and connectivity is usable. `AskScreen` `RefusalView` shows conditional import offer. `AskTrustedSourceImportFlowTests` (16 tests) verify URL validation, source filtering, preview/import lifecycle, and state management.
- CI and quality automation: GitHub Actions CI workflow (`.github/workflows/ci.yml`) runs build, test, and Codecov coverage upload on push/PR to main. CodeQL security analysis (`.github/workflows/codeql.yml`) runs weekly and on push/PR. Codacy CLI available locally via `.codacy/cli.sh`.
- M6P1 App Intents foundation is complete: `AskLanternIntent` and `LanternAppShortcutsProvider` for Siri question-answering, `SharedRuntime` for non-SwiftUI dependency access, `AskLanternIntentExecutor` for intent-facing retrieval with citation formatting. 8 focused tests.
- M6P2 App Entities and Spotlight indexing is complete: `HandbookSectionEntity`, `QuickCardEntity`, `ChecklistEntity`, and `InventoryItemEntity` (`AppEntity` + `IndexedEntity` + `EntityStringQuery`) backed by `EntityQueryResolver`. Privacy rules enforce archived-item exclusion and notes redaction. 19 focused tests.
- M6P3 FM-powered inventory completion is complete: `LocalInventoryCompletionService` in `OSA/Assistant/InventoryCompletion/` uses Foundation Models `@Generable` structured output to suggest inventory fields, with deterministic heuristic fallback. `InventoryCompletionMerger` enforces conservative merge rules. User-triggered "Suggest Details" in `InventoryItemFormView`. 33 focused tests.
- M6P4 AssistantSchema and onscreen content is complete: `AskLanternIntent` carries `@AppIntent(schema: .system.search)` with `ShowInAppSearchResultsIntent` conformance. `AppNavigationCoordinator` mediates App Intent deep-link handoff. `OpenQuickCardIntent` and `OpenHandbookSectionIntent` accept existing entities. `OnscreenContentManager` publishes quick card and handbook section context. 12 focused tests.
- M6P5 Knowledge-base discovery is complete: RSS-first discovery from trusted sources (`RSSFeedParser`, `RSSFeedRegistry`, `LiveRSSDiscoveryService`) with optional Brave Search free tier (`BraveSearchClient` with budget tracking). `KnowledgeDiscoveryCoordinator` orchestrates both, deduplicates, and feeds into existing ImportPipeline. Connectivity-gated, once-per-day schedule, Settings UI for manual trigger and API key. The most recent full `xcodebuild test` run on 2026-03-28 passed 423 tests total: 399 unit and 24 UI.
- Product direction provided for this suite requires offline-first behavior, local-first privacy, and a grounded assistant that answers only from approved local content and app data.

## Assumptions

- The first implementation will be a native iPhone app built with SwiftUI.
- The app will prioritize iOS 18 features where they materially simplify grounded local AI, while degrading gracefully when Foundation Models are unavailable.
- v1 will not include account-based sync; "sync" in this suite primarily means online content refresh and local persistence of imported knowledge.

## Recommendations

- Use this suite as the initial source of truth until implementation reveals constraints that require ADR updates.
- Treat [Technical Architecture](./05-technical-architecture.md), [Data Model](./06-data-model-local-storage.md), and [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md) as the gating specs for early development decisions.
- Keep the suite lean by updating ADRs and the risk register rather than creating parallel decision documents.

## Open Questions Summary

1. ~~What is the minimum supported iOS version and device range for first release?~~ **Resolved:** iOS 18.0 minimum. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md).
2. ~~Is Foundation Models availability required for launch, or is extractive non-generative fallback acceptable on older hardware?~~ **Resolved:** Foundation Models where available, extractive fallback on unsupported hardware. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md).
3. ~~Which trusted domains and publishers are approved for online knowledge import at launch?~~ **Resolved:** A three-tier trusted-source allowlist has been defined with 15 PNW-focused survival and preparedness sources. Tier 1–2 sources auto-approve; Tier 3 and user-added sources are flagged for review.
4. ~~Should offline maps be in scope for v1, or should "local notes/maps/forest reference" start as text, images, and links only?~~ **Resolved:** Include PNW-focused map references (USGS topoView, Forest Service R6, PNTA) plus one or two US-wide sources. v1 scope is text, images, and links to map resources — not embedded map tile data.
5. ~~Is personal backup/export needed in the first release, or should all user data remain single-device only for v1?~~ **Resolved:** Single-device only for v1. No backup, sync, or export.

## Decision Log Summary

- [ADR-0001](../adr/ADR-0001-offline-first-local-first.md): Critical workflows must function without connectivity.
- [ADR-0002](../adr/ADR-0002-grounded-assistant-only.md): The assistant is not a general chatbot and only answers from approved local sources and app data.
- [ADR-0003](../adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md): Online knowledge is usable by the assistant only after local persistence, attribution, normalization, and indexing.
- Architecture recommendation: prefer SwiftData for primary local persistence with repository boundaries that preserve an exit path to Core Data if needed.
- Retrieval recommendation: start with deterministic keyword and metadata ranking plus chunked local citations; defer embeddings until the corpus and evaluation data justify them.
- [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md): iOS 18.0 minimum target; Foundation Models for generation where available, extractive fallback otherwise; no bundled third-party LLM in v1.

## Reading Order

1. [Problem Brief](./01-problem-brief.md)
2. [PRD](./02-prd.md)
3. [MVP Scope Roadmap](./03-mvp-scope-roadmap.md)
4. [Information Architecture And UX Flows](./04-information-architecture-and-ux-flows.md)
5. [Technical Architecture](./05-technical-architecture.md)
6. [Data Model And Local Storage](./06-data-model-local-storage.md)
7. [Sync, Connectivity, And Web Knowledge Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md)
8. [AI Assistant Retrieval And Guardrails](./08-ai-assistant-retrieval-and-guardrails.md)
9. [Content Model And Editorial Guidelines](./09-content-model-editorial-guidelines.md)
10. [Security, Privacy, And Safety](./10-security-privacy-and-safety.md)
11. [Quality Strategy, Test Plan, And Acceptance](./11-quality-strategy-test-plan-and-acceptance.md)
12. [Release Readiness And App Store Plan](./12-release-readiness-and-app-store-plan.md)
13. [Task 03 SwiftData Schema Enhanced Prompt](../prompt/enhanced/13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
14. [Milestone 1 Phase 2 Persistence, Seed Import, And Tests Enhanced Prompt](../prompt/enhanced/14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
15. [Milestone 1 Exit Criteria — Handbook And Quick Card Browsing UI Enhanced Prompt](../prompt/enhanced/15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
16. [Milestone 3 Phase 1 — Grounded Ask Retrieval Pipeline Enhanced Prompt](../prompt/enhanced/16-milestone-3-grounded-ask-retrieval-pipeline-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
17. [Milestone 3 Phase 3 — Capability Detection And Model Adapter Enhanced Prompt](../prompt/enhanced/17-milestone-3-capability-detection-and-model-adapter-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
18. [Milestone 3 Phase 5 — Assistant Policy, Prompt Shaping, And Safety Guardrails Enhanced Prompt](../prompt/enhanced/18-milestone-3-assistant-policy-prompt-shaping-and-safety-guardrails-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
19. [MVP Handbook And Quick-Card Corpus Expansion Enhanced Prompt](../prompt/enhanced/19-mvp-handbook-and-quick-card-corpus-expansion-enhanced-prompt.md) _(content expansion prompt, not an SDLC living document)_
20. [M3 Polish Sprint Enhanced Prompt](../prompt/enhanced/20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md) _(implementation task prompt, not an SDLC living document)_
21. [M6P1 App Intents Foundation Enhanced Prompt](../prompt/enhanced/33-m6p1-app-intents-foundation-enhanced-prompt.md) _(implementation task prompt)_
22. [M6P2 App Entities And Spotlight Indexing Enhanced Prompt](../prompt/enhanced/34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md) _(implementation task prompt)_
23. [M6P3 FM-Powered Inventory Completion Enhanced Prompt](../prompt/enhanced/35-m6p3-fm-powered-inventory-completion-enhanced-prompt.md) _(implementation task prompt)_
24. [M6P4 AssistantSchema, Onscreen Content, And Navigation Intents Enhanced Prompt](../prompt/enhanced/36-m6p4-assistant-schema-onscreen-content-and-navigation-intents-enhanced-prompt.md) _(implementation task prompt)_
25. ADRs in [docs/adr](../adr/)
25. [Risk Register](./risk-register.md)

## File List

| File | Purpose | Current Status |
| --- | --- | --- |
| [00-doc-suite-index.md](./00-doc-suite-index.md) | Map of the suite, reading order, status, and unresolved questions. | Initial draft complete |
| [01-problem-brief.md](./01-problem-brief.md) | High-level product problem framing, vision, non-goals, and risks. | Initial draft complete |
| [02-prd.md](./02-prd.md) | Product requirements baseline for MVP and first release. | Initial draft complete |
| [03-mvp-scope-roadmap.md](./03-mvp-scope-roadmap.md) | Delivery phasing, deferrals, and milestone sequencing. | Initial draft complete |
| [04-information-architecture-and-ux-flows.md](./04-information-architecture-and-ux-flows.md) | Navigation, core screens, stress-state UX, and key flows. | Initial draft complete |
| [05-technical-architecture.md](./05-technical-architecture.md) | System architecture, modules, trust boundaries, and core technical recommendations. | Initial draft complete |
| [06-data-model-local-storage.md](./06-data-model-local-storage.md) | Local schema, storage layout, migration, and seed data model. | Initial draft complete |
| [07-sync-connectivity-and-web-knowledge-refresh.md](./07-sync-connectivity-and-web-knowledge-refresh.md) | Connectivity handling, online refresh flows, and local persistence requirements. | Initial draft complete |
| [08-ai-assistant-retrieval-and-guardrails.md](./08-ai-assistant-retrieval-and-guardrails.md) | Grounded assistant behavior, retrieval rules, and safety guardrails. | Initial draft complete |
| [09-content-model-editorial-guidelines.md](./09-content-model-editorial-guidelines.md) | Handbook structure, templates, taxonomy, and review workflow. | Initial draft complete |
| [10-security-privacy-and-safety.md](./10-security-privacy-and-safety.md) | On-device privacy posture, network assumptions, and safety controls. | Initial draft complete |
| [11-quality-strategy-test-plan-and-acceptance.md](./11-quality-strategy-test-plan-and-acceptance.md) | Test strategy, offline and transition test matrices, and acceptance criteria. | Initial draft complete |
| [12-release-readiness-and-app-store-plan.md](./12-release-readiness-and-app-store-plan.md) | Launch checklist, TestFlight plan, store disclosures, and post-launch maintenance. | Initial draft complete |
| [13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md](../prompt/enhanced/13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md) | Implementation task prompt for SwiftData schema and repository protocols (Milestone 1 Phase 2). | Executed — first editorial-content slice implemented |
| [14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md](../prompt/enhanced/14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md) | Expanded implementation task prompt for Milestone 1 Phase 2 persistence, bundled seed import, and repository-contract tests. | Executed — persistence, seed import, and repository tests landed |
| [15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md](../prompt/enhanced/15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md) | Implementation task prompt for Milestone 1 exit criteria: handbook and quick-card browsing UI. | Executed — handbook and quick-card browsing UI landed |
| [16-milestone-3-grounded-ask-retrieval-pipeline-enhanced-prompt.md](../prompt/enhanced/16-milestone-3-grounded-ask-retrieval-pipeline-enhanced-prompt.md) | Implementation task prompt for Milestone 3 Phase 1: grounded Ask retrieval pipeline. | Executed — retrieval pipeline, sensitivity policy, citations, capability detection, and bounded Ask UI landed |
| [17-milestone-3-capability-detection-and-model-adapter-enhanced-prompt.md](../prompt/enhanced/17-milestone-3-capability-detection-and-model-adapter-enhanced-prompt.md) | Implementation task prompt for Milestone 3 Phase 3: capability detection and model adapter. | Executed — capability detection and model adapter implementation landed |
| [18-milestone-3-assistant-policy-prompt-shaping-and-safety-guardrails-enhanced-prompt.md](../prompt/enhanced/18-milestone-3-assistant-policy-prompt-shaping-and-safety-guardrails-enhanced-prompt.md) | Implementation task prompt for Milestone 3 Phase 5: assistant policy, prompt shaping, and safety guardrails. | Executed — prompt shaping layer, prompt injection detection, and safety regression tests landed |
| [19-mvp-handbook-and-quick-card-corpus-expansion-enhanced-prompt.md](../prompt/enhanced/19-mvp-handbook-and-quick-card-corpus-expansion-enhanced-prompt.md) | Content expansion prompt for broader MVP handbook and quick-card seed corpus. | Executed — handbook and quick-card corpus expanded |
| [20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md](../prompt/enhanced/20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md) | M3 polish sprint: Home live data, Settings capability detection, Ask scope/navigation, and seed-manifest integrity. | Executed — M3 polish sprint landed |
| [ADR-0001-offline-first-local-first.md](../adr/ADR-0001-offline-first-local-first.md) | Records the offline-first local-first decision. | Initial draft complete |
| [ADR-0002-grounded-assistant-only.md](../adr/ADR-0002-grounded-assistant-only.md) | Records the grounded assistant-only decision. | Initial draft complete |
| [ADR-0003-online-knowledge-refresh-with-local-persistence.md](../adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md) | Records the online retrieval plus local persistence decision. | Initial draft complete |
| [ADR-0004-ios18-minimum-target-with-foundation-models.md](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md) | Records the iOS 18 minimum target and Foundation Models with extractive fallback decision. | Accepted |
| [risk-register.md](./risk-register.md) | Consolidated product and delivery risks with mitigation ownership. | Initial draft complete |
| [33-m6p1-app-intents-foundation-enhanced-prompt.md](../prompt/enhanced/33-m6p1-app-intents-foundation-enhanced-prompt.md) | M6P1 App Intents foundation: AskLanternIntent, shortcuts provider, SharedRuntime. | Executed |
| [34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md](../prompt/enhanced/34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md) | M6P2 App Entities and Spotlight indexing for Siri entity resolution. | Executed |
| [35-m6p3-fm-powered-inventory-completion-enhanced-prompt.md](../prompt/enhanced/35-m6p3-fm-powered-inventory-completion-enhanced-prompt.md) | M6P3 FM-powered inventory completion with heuristic fallback. | Executed |
| [36-m6p4-assistant-schema-onscreen-content-and-navigation-intents-enhanced-prompt.md](../prompt/enhanced/36-m6p4-assistant-schema-onscreen-content-and-navigation-intents-enhanced-prompt.md) | M6P4 AssistantSchema, onscreen content, and navigation intents. | Executed |
| [sdlc_doc_suite_prompt.md](../prompt/enhanced/sdlc_doc_suite_prompt.md) | Original source prompt retained for context and traceability. | Preserved input |

## Current Suite Status

- Document creation status: complete for initial v0.1 draft set; updated through M6P5 completion.
- Architecture confidence: high; Milestones 1–6 complete. All UI surfaces are backed by live data. CI and quality automation in place. Siri App Intents with AssistantSchema, App Entities with Spotlight, FM-powered inventory completion, deep-link navigation intents, onscreen content manager, and RSS-based knowledge discovery with optional Brave Search enrichment all landed.
- Product confidence: high; release-readiness evidence pack maps 6 criteria to test evidence (4 passed, 2 require device testing). App Store materials and TestFlight feedback plan exist as dated repo artifacts.
- Highest uncertainty areas: Foundation Models generation quality with real corpus data; device-specific performance and App Store binary validation. Branding and UI polish sprint is complete (forest canopy palette, wordmarks, themed surfaces applied across all 8 feature screens).

## Done Means

- Every required file exists under `docs/sdlc/` with project-specific initial content.
- Cross-links are present between related documents.
- Decisions that materially shape implementation are captured in ADRs and summarized here.
- Open questions are consolidated here so they can be answered before coding begins.

## Next-Step Recommendations

1. ~~Resolve the minimum OS and AI capability support matrix before creating the Xcode project.~~ **Resolved:** iOS 18.0 minimum, Foundation Models with extractive fallback. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md). Xcode project scaffolded.
2. ~~Approve an initial trusted web source allowlist before implementing online knowledge refresh.~~ **Resolved:** Three-tier allowlist defined with 15 PNW-focused sources.
3. ~~Expand the first bundled seed packs into the broader MVP handbook, quick-card, and checklist corpus.~~ **Done:** Handbook pack expanded to 11 chapters with 35 sections, quick-card pack to 14 cards, content hashes populated in SeedManifest.json v0.3.1. Two planned chapters (Local Notes/Maps, Archery/Longbow) deferred.
4. ~~Begin Milestone 3 (Grounded Ask): retrieval pipeline, citation packaging, capability detection, and bounded Ask UI.~~ **Done:** M3P1 (retrieval pipeline, sensitivity policy, citation packaging, capability detection, bounded Ask UI), M3P3 (real device capability detection, Foundation Models generation adapter, async retrieval routing, extractive fallback), and M3P5 (prompt shaping layer, prompt injection detection, safety regression tests) are implemented. Milestone 3 core implementation is complete.
5. ~~Implement M4P1 (ConnectivityService) and M4P2 (import domain models and persistence).~~ **Done:** M4P1–P6 are complete. Milestone 4 (Online Enrichment) is finished.
6. ~~Implement M6P1–P5 (Siri, Apple Intelligence, and knowledge discovery).~~ **Done:** M6P1 App Intents foundation, M6P2 App Entities and Spotlight indexing, M6P3 FM-powered inventory completion, M6P4 AssistantSchema with navigation intents and onscreen content, and M6P5 RSS-based knowledge discovery with optional Brave Search enrichment are complete. Milestone 6 is finished.
