# Milestone 6 Phase 2 App Entities And Spotlight Indexing Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** M6P2 crosses App Intents, local search, repository hydration, privacy-sensitive Spotlight exposure, and focused verification for four domain entity types. The implementation should stay narrow, but it still spans multiple files and requires care to avoid widening scope into navigation intents, AssistantSchema, or new retrieval infrastructure.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | Milestones 1 through 5 are complete, M6P1 is complete, M6P2 is the recommended next step, and M6P4 depends on M6P2. |
| User brief | The remaining M6 work is phased; M6P2 should implement App Entities plus Spotlight indexing for handbook sections, quick cards, checklist templates, and inventory items. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, preserve offline-first and local-first behavior, keep assistant behavior grounded and cited, and report blocked verification as `unverified`. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M6P2 is explicitly defined as `HandbookSectionEntity`, `QuickCardEntity`, `ChecklistEntity`, and `InventoryItemEntity` with `EntityStringQuery`, backed by the existing FTS5 search substrate and exposed through Spotlight via `IndexedEntity`. |
| `docs/sdlc/05-technical-architecture.md` | OSA already has clean `App`, `Domain`, `Persistence`, `Retrieval`, and `Assistant` boundaries, plus a sidecar FTS5 index accessed through `SearchService`. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Siri and Apple Intelligence surfaces must stay bounded to approved local content and app data. No uncited or live-web answers are allowed. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Inventory, notes, and other personal data remain device-local. Spotlight discoverability must not silently widen private-data exposure or trigger networking. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | New assistant-adjacent surfaces require focused tests plus explicit verification evidence; `snyk code test --path="$PWD"` is required when first-party code changes and `snyk` is available. |
| `docs/adr/ADR-0002-grounded-assistant-only.md` | OSA is a bounded assistant, not a general chatbot. Any new Apple Intelligence surface must resolve to approved local records and preserve trust boundaries. |
| `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md` | The app already targets iOS 18. M6P2 should use the existing platform baseline and not introduce deployment-target or dependency changes. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` | The app already exposes `handbookRepository`, `quickCardRepository`, `checklistRepository`, `inventoryRepository`, and `searchService`; M6P2 should reuse that graph rather than constructing a parallel lookup stack. |
| `OSA/App/Bootstrap/AppModelContainer.swift` | `SharedRuntime` already exists for App Intents and other non-SwiftUI entry points, so M6P2 can build on the M6P1 bootstrap seam instead of adding a new one. |
| `OSA/Domain/Common/Repositories/SearchRepositories.swift` and `OSA/Persistence/SearchIndex/LocalSearchService.swift` | The existing search layer already supports text search across the required kinds and can be used as the candidate-result substrate before repository hydration. |
| `OSA/Domain/Common/Models/SearchResult.swift` | `SearchResultKind` already distinguishes `handbookSection`, `quickCard`, `inventoryItem`, and `checklistTemplate`, which maps cleanly onto the M6P2 entity set. |
| `OSA/Domain/Content/Repositories/ContentRepositories.swift`, `OSA/Domain/Checklists/Repositories/ChecklistRepositories.swift`, `OSA/Domain/Inventory/Repositories/InventoryRepositories.swift` | The repositories already expose the id-based lookup APIs required to hydrate search hits into real domain objects. |
| `OSA/App/Intents/AskLanternIntent.swift`, `OSA/App/Intents/LanternAppShortcutsProvider.swift`, `OSA/Assistant/Orchestration/AskLanternIntentExecutor.swift` | M6P1 is complete and provides the App Intents foundation. M6P2 must add entities and indexing on top of it without rewriting the existing Siri entry path. |
| `docs/prompt/enhanced/33-m6p1-app-intents-foundation-enhanced-prompt.md` | M6P1 intentionally left `AppEntity`, Spotlight, navigation intents, and AssistantSchema work out of scope. M6P2 should pick up exactly that deferred slice and no more. |

## Classification Summary

- Core intent: implement the M6P2 entity layer so Siri and system search can resolve real OSA domain objects from natural-language references using the existing local search index and repository graph.
- In scope: four `AppEntity` types, four `EntityStringQuery` implementations, a thin shared search-and-hydration seam, `IndexedEntity` Spotlight exposure, focused tests, and minimal documentation updates needed to reflect the completed phase.
- Out of scope: `AssistantSchema`, onscreen content, navigation intents, FM-powered inventory completion, knowledge-base discovery, live-web behavior, notes entities, imported-knowledge entities, and any new dependency or persistence architecture.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- New source files placed under `OSA/` and new test files placed under `OSATests/` are already picked up by the current `project.yml` source globs, so `xcodegen generate` is not required unless the implementation changes target structure.
- M6P2 should resolve checklist templates, not active checklist runs, because the current search kind is `checklistTemplate` and the roadmap names `ChecklistEntity` generically rather than introducing a run entity.
- Inventory entities may be system-searchable, but archived items and private note text should not be exposed through Spotlight-facing representations in this phase.
- Simulator or headless environments may not be sufficient to prove end-to-end Spotlight behavior. If that happens, report the exact blocker and keep the affected claim `unverified`.
- If full Xcode is unavailable and `xcode-select -p` points at Command Line Tools, build and test verification must be reported as `unverified`.

## Mission Statement

Implement M6P2 by adding App Intents entity resolution and Spotlight indexing for handbook sections, quick cards, checklist templates, and inventory items using the existing local FTS5 search and repository graph, while preserving OSA's offline-first, grounded, and privacy-bounded behavior.

## Technical Context

OSA already has the core substrate needed for M6P2. The app stores editorial and user data locally, indexes the searchable subset through `LocalSearchService`, and exposes domain repositories plus the search service through `AppDependencies` and `SharedRuntime`. M6P1 already proved that App Intents can safely reuse the existing runtime seam. M6P2 should therefore add only the missing entity layer, not a second search system or a second dependency graph.

The key technical problem is hydration. `SearchService.search(query:scopes:limit:)` returns ranked `SearchResult` values containing ids, kinds, titles, and snippets. `AppEntity` queries need richer, type-safe objects with stable identity and user-facing display metadata. The right design is a thin App Intents-facing resolver that uses `SearchService` for candidate ranking and then hydrates each hit through the existing domain repositories. That preserves the current BM25 ranking behavior while keeping SwiftData and SQLite details out of entity definitions.

Three product constraints matter here:

1. M6P2 must remain local-first and offline-first. Entity lookup should work against the current on-device corpus with no networking.
2. M6P2 must preserve privacy boundaries. Notes and imported knowledge are not part of this phase, and inventory Spotlight exposure must not leak note text or archived items.
3. M6P2 must stay narrow enough to unblock M6P4 without absorbing it. Do not add navigation intents, AssistantSchema, onscreen content, or UI redesign while building the entity layer.

The preferred implementation shape is:

- one shared resolver or helper that maps query text plus allowed `SearchResultKind` values to hydrated domain objects
- four focused entity types under `OSA/App/Intents/`
- four focused `EntityStringQuery` types, one per entity kind
- `IndexedEntity` conformance on the four entity types so Spotlight can expose them without introducing a parallel Core Spotlight subsystem unless the SDK forces that fallback
- focused tests proving query resolution, id lookup, stale-hit handling, and privacy-sensitive inventory behavior

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| App Intents entity resolution | M6P1 can answer a free-text question, but Siri cannot resolve named OSA content objects such as a specific quick card or handbook section. | Siri and Shortcuts can resolve four real OSA entity types from natural-language references. |
| Search-to-entity bridge | `SearchService` returns lightweight `SearchResult` values only. No entity query layer hydrates those ids back into domain objects. | A small App Intents-facing resolver uses `SearchService` ranking and repository hydration to produce real entity results. |
| Spotlight discoverability | There is no `AppEntity`, `EntityStringQuery`, or `IndexedEntity` implementation in the codebase today. | The four M6P2 entity types are indexed and discoverable through the system's App Intents entity surface. |
| Checklist surface | The app has checklist templates and runs, but the search index only knows `checklistTemplate`. | `ChecklistEntity` resolves seeded or user-visible checklist templates only, not active runs. |
| Inventory privacy | Inventory items are locally searchable, but no Spotlight representation exists and privacy rules for entity exposure are not encoded. | Inventory entities exclude archived items and do not expose free-form notes in display or Spotlight-facing metadata. |
| Milestone dependency | M6P4 depends on M6P2 but cannot reuse an entity layer that does not exist yet. | M6P2 provides the entity substrate needed for later navigation and AssistantSchema work without implementing those later phases now. |

## Pre-Flight Checks

1. Verify the repository root and the main M6P2 seams.

```bash
pwd
test -f OSA/App/Intents/AskLanternIntent.swift \
  && test -f OSA/App/Bootstrap/AppModelContainer.swift \
  && test -f OSA/App/Bootstrap/Dependencies/AppDependencies.swift \
  && test -f OSA/Domain/Common/Repositories/SearchRepositories.swift \
  && test -f OSA/Persistence/SearchIndex/LocalSearchService.swift \
  && test -f OSA/Domain/Content/Repositories/ContentRepositories.swift \
  && test -f OSA/Domain/Checklists/Repositories/ChecklistRepositories.swift \
  && test -f OSA/Domain/Inventory/Repositories/InventoryRepositories.swift \
  && echo "m6p2 surfaces present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: m6p2 surfaces present
