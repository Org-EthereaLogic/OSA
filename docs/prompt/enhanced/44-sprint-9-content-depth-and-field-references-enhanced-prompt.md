
Developer: # Sprint 9 Content Depth And Structured Field References Enhanced Prompt

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** This sprint combines a seed-content expansion with a bounded new editorial-content type slice that touches domain models, seed import, persistence, search indexing, and Library browsing while preserving offline-first behavior, grounded retrieval, and safety-review rules.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 9 must deepen the offline corpus and add structured reference types for climate, first aid, scenario, seasonal, infographic, and lookalike content. |
| `AGENTS.md` | Use Plan -> Act -> Verify -> Report, keep offline-first behavior intact, preserve folder boundaries, and mark blocked verification as unverified. |
| `DIRECTIVES.md` | Keep the assistant grounded, keep editorial content separate from user state, require evidence-backed verification, and run security review for substantive first-party code changes. |
| `.github/instructions/codacy.instructions.md` | Repository owner is `Org-EthereaLogic/OSA`; Codacy analysis is expected after edits when the MCP tooling is available. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Library already supports scenario browse chips and tag-driven search filters, so Sprint 9 should extend those mechanisms rather than invent a parallel browse model. |
| `docs/sdlc/06-data-model-local-storage.md` | Seed content is bundled, imported locally, indexed locally, and represented through domain models plus SwiftData-backed persistence. |
| `docs/sdlc/09-content-model-editorial-guidelines.md` | Sensitive content must remain concise, static, reviewed, and citation-friendly; consistent taxonomy and safety metadata are required. |
| `OSA/Domain/Content/Models/SeedContentModels.swift` | Seed packs currently support handbook chapters, quick cards, and checklist templates only. |
| `OSA/Persistence/SeedImport/SeedContentLoader.swift` | Adding a new first-class editorial type requires manifest, loader, record-count, and cross-reference updates. |
| `OSA/Features/Library/LibraryScreen.swift` and `OSA/Features/Library/SearchResultsView.swift` | Scenario and season tags already drive browse and filter behavior; new editorial types should surface through this existing Library/search flow. |
| `OSATests/SeedContentRepositoryTests.swift` | Seed content changes already have focused loader/import regression tests and should be extended instead of relying on manual validation only. |

## Classification Summary

- Core intent: expand the bundled preparedness corpus and add structured, searchable local reference content that improves offline utility without widening the app beyond documented safety boundaries.
- In scope: climate-specific handbook depth, structured field-reference content, expanded first-aid reference coverage, infographic-style content, seasonal tagging, scenario-based browse/search extensions, lookalike comparison content, seed-manifest updates, focused model/import/search/UI tests, and any minimal Library/Quick Cards UI needed to browse the new content.
- Out of scope: live-web import changes, assistant policy changes, general-chat behavior, backend or sync work, new top-level navigation destinations, speculative editorial tooling, or broad redesign outside the affected Library and Quick Cards surfaces.

## Mission Statement

Implement Sprint 9 by extending OSA's local seed-content system with deeper climate-aware preparedness content and a bounded first-class structured reference model so users can browse, search, and cite field-reference, infographic, seasonal, and scenario-linked guidance entirely offline.

## Technical Context

OSA already has a clean editorial-content seam:

- domain models and repository contracts live under `OSA/Domain/Content/`
- bundled seed import lives under `OSA/Persistence/SeedImport/`
- persistence implementations live under `OSA/Persistence/SwiftData/`
- search indexing lives under `OSA/Persistence/SearchIndex/`
- browse and discovery live under `OSA/Features/Library/` and `OSA/Features/QuickCards/`

The current seed bundle supports handbook chapters, quick cards, and checklist templates. Sprint 9 should not bypass that architecture with ad hoc JSON parsing or feature-owned storage. Instead, it should add the smallest new editorial types needed for the requested capability while reusing the existing tag-driven browse/search model.

The preferred implementation is:

1. Keep climate-specific survival depth inside handbook chapters and sections.
2. Introduce a first-class `FieldReferenceEntry` type for structured reference categories such as first aid, weather exposure, water treatment, signaling, and lookalike comparisons.
3. Introduce a first-class `InfographicCard` type only if the requested infographic behavior cannot be represented cleanly as a quick card with existing fields. If the current quick-card surface can deliver the required infographic-style content through layout metadata, keep infographic content in the quick-card model and avoid a second new repository.
4. Reuse existing `scenario:*`, `season:*`, and `region:*` tags for browse and filter behavior rather than creating a new scenario taxonomy.

