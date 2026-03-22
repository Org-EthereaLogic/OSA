# OSA SDLC Document Suite Index

Status: Initial draft complete, verification and cross-link pass complete.  
Primary audience: solo developer or very small iOS team.  
Related docs: [Problem Brief](./01-problem-brief.md), [PRD](./02-prd.md), [Technical Architecture](./05-technical-architecture.md), [Risk Register](./risk-register.md)

## Purpose Of This Suite

This suite defines the initial product, architecture, data, safety, quality, and release baseline for OSA, an offline-first iPhone preparedness handbook app with a grounded local assistant and optional online knowledge enrichment. The goal is implementation usefulness, not generic process coverage.

## Confirmed Facts

- The repository currently contains a minimal `README.md` and an existing prompt file at [docs/sdlc_doc_suite_prompt.md](./sdlc_doc_suite_prompt.md).
- No iOS project structure or shipped app code is present yet.
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

1. What is the minimum supported iOS version and device range for first release?
2. Is Foundation Models availability required for launch, or is extractive non-generative fallback acceptable on older hardware?
3. Which trusted domains and publishers are approved for online knowledge import at launch?
4. Should offline maps be in scope for v1, or should "local notes/maps/forest reference" start as text, images, and links only?
5. Is personal backup/export needed in the first release, or should all user data remain single-device only for v1?

## Decision Log Summary

- [ADR-0001](./adr/ADR-0001-offline-first-local-first.md): Critical workflows must function without connectivity.
- [ADR-0002](./adr/ADR-0002-grounded-assistant-only.md): The assistant is not a general chatbot and only answers from approved local sources and app data.
- [ADR-0003](./adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md): Online knowledge is usable by the assistant only after local persistence, attribution, normalization, and indexing.
- Architecture recommendation: prefer SwiftData for primary local persistence with repository boundaries that preserve an exit path to Core Data if needed.
- Retrieval recommendation: start with deterministic keyword and metadata ranking plus chunked local citations; defer embeddings until the corpus and evaluation data justify them.

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
13. ADRs in [docs/adr](./adr/)
14. [Risk Register](./risk-register.md)

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
| [ADR-0001-offline-first-local-first.md](./adr/ADR-0001-offline-first-local-first.md) | Records the offline-first local-first decision. | Initial draft complete |
| [ADR-0002-grounded-assistant-only.md](./adr/ADR-0002-grounded-assistant-only.md) | Records the grounded assistant-only decision. | Initial draft complete |
| [ADR-0003-online-knowledge-refresh-with-local-persistence.md](./adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md) | Records the online retrieval plus local persistence decision. | Initial draft complete |
| [risk-register.md](./risk-register.md) | Consolidated product and delivery risks with mitigation ownership. | Initial draft complete |
| [sdlc_doc_suite_prompt.md](./sdlc_doc_suite_prompt.md) | Original source prompt retained for context and traceability. | Preserved input |

## Current Suite Status

- Document creation status: complete for initial v0.1 draft set.
- Architecture confidence: medium; the repo has no app code yet, so several technical choices remain recommendations rather than confirmed implementation facts.
- Product confidence: medium-high; the product principles and safety boundaries are clear enough for MVP planning.
- Highest uncertainty areas: device support matrix, trusted-source policy, content review workflow ownership, and backup/export scope.

## Done Means

- Every required file exists under `/docs` with project-specific initial content.
- Cross-links are present between related documents.
- Decisions that materially shape implementation are captured in ADRs and summarized here.
- Open questions are consolidated here so they can be answered before coding begins.

## Next-Step Recommendations

1. Resolve the minimum OS and AI capability support matrix before creating the Xcode project.
2. Approve an initial trusted web source allowlist before implementing online knowledge refresh.
3. Convert the handbook chapter map and templates into seed content files after the first app skeleton exists.
