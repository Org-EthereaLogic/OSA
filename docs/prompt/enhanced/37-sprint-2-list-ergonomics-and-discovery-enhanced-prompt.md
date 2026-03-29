# Implement Sprint 2 List Ergonomics And Discovery

**Date:** 2026-03-28  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** This sprint improves five existing product surfaces with search, empty-state, swipe-action, context-menu, and recent-history behavior. It likely touches 8-12 Swift files plus focused tests, but it should stay inside current repository, settings, and navigation patterns without introducing new persistence architecture or online behavior.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 2 is about list ergonomics and discovery: search, empty states, swipe/context actions, topic browse, and recently viewed. |
| `AGENTS.md`, `CONSTITUTION.md`, `DIRECTIVES.md`, `CLAUDE.md` | Keep changes offline-first, local-first, minimally scoped, and evidence-backed. Do not add speculative architecture or uncited assistant behavior. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Quick Cards, Notes, Checklists, Inventory, and Library are first-class surfaces; empty states should guide the user; Library is the browse/search entry for local content. |
| `docs/sdlc/05-technical-architecture.md` | Feature screens consume repositories through environment injection; settings-like local UI state should stay lightweight; Home and Library already use app-local persisted settings patterns. |
| `docs/sdlc/06-data-model-local-storage.md` | Notes, inventory, and checklist data already exist locally and must not require new SwiftData schema work for a UI ergonomics sprint. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Favor focused tests and UI checks for navigation, search, and offline-safe behavior; report blockers as unverified. |
| `docs/prompt/enhanced/20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md` | Existing enhanced prompts in this repo use explicit scope, phased instructions, guardrails, and verification checklists. |
| `OSA/Features/QuickCards/QuickCardsScreen.swift`, `OSA/Features/Notes/NotesScreen.swift`, `OSA/Features/Checklists/ChecklistsScreen.swift`, `OSA/Features/Inventory/InventoryScreen.swift`, `OSA/Features/Library/LibraryScreen.swift` | The current list screens are mostly passive lists with minimal empty states; Library already has search and hazard chips, but not a recently viewed section. |
| `OSA/Domain/Settings/AskScopeSettings.swift`, `OSA/Domain/Settings/PinnedContentSettings.swift`, `OSA/Persistence/SearchIndex/LocalSearchService.swift` | Lightweight persisted UI state already uses `@AppStorage` and `UserDefaults`; reuse those patterns for recent-history behavior instead of adding new persistence layers. |
| `OSA/Domain/Inventory/Repositories/InventoryRepositories.swift`, `OSA/Domain/Checklists/Repositories/ChecklistRepositories.swift` | The existing domain layer already supports inventory archive/delete and checklist start/delete behaviors that can back swipe and context actions without new protocols. |

## Assumptions

- Treat `searchable attributes` in this sprint as in-app list searchability and discovery copy for the dedicated screens, not as a new Siri, Spotlight, or App Entity expansion.
- Keep list filtering local to already-loaded arrays unless an existing repository method clearly provides a better fit.
- Implement `Recently Viewed` as a lightweight app-local history for Library content, not as a new analytics or cross-device sync system.
- Reuse existing navigation destinations such as `QuickCardDetailView`, `ChecklistTemplateDetailView`, `ChecklistRunView`, `InventoryItemDetailView`, `ChapterDetailView`, and `HandbookSectionDetailView`.
- Preserve current privacy boundaries: do not expose more note content outside the app’s existing local search and UI than the current product already allows.

## Mission Statement

Improve list findability and common actions across Quick Cards, Notes, Checklists, Inventory, and Library by adding local search, actionable empty states, swipe/context actions, topical browse support, and a lightweight recently viewed section without changing the app’s storage architecture or online boundaries.

## Technical Context

The current surfaces already have the domain data needed for this sprint, but the UX is uneven:

- `LibraryScreen` already supports `.searchable`, search suggestions, and hazard-scenario chips, so it is the strongest example of current local discovery behavior.
- `QuickCardsScreen`, `NotesScreen`, and `ChecklistsScreen` are loaded from repositories but currently provide no text search, no search-result empty state, and limited secondary actions.
- `InventoryScreen` groups data well and already supports archive/delete at the repository layer, but the list surface only exposes destructive delete and requires extra taps for common actions.
- `QuickCardDetailView` and `InventoryItemDetailView` already expose pinning or action menus that can inform row-level context menus rather than inventing new semantics.
- `HandbookSectionDetailView` already represents the strongest “recently viewed” candidate because it is a stable, local, identifier-backed reading surface.

