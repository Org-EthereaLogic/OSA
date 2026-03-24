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
- Milestone 3 Phase 1 (Grounded Ask retrieval pipeline) is implemented: domain-facing retrieval and citation models (`EvidenceItem`, `CitationReference`, `RetrievalOutcome`, `AnswerMode`, `ConfidenceLevel`, `RefusalReason`), `RetrievalService`, `SensitivityClassifier`, and `CapabilityDetector` protocols, `LocalRetrievalService` pipeline (normalize → classify → search → rank → cite → assemble), `SensitivityPolicy` for blocked/sensitive topic enforcement, `DeviceCapabilityDetector` (extractive-only default), deterministic `EvidenceRanker`, and a retrieval-backed Ask UI with answer/citation/refusal states. Focused tests cover normalization, sensitivity, ranking, and end-to-end retrieval.
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
17. ADRs in [docs/adr](../adr/)
17. [Risk Register](./risk-register.md)

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
| [ADR-0001-offline-first-local-first.md](../adr/ADR-0001-offline-first-local-first.md) | Records the offline-first local-first decision. | Initial draft complete |
| [ADR-0002-grounded-assistant-only.md](../adr/ADR-0002-grounded-assistant-only.md) | Records the grounded assistant-only decision. | Initial draft complete |
| [ADR-0003-online-knowledge-refresh-with-local-persistence.md](../adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md) | Records the online retrieval plus local persistence decision. | Initial draft complete |
| [ADR-0004-ios18-minimum-target-with-foundation-models.md](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md) | Records the iOS 18 minimum target and Foundation Models with extractive fallback decision. | Accepted |
| [risk-register.md](./risk-register.md) | Consolidated product and delivery risks with mitigation ownership. | Initial draft complete |
| [sdlc_doc_suite_prompt.md](../prompt/enhanced/sdlc_doc_suite_prompt.md) | Original source prompt retained for context and traceability. | Preserved input |

## Current Suite Status

- Document creation status: complete for initial v0.1 draft set.
- Architecture confidence: high; Milestones 1–2 are complete and Milestone 3 Phase 1 (retrieval pipeline, sensitivity policy, capability detection, citation packaging, and bounded Ask UI) is implemented. Remaining M3 work: Foundation Models generation adapter, prompt shaping, and safety regression tests.
- Product confidence: medium-high; the product principles and safety boundaries are clear enough for MVP planning.
- Highest uncertainty areas: Foundation Models integration quality and retrieval ranking tuning with real corpus data.

## Done Means

- Every required file exists under `docs/sdlc/` with project-specific initial content.
- Cross-links are present between related documents.
- Decisions that materially shape implementation are captured in ADRs and summarized here.
- Open questions are consolidated here so they can be answered before coding begins.

## Next-Step Recommendations

1. ~~Resolve the minimum OS and AI capability support matrix before creating the Xcode project.~~ **Resolved:** iOS 18.0 minimum, Foundation Models with extractive fallback. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md). Xcode project scaffolded.
2. ~~Approve an initial trusted web source allowlist before implementing online knowledge refresh.~~ **Resolved:** Three-tier allowlist defined with 15 PNW-focused sources.
3. Expand the first bundled seed packs into the broader MVP handbook, quick-card, and checklist corpus.
4. ~~Begin Milestone 3 (Grounded Ask): retrieval pipeline, citation packaging, capability detection, and bounded Ask UI.~~ **In progress:** M3P1 (retrieval pipeline, sensitivity policy, citation packaging, capability detection, bounded Ask UI) is implemented. Remaining: Foundation Models generation adapter (M3P3), prompt shaping and safety guardrails (M3P5).
