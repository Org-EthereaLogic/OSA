# ADR-0003: Online Knowledge Refresh With Local Persistence

Status: Accepted  
Date: 2026-03-21  
Related docs: [Technical Architecture](../05-technical-architecture.md), [Data Model](../06-data-model-local-storage.md), [Sync And Refresh](../07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](../08-ai-assistant-retrieval-and-guardrails.md)

## Confirmed Facts

- The product allows optional online enrichment but remains offline-first.
- Source provenance and local citations are required for assistant trustworthiness.

## Assumptions

- Some source discovery and refresh will happen on-device without a mandatory backend in v1.
- The app can store enough imported material locally to provide future offline value.

## Recommendations

- Keep import, normalization, and local commit as separate explicit stages.
- Do not allow live remote pages to bypass the local review and persistence pipeline.

## Open Questions

- The launch allowlist of trusted domains still needs explicit product approval.
- The amount of background auto-refresh allowed without user review remains unresolved.

## Context

OSA may optionally use the web to discover or refresh trusted knowledge, but the product must remain offline-first and grounded. Using live web results directly inside Ask would weaken provenance, create inconsistent offline behavior, and increase hallucination risk.

## Decision

When online, the app may retrieve trusted external knowledge, but only persisted, attributed, locally stored knowledge becomes part of the usable offline knowledge base.

## Rationale

- Local persistence preserves offline usability after the initial import.
- Attribution and normalization create a reviewable evidence trail.
- The assistant can cite stable local records instead of volatile live pages.
- The import pipeline provides a place to enforce trust, safety, and deduplication rules.

## Tradeoffs

- Online answers will feel more deliberate than instant live browsing.
- Import, normalization, and indexing add engineering complexity.
- The app needs storage and stale-content management for imported knowledge.

## Consequences

- The assistant may offer online search when connected, but not answer from live remote pages directly.
- Imported content must carry source metadata, trust level, timestamps, and chunk IDs.
- QA must test interrupted imports, stale content, and deduplication behavior.
- Source-review UX becomes a product requirement rather than an optional enhancement.

## Done Means

- Imported knowledge is queryable offline after successful local commit.
- Ask cites local imported records, not ephemeral live web pages.
- Unreviewed or partially fetched remote content never enters the approved local corpus.
