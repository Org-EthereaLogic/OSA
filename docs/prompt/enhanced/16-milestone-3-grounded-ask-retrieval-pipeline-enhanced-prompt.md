# Milestone 3 Phase 1 Enhanced Prompt: Grounded Ask Retrieval Pipeline

**Date:** 2026-03-23
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task sits at the seam between local search, retrieval ranking, citation packaging, assistant orchestration, and bounded Ask UI. It must reuse the existing FTS5 index, preserve offline-first grounding, and keep unsupported prompts safely refused.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow` with the note: `Next logical step: Milestone 3 - Grounded Ask. The retrieval pipeline (M3P1) is the natural starting point since it builds on the FTS5 search index already in place.`
- Project governance: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Product and architecture docs: `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Milestone context: `docs/adr/ADR-0002-grounded-assistant-only.md`, `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`, `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`
- Current code surface: `OSA/Features/Ask/AskScreen.swift`, `OSA/Assistant/README.md`, `OSA/Retrieval/README.md`, `OSA/Domain/Common/Models/SearchResult.swift`, `OSA/Persistence/SearchIndex/LocalSearchService.swift`, `OSA/Persistence/SearchIndex/SearchIndexStore.swift`, `OSATests/SearchIndexStoreTests.swift`

## Assumptions

- The repository root contains `project.yml`, `OSA.xcodeproj`, `AGENTS.md`, `CLAUDE.md`, and `docs/`.
- The existing FTS5 search index and `LocalSearchService` are the retrieval substrate for Milestone 3 and should be extended rather than replaced.
- The current Ask screen is still a placeholder and can remain simple until the retrieval contract is defined.
- Foundation Models capability detection is part of the Ask pipeline, but the retrieval layer itself must remain local and deterministic.
- Online search, import, and refresh are Milestone 4 concerns and stay out of scope unless a tiny shared interface is required.
- The first retrieval slice should cover local handbook sections, quick cards, inventory, checklists, and notes already represented in the local search corpus.

## Mission Statement

Implement the first grounded Ask retrieval slice by turning the existing local search stack into a retrieval pipeline that normalizes queries, enforces scope and safety, ranks local evidence deterministically, and packages citation-ready results for Ask without exposing unsupported knowledge or uncited answers.

## Technical Context

Milestone 2 already provides a local FTS5 search index, a `LocalSearchService`, and unified search-result types. Milestone 3 should layer grounded Ask behavior on top of that substrate. The work is not to invent a new database or a general chatbot. The work is to build a retrieval pipeline that can reliably answer from approved local evidence, refuse unsupported prompts, and hand clean evidence packages to assistant formatting or extractive fallback code.

The pipeline should treat local evidence as the source of truth. Retrieval must stay deterministic, inspectable, and bounded. If the user asks for something outside the approved corpus or outside the app's safety policy, the pipeline should refuse or redirect rather than improvising.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `SearchIndexStore` and `LocalSearchService` already support local FTS5 search. | A higher-level retrieval pipeline produces ranked evidence packages for Ask. |
| `AskScreen.swift` is a placeholder with a text field and zero-state copy. | Ask can submit queries into a bounded retrieval flow and display grounded outcomes. |
| Search results exist as generic local search rows. | Retrieval results carry citation metadata, source labels, and stable local identifiers. |
| No capability-aware Ask orchestration exists yet. | Capability detection cleanly branches between grounded generation, extractive fallback, and refusal states. |
| No dedicated citation packaging layer exists. | Citations are produced as first-class local evidence references tied to records. |

## Pre-Flight Checks

1. Confirm the project root and read the governing documents before changing code.
   *Success signal: the agent can name the repo root and the docs it used to scope Milestone 3.*

2. Inspect the current Ask, Retrieval, Assistant, and SearchIndex code paths before implementation.
   *Success signal: the agent can list the exact files or folders it will add or edit.*

