# M3 Polish Sprint Enhanced Prompt: Home, Settings, Ask Navigation, And Seed Integrity

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This sprint closes six small but user-visible M3 loose ends that already fit inside the existing codebase. It spans live repository plumbing, persisted UI state, content deep-linking, seed-content density, and manifest integrity, but it does not require new architecture or M4 networking/import work.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow` with the note: `Recommended Next Step: M3 Polish Sprint. Before jumping into M4's networking/import work, there are 6 loose ends that are entirely within the existing codebase — no new architecture needed.`
- User recommendation: start with the M3 polish sprint and address tasks 1-6 in the order that keeps the current codebase shippable.
- Project governance: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Product and architecture docs: `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/04-information-architecture-and-ux-flows.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/09-content-model-editorial-guidelines.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Relevant code surfaces: `OSA/Features/Home/HomeScreen.swift`, `OSA/Features/Settings/SettingsScreen.swift`, `OSA/Features/Ask/AskScreen.swift`, `OSA/Domain/Ask/Repositories/AskRepositories.swift`, `OSA/Domain/Content/Models/HandbookModels.swift`, `OSA/Persistence/SeedImport/SeedContentLoader.swift`, `OSA/Resources/SeedContent/SeedManifest.json`
- Supporting surfaces: the existing repository-backed content and capability plumbing already present in the codebase

## Assumptions

- The repositories for quick cards, checklists, inventory, and notes already exist and can supply live state to the Home screen.
- `DeviceCapabilityDetector` is available to the Settings surface through existing app composition.
- Ask scope can be persisted with app-local storage and passed into retrieval without changing the assistant architecture.
- Ask result actions can navigate to existing content detail surfaces or equivalent content routes.
- The thin seed chapters can be expanded in place without altering the content schema.
- `contentHash` values in `SeedManifest.json` should be derived from the real pack contents, not invented.
- The sprint should remain independent of M4 networking/import work.

## Mission Statement

Complete the M3 polish sprint by replacing remaining placeholder surfaces with live local data, making Ask state and navigation real, and tightening seed-content integrity so the app feels materially usable before M4 begins.

## Technical Context

The current app already has the core data and assistant scaffolding in place, but several surfaces still present as placeholders or hardcoded stubs. The Home screen renders static text for the main sections. Settings shows `Checking...` for model capability even though capability detection exists. Ask uses a non-persistent scope toggle and has incomplete content-navigation affordances. The seed corpus still has thin chapters, and the seed manifest leaves `contentHash` values null even though the importer expects the manifest and pack files to stay aligned.

This sprint should remove those gaps without introducing new architecture. Each item is small enough to land independently, but the implementation should keep the data flow clean: repositories feed UI, settings reflect real capability state, Ask scope persists and influences retrieval, content navigation resolves to existing handbook or quick-card entries, and seed metadata remains consistent with the loaded content.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| Home shows static placeholder text for Quick Cards, Active Checklists, Inventory, and Recent Notes. | Home renders live repository-backed summaries for the four sections. |
| Settings shows `Checking...` for model capability. | Settings reflects the actual capability status reported by the detector. |
| Ask scope uses `isOn: .constant(false)`. | Ask scope persists locally and affects retrieval scope or source selection. |
| Ask suggested actions do not navigate to content. | Ask result actions deep-link into quick cards or handbook sections. |
| Two handbook chapters remain thin at two sections each. | The thin chapters are expanded with denser, more useful content for retrieval evaluation. |
| `SeedManifest.json` leaves all `contentHash` fields null. | Each seed pack includes a populated content hash that matches the actual pack contents. |

## Pre-Flight Checks

1. Confirm the exact code surfaces for Home, Settings, Ask, seed content, and the manifest before editing.
   *Success signal: the implementation can name the files and data paths that will change for each of the six tasks.*

2. Confirm the live repositories or data sources available to the Home screen.
   *Success signal: the implementer can explain how each Home section will derive its state without introducing new storage layers.*

3. Confirm how Ask scope should persist and how it should reach retrieval.
   *Success signal: the implementation can describe the storage key or state boundary and the retrieval-level effect it should have.*

4. Confirm the content-navigation path for Ask actions before wiring buttons.
   *Success signal: the target route, destination view, or content identifier scheme is known before the tap handler is implemented.*

5. Confirm the thin seed chapters and the manifest update strategy.
   *Success signal: the implementation can list which chapters will be expanded and how `contentHash` values will be produced and recorded.*

## Phased Instructions

### Phase 1: Freeze The M3 Polish Scope

1. Keep the sprint limited to the six listed polish tasks.
   *Success signal: no M4 networking, import pipeline, refresh coordination, or new assistant architecture is introduced.*

2. Preserve the existing local-first and offline-first product shape.
   *Success signal: all changes work with the current on-device repositories and seed content.*

3. Prefer direct plumbing over abstraction.
   *Success signal: the solution uses the smallest useful changes to connect existing data and state to the UI.*

4. Treat each task as independently shippable.
   *Success signal: Home, Settings, Ask scope, Ask navigation, seed expansion, and manifest hashes can each land without depending on a new cross-cutting subsystem.*

### Phase 2: Wire Home To Live Repositories

1. Replace placeholder Home sections with live repository-backed state.
   *Success signal: Quick Cards, Active Checklists, Inventory, and Recent Notes all render real data instead of static copy.*

2. Keep the Home layout calm and scannable.
   *Success signal: the section presentation remains simple, readable, and stress-state friendly while showing real content.*

3. Surface empty and loading states intentionally.
   *Success signal: the user can distinguish between no data, loading, and populated repository-backed sections.*

4. Keep Home isolated from storage internals.
   *Success signal: the screen consumes repository or view-model state rather than raw persistence details.*

### Phase 3: Wire Settings Capability Status

1. Replace the `Checking...` placeholder with actual capability state.
   *Success signal: Settings reflects the runtime status provided by the existing capability detector or equivalent app-level source.*

2. Keep the display conservative.
   *Success signal: the capability label is clear and factual without exposing implementation details that the user does not need.*

3. Preserve privacy and offline expectations.
   *Success signal: capability display does not require network access or new telemetry.*

4. Keep the Settings section consistent with the rest of the app.
   *Success signal: the capability status reads like part of a local preparedness app, not a diagnostic dashboard.*

### Phase 4: Persist Ask Scope And Add Content Navigation

1. Replace the Ask scope toggle stub with persisted state.
   *Success signal: the toggle actually changes a stored value and survives app relaunches.*

2. Connect the persisted scope to Ask retrieval behavior.
   *Success signal: the toggle changes the content scope the assistant can consider, rather than acting as a visual-only control.*

3. Implement Ask result navigation into content.
   *Success signal: suggested actions and content taps can open the relevant quick card or handbook section instead of doing nothing.*

4. Keep navigation targets grounded in existing content IDs or routes.
   *Success signal: the deep-linking path reuses the app’s current content structure rather than inventing a new navigation model.*

### Phase 5: Expand Thin Seed Chapters And Populate Manifest Hashes

1. Expand the two thin handbook chapters so they are materially denser.
   *Success signal: the chapters used for retrieval evaluation have enough sections to improve local search and Ask grounding quality.*

2. Keep the added content aligned with the existing editorial posture.
   *Success signal: the new sections remain concise, conservative, and useful for offline browseability.*

3. Populate `contentHash` for each seed pack.
   *Success signal: every manifest pack has a non-null hash that corresponds to the actual pack contents.*

4. Keep the manifest and loader in sync.
   *Success signal: record counts, file names, versions, and hashes all describe the same on-disk content.

### Phase 6: Verify Consistency And User-Facing Behavior

1. Verify the Home screen shows live data.
   *Success signal: the four Home sections no longer render static placeholder text.*

2. Verify Settings reports a real capability state.
   *Success signal: the capability label is no longer a hardcoded `Checking...` placeholder.*

3. Verify Ask scope persistence and navigation.
   *Success signal: the toggle retains state and Ask actions land on the correct content views.*

4. Verify seed density and manifest integrity.
   *Success signal: the thin chapters are expanded and the manifest hashes and counts match the actual seed packs.*

5. Run the appropriate local checks for the touched files.
   *Success signal: code, content, and manifest changes are validated or any blocker is recorded precisely.*

## Guardrails

- Do not introduce M4 networking, import, refresh, or web-knowledge work.
- Do not add a new architecture layer just to remove a placeholder.
- Do not leave any of the six tasks half-wired behind new UI copy.
- Do not fabricate `contentHash` values; derive them from the real pack content.
- Do not widen the handbook or quick-card corpus beyond the current editorial and safety boundaries.
- Do not break existing seed loader validation or content references.
- Do not let Ask navigation or scope changes bypass the current retrieval contract.

## Verification Checklist

- [ ] Home renders live repository-backed state for all four sections.
- [ ] Settings displays real capability status instead of `Checking...`.
- [ ] Ask scope is persisted and affects retrieval scope.
- [ ] Ask result actions navigate to quick cards or handbook sections.
- [ ] Thin seed chapters are expanded with denser useful content.
- [ ] `SeedManifest.json` contains populated `contentHash` values.
- [ ] Manifest counts, versions, and file names still match the actual seed packs.
- [ ] Local verification was run or any blocker was reported explicitly.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| Home still renders placeholders after wiring data | Trace the repository or view-model source and replace the static copy with the live state path. |
| Settings capability remains hardcoded | Connect the view to the existing detector or app dependency instead of duplicating state. |
| Ask scope does not persist | Move the toggle to persisted app-local state and thread that state into retrieval. |
| Ask navigation cannot resolve a destination | Reuse an existing content route or content identifier rather than inventing a new deep-link path. |
| Seed chapters remain too thin for useful retrieval | Add focused sections to the targeted chapters instead of broadening to unrelated topics. |
| Manifest hashes do not match the actual pack contents | Recompute the hashes from the canonical on-disk pack data and update the manifest together with the content files. |
| Verification tooling is unavailable | Report the exact blocker and keep the affected claims unverified. |

## Out Of Scope

- M4 networking, import, refresh, and online knowledge work.
- New persistence schema work that is not required for the existing M3 polish items.
- A broader UI redesign beyond the placeholder removal and content wiring required here.
- Rewriting the Ask assistant boundary or retrieval architecture.
- Expanding the corpus into new topical areas unrelated to the thin-chapter fix.

## Report Format

When the sprint is complete, report back in this structure:

1. Files added and files changed.
2. Home screen wiring and the live repository state it now shows.
3. Settings capability wiring and the state source it uses.
4. Ask scope persistence and content-navigation changes.
5. Seed chapter expansion and manifest hash updates.
6. Verification commands run and their outcomes.
7. Remaining risks, deferred work, or explicitly unverified claims.
