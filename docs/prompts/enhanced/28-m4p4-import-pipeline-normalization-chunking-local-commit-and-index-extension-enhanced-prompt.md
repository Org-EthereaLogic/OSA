# M4P4 Enhanced Prompt: Import Pipeline - Normalization, Chunking, Local Commit, And Index Extension

**Date:** 2026-03-26
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** High
**Complexity Justification:** This is the first cross-layer online-enrichment slice that must bridge M4P3 networking output into M4P2 persistence, extend the local FTS5 corpus, and make approved imported knowledge retrievable and citeable by Ask without leaking pending or unreviewed content into the assistant corpus.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-Prompt-workflow  M4P4: Import pipeline - normalization, chunking, local commit, and index extension.` | The requested slice is the M4 critical-path consumer of `TrustedSourceFetchResponse`: normalize fetched HTML or text, chunk it, persist it locally, and extend search so imported knowledge becomes usable offline. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | The change must follow `Plan -> Act -> Verify -> Report`, preserve offline-first behavior, keep assistant grounding intact, and avoid speculative architecture. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M4P1, M4P2, and M4P3 are complete. M4P4 is the next strict dependency before refresh or Ask online-offer UX can land. |
| `docs/sdlc/05-technical-architecture.md` | `OSA/Networking/ImportPipeline/` is the correct home for normalization and chunking orchestration. Imported knowledge must be persisted locally before Ask can use it. The search corpus is FTS5-backed, and retrieval is deterministic. |
| `docs/sdlc/06-data-model-local-storage.md` | `SourceRecord`, `ImportedKnowledgeDocument`, and `KnowledgeChunk` already define the local schema. `SearchIndex.sqlite` is the sidecar store for retrieval, and chunk identity should be stable where feasible. |
| `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` | Remote content only becomes answerable after normalization, attribution, chunking, local commit, indexing, and approval-state checks. Pending or partially processed content must not enter Ask. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Ask may answer only from approved local evidence. Imported-source citations must come from durable local records, not live URLs. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Raw fetched content remains untrusted until normalized and approved locally. Pending imports must not become assistant-usable. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Import-path changes require unit and integration coverage for normalization, indexing, interrupted-commit behavior, and retrieval discoverability. |
| `docs/adr/ADR-0001-offline-first-local-first.md` | Online enrichment exists only to improve the local corpus; it must never become a mandatory live dependency. |
| `docs/adr/ADR-0002-grounded-assistant-only.md` | Imported knowledge is valid Ask input only after it is approved local content. |
| `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md` | The pipeline must enforce the boundary between live remote content and stable local records. |
| `docs/prompt/enhanced/27-m4p3-trusted-source-allowlist-and-http-client-enhanced-prompt.md` | M4P3 already provides the upstream fetch contract and exact scope boundary. M4P4 should consume that output, not redesign fetching. |
| `OSA/Networking/DTOs/TrustedSourceFetchResponse.swift` | M4P4 starts from a raw payload DTO containing requested URL, final URL, status, content type, bytes, and fetch timestamp. |
| `OSA/Networking/Clients/TrustedSourceAllowlist.swift`, `TrustedSourceHTTPClient.swift` | Trust level and default review status already map from the approved allowlist. M4P4 should reuse those mappings rather than inventing new trust logic. |
| `OSA/Domain/ImportedKnowledge/Repositories/ImportedKnowledgeRepository.swift` and `OSA/Persistence/SwiftData/Repositories/SwiftDataImportedKnowledgeRepository.swift` | Source, document, and chunk persistence contracts are already available and should be used instead of direct SwiftData access. |
| `OSA/Domain/Common/Models/SearchResult.swift`, `OSA/Domain/Common/Repositories/SearchRepositories.swift`, `OSA/Persistence/SearchIndex/LocalSearchService.swift`, `OSA/Persistence/SearchIndex/SearchIndexStore.swift` | The FTS5 corpus currently supports handbook, quick cards, inventory, checklists, and notes only. Imported knowledge requires a new search kind and index entry path. |
| `OSA/Retrieval/Querying/LocalRetrievalService.swift`, `OSA/Domain/Ask/Models/RetrievalModels.swift`, `OSA/Domain/Settings/AskScopeSettings.swift` | Ask currently has no imported-knowledge retrieval scope and no item-specific citation resolution for imported chunks. M4P4 must extend retrieval, not only indexing. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` | The composition root already wires repositories, search, retrieval, connectivity, and trusted fetch client. M4P4 should add import-pipeline dependencies here if needed, without exposing persistence details to feature views. |

## Mission Statement