**Rationale:** this keeps the change aligned with the current content architecture, avoids premature abstraction, and still gives the app a structured editorial surface beyond handbook chapters and quick cards.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Climate coverage | Core handbook content exists, but climate-specific readiness depth is limited. | Handbook seed content includes climate- and season-specific chapters or sections for cold, heat, smoke, flood, storm, and related household scenarios. |
| Structured references | No first-class local field-reference content type exists. | Structured local references exist for categories such as first aid, weather exposure, signaling, and lookalike comparisons. |
| First-aid reference | First-aid guidance exists, but reference depth is limited and mixed into broader handbook/checklist content. | First-aid content includes a deeper, static, reviewed reference structure that remains concise and non-diagnostic. |
| Infographic-style content | Quick cards exist, but there is no explicit implementation plan for infographic-style offline cards. | Infographic-style content is represented through the smallest viable editorial model and is searchable, browsable, and stress-friendly. |
| Seasonal and scenario browse | Scenario and season tags already exist in some content, but coverage is uneven and not extended to new content types. | New and existing content types share scenario and season tags that drive Library browse and search filtering consistently. |
| Search and Library discovery | Search kinds and Library results do not account for field references or any new editorial type. | Search indexing, Library filtering, and detail routing include the new content type without creating a new top-level destination. |

## Pre-Flight Checks

1. Verify the existing content, import, and browse seams before editing.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Domain/Content/Models/SeedContentModels.swift && test -f OSA/Persistence/SeedImport/SeedContentLoader.swift && test -f OSA/Features/Library/LibraryScreen.swift && echo "seed-content seams present"
   ```

   *Success: the command prints `seed-content seams present`.*

2. Verify the current seed bundle files that Sprint 9 will extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && ls OSA/Resources/SeedContent
   ```

   *Success: the listing includes `SeedManifest.json`, `handbook-foundations-v1.json`, `quick-cards-core-v1.json`, and `checklist-templates-core-v1.json`.*

3. Verify the current scenario/season browse pattern that Sprint 9 should reuse.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "scenario:|season:" OSA/Resources/SeedContent OSA/Features/Library
   ```

   *Success: matches show existing scenario and season tags plus Library filtering logic.*

4. Confirm the focused tests that already guard seed import behavior.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "SeedContentLoader|SeedContentImporter|contentHashMismatch" OSATests/SeedContentRepositoryTests.swift OSATests/SeedContentMigrationTests.swift
   ```

   *Success: matches identify the tests that must be extended rather than bypassed.*

## Phased Instructions

### Phase 1: Finalize The Smallest Coherent Sprint 9 Design

1. Freeze the implementation around the existing content boundary.

   Use `OSA/Domain/Content/`, `OSA/Persistence/SeedImport/`, `OSA/Persistence/SwiftData/`, `OSA/Persistence/SearchIndex/`, `OSA/Features/Library/`, and `OSA/Features/QuickCards/` as the only architecture surfaces for this sprint.

   *Success: no feature-layer storage logic, networking logic, or assistant-policy changes are required by the design.*

2. Define the new editorial types before editing any persistence or UI code.

   Preferred outcome:
   - `FieldReferenceEntry` becomes a first-class local editorial type with explicit category, summary, structured body content, related handbook section IDs, tags, review metadata, and safety level.
   - `InfographicCard` becomes a first-class type only if a `QuickCard` layout/version extension cannot satisfy the requested infographic behavior without distortion.

   *Success: the implementer can name the exact new model types, or can justify keeping infographic content inside `QuickCard` with no ambiguity.*

3. Define the editorial categories Sprint 9 will ship.

   Minimum categories to cover:
   - climate-specific survival chapters or chapter sections
   - structured field references for first aid and general field reference categories
   - infographic-style cards
   - seasonal tags
   - scenario-linked browse/search coverage
   - lookalike comparison content

   *Success: the sprint scope names concrete categories and does not rely on placeholders like "misc reference" or "future content".*