3. Confirm which local record families are already indexed and usable for grounded Ask.
   *Success signal: the agent can state the included evidence families and any deferred ones before writing code.*

4. Check the current tests around search index behavior and retrieval-adjacent code.
   *Success signal: the agent can point to the existing test coverage that will be extended or reused.*

## Phased Instructions

### Phase 1: Freeze The Milestone 3P1 Retrieval Slice

1. Treat the existing FTS5 search index as the initial candidate-evidence source.
   *Success signal: the retrieval pipeline reuses the current search substrate rather than introducing a second index.*

2. Limit the first slice to approved local evidence already present in the corpus.
   *Success signal: the scope explicitly includes handbook sections, quick cards, inventory, checklists, and notes, while online refresh and imported web knowledge remain deferred.*

3. Define the retrieval contract before building UI polish.
   *Success signal: the agent names the input, output, and refusal states the pipeline must support.*

4. Establish stable evidence identity rules.
   *Success signal: each evidence item carries a stable local record ID, record kind, human-readable source label, and enough metadata to form a durable citation.*

### Phase 2: Create Domain Contracts For Retrieval And Citations

1. Add domain-facing retrieval and citation models under `OSA/Domain/`.
   *Success signal: the new types are plain Swift values that do not import SQLite, SwiftData, or search-index internals.*

2. Add concrete protocols for querying grounded evidence and packaging citations.
   *Success signal: the contracts cover query normalization, scope filtering, ranked retrieval, citation packaging, and refusal or insufficient-evidence states.*

3. Keep the method surface near-term and workflow-driven.
   *Success signal: signatures map to real Ask actions such as submit query, return evidence, show sources, and record unsupported or blocked requests.*

4. Add only the shared support types that materially improve correctness.
   *Success signal: types like retrieval scope, evidence item, citation reference, answer mode, or refusal reason exist because the workflow needs them, not for abstraction theater.*

### Phase 3: Implement The Retrieval Pipeline On Top Of FTS5

1. Build a higher-level retrieval service that wraps the current local search implementation.
   *Success signal: the service can call into the existing search index and then normalize, filter, rank, and package the results for Ask.*

2. Normalize user queries deterministically before search.
   *Success signal: empty, noisy, or trivially unsupported input is handled without querying the index unnecessarily.*

3. Apply scope and safety policy before final answer assembly.
   *Success signal: the pipeline can reject or narrow requests before they become answer candidates.*

4. Re-rank results using explicit heuristics that are stable across runs.
   *Success signal: the pipeline can prefer exact title or heading matches, quick-card priority for urgent topics, and other deterministic local signals without relying on opaque behavior.*

5. Preserve provenance for every evidence item.
   *Success signal: each returned item can be traced back to a local record, including title, section or chunk label when available, and the source family that produced it.*

6. Keep the output small and inspectable.
   *Success signal: retrieval returns a compact, ordered evidence set that can feed either generation or extractive fallback without leaking implementation details.*

### Phase 4: Add Citation Packaging And Capability Detection

1. Define citation packaging as a first-class step, not an afterthought.
   *Success signal: Ask can render sources from local record identifiers and human-readable labels without reconstructing them ad hoc in the UI.*

2. Implement refusal and insufficient-evidence states explicitly.
   *Success signal: unsupported or under-evidenced prompts produce a bounded response instead of uncited prose.*

3. Add a capability-detection boundary for grounded generation versus extractive fallback.
   *Success signal: the pipeline can select a mode such as grounded-generation, extractive-only, or unavailable without making the retrieval layer itself model-specific.*

4. Keep generation adapters separate from retrieval.
   *Success signal: the retrieval layer supplies evidence and citation packages, while assistant formatting or model adapters decide how to phrase the final answer.*

### Phase 5: Wire The Bounded Ask UI

1. Replace the Ask placeholder with a retrieval-backed state flow.
   *Success signal: Ask can submit a query, show progress, and present a grounded result, citation list, or refusal state.*