```

*Success signal: the app-intents bootstrap seam, repositories, and search substrate M6P2 must reuse are all present before implementation begins.*

1. Confirm the current codebase still has no M6P2 implementation.

```bash
rg -n "AppEntity|EntityStringQuery|IndexedEntity|CoreSpotlight|CSSearchableIndex" OSA OSATests
# Expected: no matches
```

*Success signal: M6P2 is starting from a clean entity surface and not overlapping a hidden partial implementation.*

1. Confirm the roadmap contract for M6P2.

```bash
rg -n "M6P2|App Entities and entity queries|IndexedEntity" docs/sdlc/03-mvp-scope-roadmap.md
# Expected: the roadmap line for M6P2 appears and names the four entity types plus Spotlight exposure
```

*Success signal: the implementation target is anchored to the current milestone contract, not guessed from memory.*

1. Confirm the existing search and repository seams that should back entity queries.

```bash
rg -n "enum SearchResultKind|protocol SearchService|listChapters|section\(id:|listQuickCards|quickCard\(id:|listTemplates|template\(id:|listItems\(includeArchived:|item\(id:" \
  OSA/Domain OSA/Persistence
# Expected: matches for SearchResultKind, SearchService, and the id-based repository methods needed for hydration
```

*Success signal: entity queries can be built on top of existing repositories and search primitives without adding new persistence interfaces.*

1. Confirm whether build and test verification are available.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success signal: full verification is possible, or the exact blocker is known before implementation starts.*

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the current App Intents, bootstrap, search, repository, and model files before editing.

   Required files:

   - `OSA/App/Intents/AskLanternIntent.swift`
   - `OSA/App/Intents/LanternAppShortcutsProvider.swift`
   - `OSA/App/Bootstrap/AppModelContainer.swift`
   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/Domain/Common/Models/SearchResult.swift`
   - `OSA/Domain/Common/Repositories/SearchRepositories.swift`
   - `OSA/Persistence/SearchIndex/LocalSearchService.swift`
   - `OSA/Domain/Content/Models/HandbookModels.swift`
   - `OSA/Domain/Content/Models/QuickCard.swift`
   - `OSA/Domain/Content/Repositories/ContentRepositories.swift`
   - `OSA/Domain/Checklists/Models/ChecklistTemplate.swift`
   - `OSA/Domain/Checklists/Repositories/ChecklistRepositories.swift`
   - `OSA/Domain/Inventory/Models/InventoryItem.swift`
   - `OSA/Domain/Inventory/Repositories/InventoryRepositories.swift`
   - `OSATests/AskLanternIntentExecutorTests.swift`
   - `OSATests/SearchIndexStoreTests.swift`
   - `docs/sdlc/03-mvp-scope-roadmap.md`
   - `docs/sdlc/05-technical-architecture.md`
   - `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`
   - `docs/sdlc/10-security-privacy-and-safety.md`
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`

   *Success signal: the work is grounded in the current M6P1 runtime seam, search layer, and privacy rules instead of inferred from milestone names alone.*

2. Freeze the M6P2 contract before writing code.

   This phase includes only:

   - `HandbookSectionEntity`
   - `QuickCardEntity`
   - `ChecklistEntity`
   - `InventoryItemEntity`
   - string-based entity queries
   - Spotlight exposure through `IndexedEntity`
   - focused tests and docs updates tied directly to M6P2 completion

   This phase excludes:

   - `AssistantSchema`
   - onscreen content
   - navigation intents such as `OpenQuickCardIntent` or `OpenHandbookSectionIntent`
   - FM-powered inventory completion
   - web discovery or import work
   - notes entities or imported-knowledge entities

   *Success signal: the implementation remains the narrow entity-and-indexing slice that unblocks M6P4 without absorbing it.*

3. Lock the domain mapping decisions explicitly.

   Required mappings:

   - `HandbookSectionEntity` wraps `HandbookSection` plus enough chapter metadata to present an unambiguous title.
   - `QuickCardEntity` wraps `QuickCard`.
   - `ChecklistEntity` wraps `ChecklistTemplate` or `ChecklistTemplateSummary`, not `ChecklistRun`.
   - `InventoryItemEntity` wraps non-archived `InventoryItem` records only.

   *Success signal: each entity type has one clear backing domain model, and checklist runs are excluded from this phase by design.*

4. Decide the query-and-hydration strategy before implementation.

   Preferred approach:

   - use `SearchService.search(query:scopes:limit:)` as the candidate ranking layer
   - map each `SearchResult` back to the appropriate repository by id and kind
   - preserve result ordering from the search layer
   - drop stale search hits that fail hydration instead of crashing

   *Success signal: App Intents entity lookup reuses the existing FTS5 ranking and repository graph instead of bypassing boundaries.*

### Phase 2: Implement The Entity And Query Layer

1. Add a thin App Intents-facing resolver or helper for shared search-and-hydration logic.

   Preferred location:

   - `OSA/App/Intents/Entities/` as one shared helper file, or
   - `OSA/Assistant/Orchestration/` if that folder better matches the existing runtime seams

   Required responsibilities:

   - accept query text plus allowed `SearchResultKind` values
   - call `SearchService.search(query:scopes:limit:)`
   - hydrate hits through the correct repository
   - deduplicate ids while preserving ranking order
   - return empty results on blank query input
   - ignore stale hits that no longer exist in the repository layer

   *Success signal: the entity query types can stay small and avoid duplicating search, ranking, or hydration code four times.*

2. Add one focused AppEntity file per domain type.

   Preferred files:

   - `OSA/App/Intents/Entities/HandbookSectionEntity.swift`
   - `OSA/App/Intents/Entities/QuickCardEntity.swift`
   - `OSA/App/Intents/Entities/ChecklistEntity.swift`
   - `OSA/App/Intents/Entities/InventoryItemEntity.swift`

   Required behavior for each entity type:

   - conform to `AppEntity`
   - use stable `UUID`-based identity from the domain model
   - expose a concise `DisplayRepresentation`
   - set `defaultQuery` to the matching query type
   - conform to `IndexedEntity`

   *Success signal: each M6P2 entity exists as a first-class App Intents type with stable identity and a clear display representation.*

3. Implement one focused query type per entity kind.

   Required behavior for each query type:

   - conform to `EntityStringQuery`
   - resolve exact ids through the matching repository's id-based method
   - use the shared search-and-hydration helper for natural-language matches
   - provide a small `suggestedEntities` list from the matching repository
   - constrain search scopes to the single relevant `SearchResultKind`

   *Success signal: Siri and Shortcuts can resolve names such as `water purification`, `boil water`, or a specific inventory item into typed OSA entities.*

4. Encode the entity-specific privacy and clarity rules directly in the implementation.

   Required rules:

   - `HandbookSectionEntity` display should include the chapter title or another stable context field so section headings are not ambiguous.
   - `ChecklistEntity` must resolve checklist templates only.
   - `InventoryItemEntity` must exclude archived items from suggestions and query results.
   - `InventoryItemEntity` display and Spotlight-facing metadata must not include free-form `notes` text.

   *Success signal: the entity layer matches the product model and does not create accidental leakage or ambiguous system-search results.*

5. Reuse the existing runtime seam instead of adding a second dependency graph.

   Required rule:

   - if the entity query types need app services, resolve them through `SharedRuntime.dependencies`
   - do not instantiate new SwiftData repositories or a second `LocalSearchService` from inside the query files unless the current seam proves insufficient

   *Success signal: M6P2 stays aligned with the M6P1 bootstrapping model and does not split the app into competing App Intents runtimes.*

6. Update canonical docs if and only if the implementation reaches the milestone contract.

   Minimum docs to update on successful completion:

   - `docs/sdlc/03-mvp-scope-roadmap.md` to mark M6P2 complete and summarize what landed
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` to record the new entity-query and Spotlight-related tests

   *Success signal: code reality and the living SDLC docs agree about M6P2 status and verification scope.*