### Phase 2: Extend Domain Models And Repository Contracts

1. Add the new domain model files under `OSA/Domain/Content/Models/`.

   Create the smallest set of new value types needed for Sprint 9, such as:
   - `FieldReferenceCategory`
   - `FieldReferenceEntry`
   - `FieldReferenceSafetyLevel` if the existing handbook safety enum is not sufficient
   - `InfographicCard` only if a new type is justified

   Reuse the current style from `HandbookModels.swift` and `QuickCard.swift`: immutable structs, `Identifiable`, `Equatable`, and `Sendable`.

   *Success: new editorial types compile cleanly and follow the same domain-model conventions as the existing content types.*

2. Extend `OSA/Domain/Content/Repositories/ContentRepositories.swift` with new repository protocols or methods.

   Add a bounded repository seam such as `FieldReferenceRepository` and, if needed, `InfographicCardRepository`. Do not overload unrelated repositories with weakly typed generic methods.

   *Success: the new content types are available through explicit repository contracts without leaking persistence details into features.*

3. Extend `OSA/Domain/Content/Models/SeedContentModels.swift` to represent the new pack kinds.

   Update:
   - `SeedContentPackKind`
   - `SeedContentBundle`
   - `SeedImportOutcome` if counts for the new type need to be reported

   *Success: the seed bundle can represent all Sprint 9 editorial content types without using side channels or untyped dictionaries.*

### Phase 3: Extend Seed Import, Persistence, And Indexing

1. Add or update SwiftData models in `OSA/Persistence/SwiftData/Models/` for the new editorial types.

   Follow the current editorial-content pattern used by `PersistedHandbookChapter`, `PersistedHandbookSection`, and `PersistedQuickCard`. Keep editorial content separate from mutable user data.

   *Success: the new editorial entities are represented as dedicated SwiftData records with stable IDs and mapping helpers.*

2. Extend `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift` to read, write, update, and prune the new seed-backed content.

   The repository must preserve the current seed-upsert semantics: deterministic updates, deletion of stale seed records, and no accidental collision with user-authored data.

   *Success: seed import can upsert the new editorial types alongside chapters, quick cards, and checklist templates.*

3. Extend `OSA/Persistence/SeedImport/SeedContentLoader.swift` for the new pack kinds and cross-reference validation rules.

   Add decode paths for the new pack files, record-count validation, content-hash validation, and any required cross-reference checks such as:
   - field references linking to existing handbook sections
   - infographic cards linking to existing sections or quick cards
   - lookalike entries referencing the correct paired records

   *Success: malformed pack files fail during seed loading rather than surfacing as runtime UI errors.*

4. Add the new bundled seed pack files under `OSA/Resources/SeedContent/` and update `OSA/Resources/SeedContent/SeedManifest.json`.

   Expected additions are likely to include:

- `field-references-core-v1.json`
- `infographic-cards-core-v1.json` only if infographic content is not kept in quick cards
- updated `handbook-foundations-v1.json` or new climate-focused handbook pack files if chapter volume warrants separation

   Each record must include stable IDs, tags, versioning, and review dates. Use `scenario:*`, `season:*`, and `region:*` tags consistently.

   *Success: manifest record counts, versions, and content hashes match the actual files and the loader decodes the full bundle without drift.*

1. Extend `OSA/Domain/Common/Models/SearchResult.swift`, `OSA/Persistence/SearchIndex/LocalSearchService.swift`, and the search index wiring for the new content types.

   Add new `SearchResultKind` cases only for truly first-class content types. Index title, summary/body text, and tags for the new content so Library search and Ask retrieval can discover the content locally.

   *Success: local search returns the new content type with tags and snippets, and no existing kind regresses.*

### Phase 4: Add The Sprint 9 Editorial Corpus

1. Expand handbook depth for climate- and season-specific readiness.

   Add handbook chapters or major sections for the highest-value climate scenarios relevant to the current product posture, such as:

- extreme heat / heat wave household readiness
- winter storm / cold outage household readiness
- smoke / wildfire air-quality readiness
- heavy rain / flood readiness
- seasonal rotation and household adaptation guidance

   Keep these inside the handbook model rather than inventing a separate climate-content type.

   *Success: handbook coverage materially improves for seasonal and climate-driven household disruptions while remaining concise and static.*