Implement M4P4 by building the first production import pipeline that takes a `TrustedSourceFetchResponse`, normalizes supported HTML or text into clean local content, derives retrieval-sized `KnowledgeChunk` records, persists `SourceRecord` plus `ImportedKnowledgeDocument` plus chunks through the existing repository protocols, and extends the FTS5 search and Ask retrieval surfaces so approved imported knowledge becomes discoverable, citeable, and usable offline.

## Technical Context

M4P3 already solves `who may be fetched` and `how raw content is fetched safely`. M4P2 already solves `where imported knowledge is stored`. The critical missing layer is the consumer that turns raw fetched bytes into durable local evidence.

That missing layer is more than a parser. It must bridge four boundaries correctly:

1. Raw remote bytes to normalized local text.
2. Normalized text to citeable `KnowledgeChunk` records.
3. In-memory transformed content to repository-backed local commit.
4. Persisted imported chunks to FTS5 and Ask retrieval.

The pipeline must also preserve the approval boundary. Tier 1 and Tier 2 sources default to `.approved`, so their searchable chunks may enter the FTS index immediately. Tier 3 sources default to `.pending`, so they may be persisted locally but must not be indexed for Ask or general search until later review mechanisms exist.

Keep M4P4 narrow and explicit. This phase should not implement background refresh orchestration, retry workers, review UI, candidate-source discovery UI, or live-web answer behavior. Those belong to M4P5 and M4P6.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `TrustedSourceFetchResponse` exists, but nothing consumes it. | There is one import-pipeline entry point that accepts fetched content and produces locally persisted imported knowledge records. |
| Imported-knowledge repositories exist, but there is no normalizer or chunker. | Supported HTML and plain-text payloads are normalized deterministically and chunked into retrieval-sized `KnowledgeChunk` records. |
| The FTS5 index does not contain imported knowledge. | Approved imported chunks are indexed under a dedicated search-result kind and are queryable offline. |
| Ask has no imported-knowledge retrieval scope and no imported-source citation resolution. | Ask includes approved imported knowledge in its local retrieval scope and can render stable local citations for those chunks. |
| Tier 3 pending sources could accidentally leak into retrieval if indexing is naive. | Persisted-but-pending imports remain out of the searchable assistant corpus until a later review flow approves them. |
| Re-importing the same source would currently risk duplicate rows or duplicate index entries. | The pipeline handles repeat imports with at least minimal dedupe and version-aware behavior. |

## Pre-Flight Checks

1. Confirm the upstream fetch contract and allowlist are already in place.

   ```bash
   rg -n "TrustedSourceFetchResponse|TrustedSourceAllowlist|TrustedSourceHTTPClient" OSA/Networking
   ```

   *Success signal: M4P4 starts from existing M4P3 types rather than adding a second fetch model.*

2. Confirm the imported-knowledge persistence contracts already exist.

   ```bash
   rg -n "protocol ImportedKnowledgeRepository|struct SourceRecord|struct ImportedKnowledgeDocument|struct KnowledgeChunk" OSA/Domain OSA/Persistence
   ```

   *Success signal: the pipeline can commit through domain repositories without importing SwiftData into feature or import orchestration code.*

3. Confirm the current search and retrieval gap.

   ```bash
   rg -n "enum SearchResultKind|protocol SearchService|retrievalScopes|sourceLabel\(|displayLabel" OSA
   ```

   Expected findings:

   - `SearchResultKind` has no imported-knowledge case.
   - `SearchService` has no imported-knowledge indexing method.
   - `AskScopeSettings` does not include imported knowledge in default scopes.
   - `CitationReference.displayLabel` does not yet handle imported-source citations.

   *Success signal: the executor understands that indexing and retrieval both need extension.*

4. Freeze the supported payload formats for this phase.

   *Success signal: M4P4 supports only the text-oriented payload types already accepted by M4P3: `text/html`, `application/xhtml+xml`, and `text/plain`.*

5. Freeze the milestone boundary before editing.

   *Success signal: the executor can state plainly that M4P4 implements normalization, chunking, local commit, and search or retrieval extension only; it does not implement refresh scheduling, retry workers, review UI, or Ask online-offer UX.*

## Phased Instructions

### Phase 1: Investigation And Setup

1. Read the M4P3 networking output and the M4P2 repository interfaces first.
   *Success signal: the import pipeline is designed around `TrustedSourceFetchResponse`, `TrustedSourceAllowlist`, `ImportedKnowledgeRepository`, and `SearchService`, not direct database or UI code.*