### Phase 3: Verification

1. Add focused unit tests for entity queries and Spotlight-facing behavior.

   Preferred files:

   - `OSATests/AppEntityQueryTests.swift`
   - `OSATests/AppEntitySpotlightTests.swift`

   Minimum behaviors to test:

   - quick-card query resolves a known quick card from natural-language text
   - handbook query resolves a known section and includes chapter context in display data
   - checklist query resolves templates and does not touch checklist runs
   - inventory query excludes archived items
   - inventory entity display does not include `notes`
   - stale search hits are dropped rather than crashing
   - id-based resolution round-trips each entity type correctly

   *Success signal: the new entity layer is covered by focused tests for ranking, hydration, and privacy-sensitive behavior.*

2. Run the focused entity tests first.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/AppEntityQueryTests \
  -only-testing:OSATests/AppEntitySpotlightTests
# Expected: the targeted M6P2 tests pass with exit code 0
```

*Success signal: the new entity resolution and Spotlight-facing behavior pass in isolation before broader regression checks.*

1. Run the full test suite if full Xcode is available.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: the full suite passes, or any unrelated pre-existing failure is reported separately
```

*Success signal: M6P2 does not regress the existing app, retrieval, or App Intents coverage.*

1. Perform a minimal manual App Intents validation pass if the environment supports it.

   Minimum manual checks:

   - build and launch the app once so the local store and search index exist
   - confirm Shortcuts or Siri can see the app's entity-enabled surface if the simulator or device supports it
   - if Spotlight discoverability cannot be validated on the available environment, capture the exact limitation and mark the claim `unverified`

   *Success signal: there is either direct manual evidence for system discoverability or a precise environment blocker explaining why that evidence could not be collected.*