Use the smallest coherent implementation:

1. Prefer local filtering over loaded arrays for screen-level search.
2. Reuse existing repository methods for swipe actions.
3. Reuse existing `@AppStorage` or `UserDefaults` patterns for recent history.
4. Keep SwiftData and persistence internals out of feature-layer code.
5. Do not expand this sprint into App Intents, online discovery, or assistant changes.

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Quick Cards list | Repository-backed cards render as a passive scroll view with a generic empty state and no search or row-level secondary actions. | The screen supports local search, distinct “no cards” vs. “no results” empty states, and a context menu for common actions such as pin/open. |
| Notes list | Notes can be filtered by note type only; there is no text search and the empty state only says to tap `+`. | Notes can be searched locally by title/body/tags, and empty states guide first-note creation with concrete preparedness-oriented examples. |
| Checklists list | Templates and active runs are browseable, but there is no text search, no search-result state, and no row-level quick actions. | Templates and active runs support local search plus swipe actions for quick start and abandon/delete flows that match current repository capabilities. |
| Inventory list | Items can be deleted from the list and managed from detail, but common actions are still extra-tap heavy and row context is limited. | Inventory rows support swipe actions and a context menu for archive/unarchive, delete, and edit/open flows. |
| Empty states | Current empty states are brief and mostly static. | Empty states clearly distinguish initial zero state from filtered no-results state and give actionable next steps that fit an offline preparedness app. |
| Library discovery | Library already supports global search and hazard chips, but topic browse is shallow and there is no recently viewed section. | Library adds a clearer topic-browse surface derived from existing chapter metadata and a lightweight recently viewed section sourced from local history. |

## Pre-Flight Checks

1. Verify the owning files before editing: `OSA/Features/QuickCards/QuickCardsScreen.swift`, `OSA/Features/Notes/NotesScreen.swift`, `OSA/Features/Checklists/ChecklistsScreen.swift`, `OSA/Features/Inventory/InventoryScreen.swift`, `OSA/Features/Library/LibraryScreen.swift`, `OSA/Features/Library/HandbookSectionDetailView.swift`, and any helper added under `OSA/Domain/Settings/` or `OSA/Shared/Support/`.
   *Success signal: every requested behavior has a concrete owning file before implementation begins.*

2. Confirm which actions are already supported by the domain layer.
   *Success signal: inventory archive/delete and checklist start/delete flows map to existing repository methods and do not require new protocols.*

3. Confirm the local filtering fields for each list surface.
   *Success signal: the implementation can name the exact properties used for search in Quick Cards, Notes, and Checklists before adding `.searchable`.*

4. Confirm the persistence pattern for recent history.
   *Success signal: the implementation uses `@AppStorage` or `UserDefaults` like `PinnedContentSettings` or `LocalSearchService`, not SwiftData.*

5. Confirm the tests to update before coding.
   *Success signal: at least one focused unit-level verification target and one UI verification target are identified up front.*

## Phased Instructions

### Phase 1: Bound The Sprint And Reuse Existing Seams

1. Keep Sprint 2 limited to list ergonomics and discovery on existing surfaces.
   *Success signal: no assistant, networking, import, App Intents, Spotlight-entity expansion, or schema-migration work appears in the change.*

2. Use current repositories and loaded arrays as the default search source.
   *Success signal: the implementation filters local in-memory data for screen-level search instead of adding new repository APIs unless a concrete blocker is found.*

3. Reuse current persisted-settings patterns for recent history.
   *Success signal: any new helper looks and behaves like `PinnedContentSettings` or the recent-query storage inside `LocalSearchService`.*

### Phase 2: Add Search And Better Empty States To The List Screens

1. Add local search to `OSA/Features/QuickCards/QuickCardsScreen.swift`.
   Use SwiftUI `.searchable` plus local filtering over `title`, `summary`, `category`, and `tags`, and keep the screen fully offline-capable.
   *Success signal: typing a query narrows the visible quick cards without any new network or persistence dependency.*

2. Add local search to `OSA/Features/Notes/NotesScreen.swift`.
   Preserve the existing note-type filter menu, and layer text search over `title`, `plainText`, and `tags` so the two filters compose instead of replacing each other.
   *Success signal: the Notes screen can narrow results by both note type and free-text query at the same time.*

3. Add local search to `OSA/Features/Checklists/ChecklistsScreen.swift`.
   Search template `title`, `description`, `category`, and item text; search active runs by `title` and any user-visible run context that already exists locally.
   *Success signal: checklist templates and active runs can be narrowed from the same search field without changing repository contracts.*