1. Add structured field-reference content with deeper first-aid and comparison coverage.

   Minimum content expectations:

- expanded first-aid reference entries with reviewed, static, non-diagnostic guidance
- field references grouped by category rather than as one flat list
- lookalike comparisons where mistaken identification would plausibly matter, written conservatively and without speculative survival claims

   *Success: users can browse structured references by category and can distinguish comparison-oriented content from narrative handbook content.*

1. Add infographic-style content in the smallest viable form.

   If `QuickCard` can support infographic presentation through `largeTypeLayoutVersion` or a similarly bounded metadata extension, keep infographic cards there. If not, implement the explicit `InfographicCard` type and associated browse/search handling.

   *Success: infographic content is usable offline, visually distinct from prose-heavy handbook content, and does not force a broad UI rewrite.*

2. Apply seasonal, scenario, and region tagging consistently across all new content.

   Reuse the existing prefixes already visible in the corpus and Library/search code:

- `scenario:*`
- `season:*`
- `region:*`

   *Success: the new content participates in existing browse chips and search filters without custom one-off logic.*

### Phase 5: Extend Library And Quick-Cards Discovery Without New Navigation Surfaces

1. Update `OSA/Features/Library/LibraryScreen.swift` and `OSA/Features/Library/SearchResultsView.swift` to surface the new content types through the current Library/search flow.

   Required behaviors:

- the new content types appear in search results and kind filters when first-class
- scenario-based browse and search surfaces can discover the new content through shared tags
- field-reference detail routing is explicit and stable
- no new top-level tab or major navigation restructure is introduced

   *Success: Library remains the primary browse/search surface for Sprint 9 additions and the navigation shell does not change.*

1. Add the smallest required detail views or route views under `OSA/Features/Library/` or `OSA/Features/QuickCards/`.

   Keep the rendering simple, stress-readable, and category-aware. Do not build a generalized CMS UI or content editor.

   *Success: every newly indexed content type has a usable destination from search results or related-content links.*

### Phase 6: Add Focused Tests And Execute Verification

1. Extend `OSATests/SeedContentRepositoryTests.swift` and `OSATests/SeedContentMigrationTests.swift` for the new pack kinds, hashes, counts, and cross-reference checks.

   Cover at minimum:

- manifest decoding for the new pack kind
- loader failure for missing or mismatched counts/hashes
- seed import upsert behavior for the new editorial types
- cross-reference validation failures

   *Success: the seed-content test suite proves that invalid Sprint 9 content cannot silently ship.*

1. Add focused search and browse tests for the new content kinds.

   Likely files to extend or add include:

- `OSATests/LocalRetrievalServiceTests.swift`
- `OSATests/OnscreenContentManagerTests.swift` if Library visibility or app-intent exposure changes
- new focused tests for search-index wiring if no current coverage exists for the new kind

   *Success: the new content kinds are discoverable by local search and do not regress existing search behavior.*

1. Run the narrowest relevant test command first.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/SeedContentRepositoryTests -only-testing:OSATests/SeedContentMigrationTests
   ```

   *Success: the focused seed-content tests pass or produce a concrete failure that maps directly to the edited slice.*

2. Run the broader build/test verification needed for the touched surfaces.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```

   *Success: the app builds and the relevant test suite passes, or any environment blocker is reported verbatim as unverified.*