2. Choose the smallest coherent production surface for M4P4.
   Recommended file set:

   - `OSA/Networking/ImportPipeline/ImportedKnowledgeNormalizer.swift`
   - `OSA/Networking/ImportPipeline/KnowledgeChunker.swift`
   - `OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift`
   - one small supporting model or error file if needed

   *Success signal: the implementation is explicit enough to test, but does not introduce a speculative import framework or background coordinator.*

3. Keep all persistence access behind repository protocols.
   *Success signal: `OSA/Networking/ImportPipeline/` does not import SwiftData, and `OSA/Features/` remains storage-framework agnostic.*

### Phase 2: Implement Normalization

1. Create a dedicated normalizer that converts a `TrustedSourceFetchResponse` into a normalized intermediate value suitable for persistence and chunking.

   Recommended intermediate fields:

   - `title`
   - `normalizedMarkdown`
   - `plainText`
   - `documentType`
   - `contentHash`
   - `versionHash`
   - `publisherDomain`
   - `sourceURL`

   *Success signal: chunking and persistence do not need to re-parse raw bytes or `URLResponse` metadata.*

2. Support `text/plain` and HTML or XHTML deterministically without adding a heavy third-party parser unless absolutely necessary.
   *Success signal: the implementation prefers Foundation-based normalization and simple structural heuristics over new dependency cost.*

3. For HTML or XHTML payloads, normalize with the smallest coherent approach that still preserves retrieval value.
   Minimum expectations:

   - remove obviously non-content noise such as scripts and styles if present in extracted text
   - decode text cleanly to Unicode
   - collapse repeated whitespace without flattening meaningful paragraph breaks
   - preserve heading or section boundaries where reasonably detectable
   - derive a usable title from the page title, first heading, or allowlist publisher fallback

   *Success signal: the stored `plainText` and `normalizedMarkdown` are calm, readable, and retrieval-friendly rather than raw HTML dumps.*

4. For `text/plain`, preserve paragraph boundaries and normalize line endings while avoiding unnecessary markdown decoration.
   *Success signal: plain-text sources remain faithful and searchable without being over-transformed.*

5. Derive `DocumentType` with conservative heuristics.
   Recommended rule:

   - use `.checklist` only for obvious checklist-like structures
   - use `.guide` or `.reference` only when the title or structure makes that clear
   - default to `.article` when uncertain

   *Success signal: document typing is deterministic and avoids false precision.*

6. Compute stable hashes from normalized content, not raw bytes alone.
   *Success signal: repeated fetches of semantically identical normalized content produce the same `contentHash` and `versionHash` even if raw HTML formatting differs slightly.*

7. Reject empty or unusable normalized content explicitly.
   *Success signal: the import pipeline fails with a deterministic error instead of committing blank documents or blank chunks.*

### Phase 3: Implement Chunking

1. Create a chunker that accepts the normalized intermediate document and outputs ordered `KnowledgeChunk` values.
   *Success signal: chunking is a dedicated, testable step rather than being hidden inside persistence logic.*

2. Follow the repository architecture guidance for imported content chunking.
   Minimum behavior:

   - prefer heading-aware chunk boundaries when headings exist
   - otherwise group adjacent paragraphs into chunks
   - target roughly 150 to 400 words per chunk when possible
   - avoid splitting in the middle of a sentence unless a large payload leaves no reasonable alternative

   *Success signal: chunks are retrieval-sized and citeable, not whole-document blobs.*

3. Populate chunk fields deliberately.

   - `id`: unique record ID for persistence and indexing
   - `localChunkID`: deterministic identifier derived from normalized document identity plus chunk content or position
   - `headingPath`: heading text or document-title fallback
   - `plainText`: searchable chunk body
   - `sortOrder`: deterministic order from the normalized document
   - `tokenEstimate`: rough heuristic from word count
   - `tags`: conservative metadata only
   - `trustLevel`: inherited from the trusted-source definition
   - `contentHash`: per-chunk normalized hash
   - `isSearchable`: `true` only when the source review state is `.approved`

   *Success signal: M4P5 can later reason about refreshes and stable citations without redesigning chunk identity.*

4. Keep tags conservative and explainable.
   Recommended tags:

   - publisher domain
   - document type
   - a small number of normalized title or heading keywords if easily available

   *Success signal: ranking gains useful metadata without noisy tag inflation.*

### Phase 4: Implement Local Commit Orchestration

1. Create a single import-pipeline entry point, such as `ImportedKnowledgeImportPipeline`, that coordinates normalization, chunking, repository commit, and indexing.

   Recommended dependency set:

   - `ImportedKnowledgeRepository`
   - `SearchService`
   - `TrustedSourceAllowlist` or its lookup helper
   - optional date or hash helpers

   *Success signal: one explicit service owns the M4P4 workflow instead of scattering logic across views, repositories, or the composition root.*