4. Replace generic zero states with actionable copy in `QuickCardsScreen`, `NotesScreen`, `ChecklistsScreen`, and any search-specific no-results state these screens introduce.
   Distinguish between first-use empty state and filtered no-results state. Prefer guidance like “Create a family plan note,” “Pin or review urgent quick cards,” or “Start from seeded templates,” not generic placeholder text.
   *Success signal: each affected screen explains what to do next when empty and what to change when a search yields no matches.*

### Phase 3: Add Common Row Actions Without New Domain APIs

1. Add inventory swipe actions in `OSA/Features/Inventory/InventoryScreen.swift` using existing repository methods.
   Support archive or unarchive plus destructive delete; if edit is exposed from the row, reuse the existing item form flow rather than creating a second editing path.
   *Success signal: a user can archive or delete an item directly from the list, and the action is reflected after reload.*

2. Add checklist swipe actions in `OSA/Features/Checklists/ChecklistsScreen.swift` where the action semantics are already supported.
   For templates, prefer a quick-start action backed by `startRun(from:title:contextNote:)`. For active runs, prefer a destructive abandon/delete action backed by `deleteRun(id:)` with confirmation if the UX would otherwise be too easy to trigger accidentally.
   *Success signal: checklist list rows expose at least one high-value quick action each without requiring new repository methods.*

3. Add a context menu to quick-card rows in `OSA/Features/QuickCards/QuickCardsScreen.swift`.
    Reuse current product semantics such as open, pin or unpin, and, when available, navigating to a first related handbook section. Do not invent sharing, export, or online actions.
    *Success signal: long-pressing a quick card exposes useful local actions that match the existing pinning and navigation model.*

4. Add a context menu to inventory rows in `OSA/Features/Inventory/InventoryScreen.swift` that mirrors the existing detail-screen action model.
    Reuse edit, archive or unarchive, and delete semantics already present in `OSA/Features/Inventory/InventoryItemDetailView.swift`.
    *Success signal: long-pressing an inventory row exposes the same core operations the detail view already supports, with no new behavior drift.*

### Phase 4: Improve Library Topic Browse And Recently Viewed

1. Strengthen topic browse in `OSA/Features/Library/LibraryScreen.swift` using existing `HandbookChapterSummary.tags` and current formatting helpers.
    Prefer deriving topic chips or grouped browse affordances from existing chapter metadata. If non-scenario tags are too sparse, fall back to a small UI-only mapping based on current chapter metadata rather than altering the content schema.
    *Success signal: Library offers a clearer browse-by-topic path than the current hazard-scenario-only chips and does not require new seed-content schema work.*

2. Introduce a lightweight recent-history helper under `OSA/Domain/Settings/` or `OSA/Shared/Support/` and record handbook section views from `OSA/Features/Library/HandbookSectionDetailView.swift`.
    Keep the stored payload small and local, for example a bounded ordered list of recent section IDs.
    *Success signal: opening handbook sections updates a stable local recent-history list without involving SwiftData or any remote service.*

3. Render a `Recently Viewed` section in `OSA/Features/Library/LibraryScreen.swift` using the recent-history helper plus existing repository lookups.
    Show only resolvable local entries, cap the list to a small number, and keep it subordinate to primary browsing and search.
    *Success signal: returning to Library shows the most recently opened local handbook sections when history exists, and hides the section cleanly when it does not.*

### Phase 5: Verification And Quality

1. Add focused verification for the new recent-history helper and any extracted pure filtering logic.
    Prefer small deterministic unit tests over view-heavy tests when possible.
    *Success signal: helper behavior such as bounded ordering, duplicate de-duplication, and decode safety is covered by unit tests.*

2. Extend UI coverage in `OSAUITests/OSAContentAndInputTests.swift` and `OSAUITests/OSAFullE2EVisualTests.swift` for the highest-value user-facing changes.
    Cover at least one searchable list surface and Library recently viewed visibility after navigating into a section. Do not overfit the suite with brittle gesture-only tests if a smaller assertion proves the feature is wired.
    *Success signal: UI verification proves the new list discovery behavior is visible and reachable in the running app.*

3. Run a simulator build after the implementation is complete.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

   *Success signal: the project builds successfully for the standard simulator destination.*