### Phase 4: Security And Quality

1. Run the required first-party security scan if `snyk` is available.

```bash
snyk code test --path="$PWD"
# Expected: no new high-severity findings, or the exact findings are reported and addressed
```

*Success signal: the new first-party App Intents code has been scanned, or the absence of `snyk` has been reported explicitly as a verification blocker.*

1. Verify the final diff stays within the milestone boundary.

```bash
git status --short
git diff --stat
# Expected: changes are limited to OSA App Intents files, focused tests, and any required SDLC doc updates
```

*Success signal: the implementation stays tightly scoped to M6P2 and does not silently pull later Apple Intelligence phases into the same change.*

## Guardrails

- Do not implement `AssistantSchema`, onscreen content, or navigation intents in this phase.
- Do not add `NoteRecord` or imported-knowledge entities.
- Do not expose archived inventory items or free-form inventory notes through Spotlight-facing metadata.
- Do not bypass repository protocols from feature-layer code or pull SwiftData APIs into `OSA/Features/`.
- Do not add new dependencies, remote services, analytics, or background networking.
- Do not replace the existing FTS5 search substrate or create a second search system.
- Do not modify `project.yml` unless the implementation truly changes target structure.
- Prefer small, explicit files over a large generic abstraction that tries to model every future entity phase at once.
- Treat any unverified Spotlight or Siri system behavior as `unverified`; do not claim success from unit tests alone when manual proof is unavailable.