2. Resolve trust metadata from the final URL, not only the requested URL.
   *Success signal: redirects that remain on approved hosts still produce correct publisher and review metadata.*

3. Persist `SourceRecord`, `ImportedKnowledgeDocument`, and `KnowledgeChunk` through the existing repository interface only.
   Populate required `SourceRecord` fields using the normalized document plus allowlist metadata.

   Minimum expectations:

   - `sourceURL`: final URL string
   - `publisherDomain`: final URL host
   - `publisherName`: allowlist publisher name
   - `sourceTitle`: normalized title fallback to publisher name if needed
   - `fetchedAt`: from `TrustedSourceFetchResponse`
   - `lastReviewedAt`: `fetchedAt` for auto-approved sources and the same timestamp as a temporary local-inspection placeholder for pending sources until review UI exists
   - `contentHash`: normalized document hash
   - `trustLevel`: allowlist trust level
   - `reviewStatus`: allowlist default review status
   - `isActive`: `true`
   - `staleAfter`: a centralized MVP default, such as 30 days after fetch, documented in code for later M4P5 tuning
   - `localChunkIDs`: the deterministic `localChunkID` values of committed chunks

   *Success signal: all required domain fields are populated coherently without inventing a parallel source schema.*

4. Implement minimal dedupe and version-aware behavior.

   Minimum acceptable behavior:

   - if no existing source matches the final URL, create a new source, document, and chunk set
   - if an existing source matches and the normalized content hash is unchanged, refresh source metadata and avoid duplicating document or chunk records
   - if an existing source matches and the content hash changed, create a new document, set `supersedesDocumentID` to the previous latest document when possible, replace or retire the previous searchable chunk set for that source, and update the source metadata to the new active version

   *Success signal: repeated imports do not create uncontrolled duplicates and future refresh work has a coherent baseline.*

5. Sequence commit work to avoid partial searchable state.
   Recommended order:

   1. normalize
   2. chunk
   3. create or update source
   4. create document
   5. create chunks
   6. update source with `localChunkIDs`
   7. index searchable chunks only after persistence succeeds

   *Success signal: a failure before indexing never leaves Ask with references to uncommitted content.*

6. Add best-effort rollback or cleanup for mid-commit failures.
   *Success signal: failed imports do not leave orphaned searchable index entries, and orphaned persistence rows are minimized.*

7. Do not build background retry or queue orchestration in M4P4.
   *Success signal: `PendingOperationRepository` remains untouched unless a very small, localized status write is truly necessary, and no worker loop or scheduler is introduced.*

### Phase 5: Extend Search And Ask Retrieval

1. Add a dedicated imported-knowledge search kind.
   Update:

   - `OSA/Domain/Common/Models/SearchResult.swift`
   - `OSA/Features/Library/SearchResultsView.swift`

   Recommended case name: `.importedKnowledge`

   *Success signal: imported chunks have a first-class result kind instead of masquerading as handbook or notes.*

2. Extend `SearchService` and `LocalSearchService` with a focused imported-knowledge indexing path.
   The new index method should accept the chunk and the parent source or document metadata needed to create a useful FTS entry.

   Recommended indexing shape:

   - `entry_id`: `KnowledgeChunk.id`
   - `kind`: `.importedKnowledge`
   - `title`: source title plus chunk heading when helpful
   - `body`: chunk plain text
   - `tags`: chunk tags plus publisher-domain metadata if useful

   *Success signal: approved imported chunks are searchable via the same FTS5 store without weakening existing content types.*

3. Index only approved searchable chunks.
   *Success signal: Tier 3 pending sources may be persisted, but they do not appear in `SearchResultsView`, local search, or Ask retrieval until a later approval phase changes their review state.*

4. Extend Ask retrieval scope to include imported knowledge by default.
   Update:

   - `OSA/Domain/Ask/Models/RetrievalModels.swift`
   - `OSA/Domain/Settings/AskScopeSettings.swift`
   - `OSA/Retrieval/Querying/LocalRetrievalService.swift`

   Recommended behavior:

   - add `.importedKnowledge` to `RetrievalScope`
   - include it in `AskScopeSettings.retrievalScopes(...)` by default
   - map it to `.importedKnowledge` in `LocalRetrievalService`

   *Success signal: Ask searches approved imported knowledge in the normal local path without any new online dependency or special-case UI flow.*