2. Keep the Ask UI calm and constrained.
   *Success signal: the surface favors answer, sources, and next-step suggestions over chat-like affordances.*

3. Do not let the UI bypass the retrieval contract.
   *Success signal: all answers visible in Ask still originate from the retrieval pipeline and its citation packaging.*

4. Preserve a path to future assistant refinement.
   *Success signal: the UI can later accept better generation or formatting without changing the retrieval contract.*

### Phase 6: Add Focused Tests And Verification

1. Add tests for query normalization, ranking, and refusal behavior.
   *Success signal: the tests demonstrate stable retrieval behavior rather than just type compilation.*

2. Add tests for citation packaging and source identity.
   *Success signal: the tests prove that evidence can be traced to local records and that citations remain stable.*

3. Add tests for capability branching and unsupported prompts.
   *Success signal: the tests prove the pipeline can fall back or refuse in a bounded way when generation is unavailable or the scope is unsupported.*

4. Run the available project build, test, and security checks.
   *Success signal: any available verification completes successfully, or blockers are recorded precisely as unverified.*

## Guardrails

- Do not add online search, import, refresh, or network dependency in this phase.
- Do not invent a general-purpose chatbot.
- Do not let uncited prose escape the retrieval or assistant boundary.
- Do not expose raw search-index implementation details to feature views.
- Do not replace the current FTS5 search substrate unless the codebase itself forces that change.
- Do not widen scope to Milestone 4 imported knowledge or refresh logic.
- Do not claim that Ask is grounded unless the answer is backed by local evidence and citations.

## Verification Checklist

- [ ] Project root and governing docs were checked before editing.
- [ ] The Milestone 3P1 retrieval slice was explicitly frozen before implementation.
- [ ] Domain-facing retrieval and citation models exist without search-index leakage.
- [ ] A higher-level retrieval pipeline wraps the existing FTS5 search substrate.
- [ ] Citation packaging returns stable local references.
- [ ] Capability detection supports grounded-generation, extractive-only, or unavailable states.
- [ ] The Ask UI can surface grounded answers or refusal states without bypassing retrieval.
- [ ] Focused tests cover normalization, ranking, citations, and refusal behavior.
- [ ] Build and test verification was run or marked unverified with a precise blocker.
- [ ] Security analysis was run or marked unverified with a precise blocker.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| The current search index cannot support the retrieval contract cleanly | Keep the FTS5 index as the candidate source and layer retrieval logic above it rather than replacing the substrate prematurely. |
| A proposed protocol leaks SQLite, FTS5, or other persistence details | Move those details back into `OSA/Persistence` and expose only domain-friendly retrieval and citation values. |
| Ask starts behaving like a general chatbot | Tighten the scope and refusal rules so all visible answers remain grounded in local evidence. |
| Unsupported prompts return uncited prose | Convert the path to a refusal or insufficient-evidence state and require citations for any substantive answer. |
| Capability detection becomes tangled with retrieval logic | Keep model availability behind a small boundary so retrieval remains deterministic and local. |
| Verification tooling is unavailable | Report the exact blocker and keep the corresponding claims unverified. |

## Out Of Scope

- Online search, web import, or background refresh.
- New persistence backends or a replacement for the current FTS5 search index.
- Full assistant prompt engineering beyond what is needed to hand off evidence and citations.
- UI polish beyond the minimum Ask flow needed to surface grounded answers.
- Imported knowledge, sync, or account-driven features.

## Report Format

When implementation is complete, report back in this structure:

1. Files added and files changed.
2. Retrieval slice chosen and deferred surfaces.
3. Domain models and protocols added.
4. Retrieval pipeline and citation packaging added.
5. Capability detection and Ask UI integration added.
6. Tests added and what each one proves.
7. Verification commands run and their outcomes.
8. Security-analysis status, including any unavailable tooling.
9. Remaining risks, deferred work, or explicitly unverified claims.