## Verification Checklist

- [ ] `HandbookSectionEntity`, `QuickCardEntity`, `ChecklistEntity`, and `InventoryItemEntity` exist and conform to `AppEntity`.
- [ ] Each entity has a focused `EntityStringQuery` implementation and stable `UUID` identity.
- [ ] The query layer reuses existing local search plus repository hydration rather than creating a new persistence or search stack.
- [ ] Checklist entity resolution is limited to checklist templates.
- [ ] Inventory entity resolution excludes archived items and does not expose free-form notes in display or Spotlight-facing metadata.
- [ ] Focused M6P2 tests pass.
- [ ] Full test suite passes, or any blocker is reported explicitly.
- [ ] `snyk code test --path="$PWD"` is run, or the blocker is reported explicitly.
- [ ] `docs/sdlc/03-mvp-scope-roadmap.md` and `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` are updated if the milestone is fully completed.
- [ ] No M6P3, M6P4, or M6P5 work is mixed into the change.

## Error Handling

| Error Condition | Resolution |
| --- | --- |
| `SearchService` does not provide enough information to hydrate an entity cleanly | Keep `SearchService` as the ranking substrate and add one thin App Intents-specific adapter over existing repositories. Do not replace the search system. |
| A search hit resolves to an id that no longer exists in the repository | Treat it as a stale index hit, drop it from results, and add or extend a focused regression test. |
| `IndexedEntity` or related App Intents APIs are unavailable or behave differently in the installed SDK | Use the platform-supported equivalent if it stays within M6P2 scope. If Spotlight exposure cannot be implemented or verified on the installed SDK, keep the entity work narrow, document the blocker, and do not drift into manual `CSSearchableIndex` work unless that fallback is explicitly required. |
| Inventory Spotlight exposure appears to leak sensitive free-form text | Remove note-derived metadata immediately, constrain the representation to safe fields, and rerun focused tests. |
| `xcodebuild` fails because the active developer directory points to Command Line Tools | Report the exact command and output, mark build and test claims `unverified`, and avoid making unsupported pass/fail claims. |
| Simulator or CI environment cannot prove end-to-end Spotlight discoverability | Record the exact limitation, keep manual Spotlight validation `unverified`, and separate that from unit-test results. |
| The implementation starts to require navigation or AssistantSchema APIs to feel complete | Stop and keep those concerns deferred to M6P4. M6P2 succeeds with typed entities and Spotlight exposure alone. |