5. Extend `LocalRetrievalService` to resolve imported-source citation details using `ImportedKnowledgeRepository`.
   This likely requires injecting the imported-knowledge repository into the retrieval service from `AppDependencies`.

   Minimum behavior for `.importedKnowledge` results:

   - load the `KnowledgeChunk` by indexed chunk ID
   - load the parent document and source when needed
   - produce a citation title based on the imported document title or heading path
   - produce a `sourceLabel` that identifies the imported source, such as publisher name or publisher domain

   *Success signal: Ask citations are still local and durable, but no longer generic or misleading for imported evidence.*

6. Update answer-confidence handling to count approved imported knowledge as grounded local evidence.
   *Success signal: Ask does not artificially under-rank or under-report confidence simply because the approved evidence came from imported local content rather than handbook seed content.*

7. Extend `CitationReference.displayLabel` and any related formatting so imported citations render cleanly.
   *Success signal: imported-source citations remain distinguishable from handbook, quick card, inventory, checklist, and note citations.*

### Phase 6: Add Focused Tests

1. Add `OSATests/ImportedKnowledgeNormalizerTests.swift`.
   Cover at least:

   - HTML normalization produces readable title and body text
   - `text/plain` normalization preserves paragraphs
   - empty or unusable content fails deterministically
   - document-type heuristics are conservative and stable

   *Success signal: normalization is deterministic and regression-resistant.*

2. Add `OSATests/KnowledgeChunkerTests.swift`.
   Cover at least:

   - heading-aware chunking
   - paragraph-group fallback chunking
   - stable `sortOrder`
   - non-empty chunk text
   - deterministic `localChunkID` behavior for unchanged normalized input
   - pending versus approved `isSearchable` gating

   *Success signal: chunk structure is executable behavior, not a hidden heuristic.*

3. Add `OSATests/ImportedKnowledgeImportPipelineTests.swift` using repository doubles or in-memory repository implementations and a stub search service.
   Cover at least:

   - first import creates source, document, chunks, and searchable index entries for approved sources
   - pending sources persist locally but do not create index entries
   - same-source same-hash re-import avoids duplicate documents or chunks
   - same-source changed-content re-import creates a new document version and replaces searchable chunk indexing coherently
   - failures before indexing do not leave searchable residue

   *Success signal: the end-to-end M4P4 workflow is verified without live networking.*

4. Extend retrieval tests.
   Update `OSATests/LocalRetrievalServiceTests.swift` to cover at least:

   - `.importedKnowledge` scope mapping
   - imported-source citation labels
   - imported approved evidence contributing to grounded confidence
   - pending imported content staying out of retrieval results

   *Success signal: Ask integration is tested where the actual retrieval contract lives.*

5. Extend search tests as needed.
   Update or add tests around `SearchResultKind` and the imported-knowledge indexing method so FTS queries return imported chunks under the correct kind.

   *Success signal: the index extension is covered, not only the persistence step.*

### Phase 7: Verification

1. Run the test suite for the touched code.

   ```bash
   xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```

   *Success signal: M4P4 production and test changes compile and pass, or the exact environment blocker is reported as `unverified`.*

2. Run a focused security scan because the change handles untrusted remote content and local indexing.

   ```bash
   snyk code test --path="$PWD"
   ```

   *Success signal: no new high-signal security findings are introduced, or exact findings are reported with scope.*

3. Manually confirm that only approved imported content reaches the searchable corpus.
   *Success signal: pending sources are persisted but absent from search and Ask, while approved sources become searchable offline after commit.*

### Phase 8: Boundary And Quality Review

1. Verify that M4P4 still does not bypass the local-first assistant boundary.
   *Success signal: Ask answers from imported content only after local persistence and indexing, never from the live fetch response.*

2. Verify that no new UI or networking scope creep slipped in.
   *Success signal: there is no refresh scheduler, no background retry worker, no live-web answer path, and no review-approval UI in this phase.*

3. Verify that storage-layer boundaries remain intact.
   *Success signal: `OSA/Networking/ImportPipeline/` uses repository protocols and search-service abstractions only, with no SwiftData APIs leaking upward.*

4. Verify that imported-source citations remain stable local references.
   *Success signal: Ask and search can refer back to persisted `KnowledgeChunk` and parent source metadata even after the device is offline.*

## Completion Report Requirements

When the executor reports completion, the report should include:

1. The concrete files added or changed for normalization, chunking, import orchestration, search extension, retrieval extension, and tests.
2. Whether dedupe behavior is no-op, metadata refresh only, or document-versioning aware.
3. Whether pending Tier 3 imports are persisted only, or whether any approval gate changed from the existing allowlist defaults.
4. The exact verification commands run, with pass or fail or `unverified` status and blockers.
5. Any deliberately deferred items that remain for M4P5 or M4P6.