1. Run a focused test pass for the touched surfaces.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSAUITests/OSAContentAndInputTests -only-testing:OSAUITests/OSAFullE2EVisualTests
```

   *Success signal: the focused UI checks for list discovery and Library navigation pass, or any exact blocker is reported.*

1. Run security scanning for the new first-party code if `snyk` is available.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
```

   *Success signal: Snyk Code completes, or the exact environment blocker is reported as unverified.*

## Guardrails

- Do not add new SwiftData models, migrations, or repository protocols unless a concrete blocker proves the current seams are insufficient.
- Do not add a new `NoteEntity`, App Intent, or Spotlight indexing expansion in this sprint.
- Do not introduce online discovery, trusted-source import, Ask scope changes, or assistant retrieval changes.
- Do not leak note content into any new system-surface metadata or other privacy-widening pathways.
- Do not replace current navigation structure or redesign the tab model.
- Do not create generic list abstractions or reusable helper layers unless two or more touched screens genuinely need the exact same code.
- Keep recent history local, bounded, and opaque to anything outside the app.
- Preserve accessibility labels and hints for new search, swipe, and context-menu actions.

## Verification Checklist

- [ ] `QuickCardsScreen` supports local search and distinguishes empty vs. no-results states.
- [ ] `NotesScreen` supports combined note-type filtering and local text search.
- [ ] `ChecklistsScreen` supports local search across templates and active runs.
- [ ] Inventory list rows expose high-value swipe actions backed by existing repository methods.
- [ ] Checklist rows expose quick actions backed by existing repository methods.
- [ ] Quick-card rows expose a useful context menu consistent with existing pin/navigation semantics.
- [ ] Inventory rows expose a context menu consistent with existing detail-view actions.
- [ ] Library offers clearer topic browsing using current chapter metadata.
- [ ] Library shows a lightweight recently viewed section when local history exists.
- [ ] New local-history storage is bounded, deterministic, and unit-tested.
- [ ] Focused build and test commands were run, or blockers were reported explicitly.
- [ ] Security scan was run when available, or the exact blocker was recorded.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Chapter tags are too sparse or inconsistent for a clean topic browse UI | Fall back to a small UI-only topic mapping based on existing chapter metadata; do not change the seed-content schema in this sprint. |
| Search logic becomes duplicated across screens | Extract only the smallest pure helper needed for normalization or matching; keep screen-specific UI state in each feature file. |
| Context menus conflict with `NavigationLink` tap behavior | Attach the context menu to the row label or a stable wrapper view instead of replacing the navigation model. |
| Swipe actions are too destructive for active checklist runs | Add confirmation for delete or abandon, and keep the destructive action explicit. |
| Recent-history IDs no longer resolve because content changed | Filter unresolved IDs out of the Library section and prune the stored list opportunistically. |
| Focused UI tests become flaky around gestures or search timing | Assert the visible post-condition with a smaller deterministic flow instead of trying to prove every gesture path in UI automation. |
| `xcodebuild` or `snyk` is unavailable in the environment | Report the exact command, failure mode, and date; mark the affected verification as unverified. |

## Out Of Scope

- New App Intents, Siri, Spotlight, or `AppEntity` coverage for Notes.
- Search-index or retrieval-pipeline changes beyond what current list screens already load locally.
- Home screen redesign, Ask UX changes, or imported-knowledge discovery/import work.
- New sync, export, analytics, or cross-device history behavior.
- Seed-content schema changes solely to support this sprint’s Library browse UI.

## Alternative Solutions

1. **Search fallback:** If per-screen filtering becomes noisy, introduce one small shared local matcher helper under `OSA/Shared/Support/` for string normalization and matching. Do not push the behavior into new repository APIs unless current lists are demonstrably too large or incomplete.
2. **Recent-history fallback:** If `@AppStorage` becomes awkward for bounded ordered IDs, use a tiny `UserDefaults`-backed helper type similar to `LocalSearchService.recentQueries()` rather than adding SwiftData.
3. **Topic-browse fallback:** If metadata-driven topic chips are not coherent enough, keep the current hazard chips and add one clearly named “Browse by Topic” section based on existing curated chapter groupings instead of editing seed data or inventing a taxonomy engine.

## Report Format

When the sprint is complete, report back in this structure:

1. Source prompt quoted verbatim.
2. Files changed and any files added.
3. Search and empty-state changes by surface.
4. Swipe and context-menu actions added and the repository methods they rely on.
5. Library topic-browse and recently viewed implementation details.
6. Verification commands run and their outcomes.
7. Security scan outcome or exact blocker.
8. Assumptions, deferred work, and any explicitly unverified claims.