## Out Of Scope

- `AssistantSchema` conformance for `AskLanternIntent`
- onscreen content exposure for handbook or quick-card detail screens
- deep-link navigation intents such as `OpenQuickCardIntent` and `OpenHandbookSectionIntent`
- FM-powered inventory completion or `@Generable` work
- knowledge-base discovery or any web search API integration
- notes entities, imported-knowledge entities, or checklist-run entities
- UI redesign, app-navigation refactors, or search-index architecture changes

## Alternative Solutions

1. Preferred solution: use `SearchService` for ranked candidate search and repositories for hydration. This preserves the current search ranking and respects existing architectural boundaries.
2. Fallback A: if `SearchService` proves too lossy for one entity type, add a thin App Intents resolver that reads from the existing search-index substrate in one isolated file and still hydrates through repositories. Pros: direct access to ranked hits. Cons: tighter coupling to search internals.
3. Fallback B: if Spotlight exposure through `IndexedEntity` is blocked by the installed SDK or environment, land the entity and query layer first, keep Spotlight-specific verification `unverified`, and open a narrow follow-up for the remaining system-discoverability gap. Do not fill the gap by pulling M6P4 navigation work into M6P2.

## Report Format

1. **Scope completed:** confirm whether M6P2 landed in full or which sub-slice remains blocked.
2. **Files changed:** list each added or modified source, test, and doc file.
3. **Entity mapping:** state which domain model backs each of the four App Entities.
4. **Query strategy:** explain how search ranking and repository hydration were combined, including stale-hit handling.
5. **Privacy decisions:** state exactly what inventory and other user data was excluded from Spotlight-facing representations.
6. **Verification evidence:** list every command run and whether it passed, failed, or remained `unverified`.
7. **Blockers:** list environment or SDK blockers separately from code defects.