3. Run the required security scan if Sprint 9 adds or changes first-party Swift code.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
   ```

   *Success: the scan completes, or the exact tooling blocker is reported if `snyk` is unavailable.*

## Guardrails

- Do not move seed content into feature-layer files or ad hoc JSON loaders.
- Do not add networking, sync, or remote editorial behavior.
- Do not widen medical, foraging, improvised heating, hazardous utility, or weapon-adjacent scope beyond the documented safety rules.
- Do not create a generalized content-management abstraction, plugin system, or editor UI.
- Do not add a new top-level tab or major navigation model change.
- Do not introduce new dependencies to solve a seed-content and local-model problem unless a direct repository constraint makes that unavoidable.
- Do not invent sources, review dates, trust levels, or safety approvals.
- Keep the first implementation bounded: use handbook chapters for climate depth, reuse tag prefixes for browse behavior, and add only the minimum new first-class content type required.

## Verification Checklist

- [ ] Prompt type is `Feature` and complexity is marked `Complex` with justification.
- [ ] Sprint 9 uses the existing content architecture instead of adding parallel storage or navigation systems.
- [ ] New editorial types are represented in `OSA/Domain/Content/` and seed content models.
- [ ] `SeedManifest.json` and all new pack files agree on kinds, counts, versions, and hashes.
- [ ] Climate-specific handbook depth is added.
- [ ] Structured field-reference content is added.
- [ ] First-aid reference depth is added with conservative safety posture.
- [ ] Seasonal, scenario, and region tags are applied consistently across new content.
- [ ] Library search and browse can discover the new content locally.
- [ ] Focused seed-content tests are executed.
- [ ] Build and broader tests are executed or reported as unverified with the exact blocker.
- [ ] `snyk code test --path="$PWD"` is executed for the first-party code change, or reported as unverified with the exact blocker.

## Verification Recovery and Error Handling

| Error Condition | Resolution |
| --- | --- |
| New content requirements seem to demand multiple new editorial types | Start with `FieldReferenceEntry`; add `InfographicCard` only if the requested infographic behavior cannot be expressed cleanly through `QuickCard` metadata. In the final report, state which path was chosen and give a concise reason to avoid unnecessary type proliferation. |
| Manifest decodes but cross-reference routing fails at runtime | Add loader-level validation for related IDs and fail import before UI rendering. |
| Search results return the new kind but no destination view exists | Add a focused route or detail view before considering the content type complete. |
| Seed import deletes user data or unrelated records | Stop and move the logic back into seed-only repository paths; editorial seed updates must not touch user-authored data. |
| First-aid or lookalike content drifts into speculative or diagnostic advice | Tighten the copy to reviewed static reference language or cut the entry from Sprint 9. |
| Build or tests fail because the active developer directory points to Command Line Tools only | Report the exact `xcodebuild` failure, keep build/test evidence unverified, and continue with bounded implementation where possible rather than silently skipping verification or claiming completion. |
| `snyk` is unavailable locally | Report the exact missing-tool failure, keep the security claim unverified, and continue with bounded implementation where possible rather than silently skipping verification or claiming completion. |
| Any other required command, test, or tool cannot run | Continue with bounded implementation when possible, and mark the affected claim `unverified` with the exact command attempted and the exact blocker encountered. |

## Out Of Scope

- Online knowledge discovery, import, refresh, or trusted-source policy changes.
- Ask prompt shaping, retrieval ranking, or assistant-scope changes unrelated to indexing the new local content type.
- Editorial tooling, seed-content authoring GUIs, or live content updates.
- New top-level app destinations or broad navigation redesign.
- Generalized comparison engines, identification assistants, or unsafe diagnostic workflows.
- Any change that treats editorial content as mutable user state.

## Alternative Solutions

1. **Preferred solution:** add `FieldReferenceEntry` as the only new first-class editorial type and keep infographic content inside `QuickCard` through bounded layout metadata. Pros: smallest surface-area increase, minimal repository/search churn, best fit with current architecture. Cons: infographic behavior must fit within the current quick-card detail surface.
2. **Fallback solution:** add both `FieldReferenceEntry` and `InfographicCard` as first-class editorial types. Pros: clearer semantic separation and future-proofing if infographic content diverges quickly. Cons: larger search, persistence, and routing footprint.
3. **Rejected solution:** encode all Sprint 9 additions as handbook sections and tags only. Pros: least code change. Cons: fails the requirement to introduce structured reference types and weakens browse/search semantics for field references and infographic content.

## Report Format

When Sprint 9 is complete, report using this exact structure:

1. `Scope delivered:` handbook depth, field references, infographic handling choice, scenario/season tagging, and Library/search updates.
2. `Files changed:` grouped by Domain, Persistence, Features, Resources, and Tests.
3. `Implementation choice:` whether infographic content remained in `QuickCard` or became a separate type, with a one-sentence rationale.
4. `Seed packs added or updated:` filenames, record counts, and manifest version/hash updates.
5. `Verification:` exact commands run and pass/fail results.
6. `Security:` `snyk` result or exact blocker.

7. `Deferred work:` any deliberately postponed structured-reference or browse enhancements.
