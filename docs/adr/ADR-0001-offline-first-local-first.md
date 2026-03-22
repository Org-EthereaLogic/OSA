# ADR-0001: Offline-First Local-First

Status: Accepted  
Date: 2026-03-21  
Related docs: [Problem Brief](../01-problem-brief.md), [PRD](../02-prd.md), [Technical Architecture](../05-technical-architecture.md), [Sync And Refresh](../07-sync-connectivity-and-web-knowledge-refresh.md)

## Confirmed Facts

- The product intent requires dependable use during outages, travel, and unreliable connectivity.
- Core workflows include both curated reference content and user-authored household data.

## Assumptions

- The first release will not rely on a backend for core functionality.
- Users will reasonably expect the app to remain useful in conditions where network access is unavailable.

## Recommendations

- Treat any proposed online dependency for core flows as an exception requiring explicit review.
- Design storage, retrieval, and UX around local readiness first.

## Open Questions

- Whether offline maps or other larger assets belong in v1 remains unresolved.
- Whether future sync should be introduced at all is a later decision, not part of this ADR.

## Context

OSA is intended to be useful during poor connectivity, power interruptions, travel, and stressful conditions. The product includes a handbook, quick cards, inventory, checklists, notes, and a grounded assistant. These functions lose much of their value if they depend on live network access.

## Decision

The app is offline-first and local-first. All critical user workflows must function without connectivity.

Critical workflows include:

- browsing handbook content
- searching local content
- using Ask over local approved content and app data
- viewing quick cards
- viewing and editing inventory
- viewing and editing checklists
- personal notes

## Rationale

- Preparedness scenarios often correlate with unreliable connectivity.
- Calm emergency UX requires instant availability and predictable behavior.
- Local-first storage strengthens privacy and simplifies the v1 system.
- The solo-developer scope is more manageable when online systems are optional rather than foundational.

## Tradeoffs

- More up-front work is required for local data modeling, indexing, and seed content packaging.
- Device storage use will be higher because usable knowledge must live on device.
- Some live-web behaviors will feel slower because content must be imported and normalized before use.

## Consequences

- Architecture, UX, and QA must treat offline as the default, not an exception path.
- Online features must enrich the local corpus rather than replace it.
- Release readiness depends on a strong offline test matrix.
- Future cloud sync, if added, must not break local autonomy.

## Done Means

- Every feature marked critical in the PRD has a fully offline path.
- Connectivity loss during use does not make existing local data unavailable.
- Design and engineering decisions that would introduce mandatory online dependencies require a new ADR.
