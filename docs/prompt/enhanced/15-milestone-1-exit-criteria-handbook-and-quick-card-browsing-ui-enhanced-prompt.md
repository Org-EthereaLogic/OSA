# Milestone 1 Exit Criteria Enhanced Prompt: Handbook And Quick-Card Browsing UI

**Date:** 2026-03-23
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task turns the existing content repositories and seed-backed domain models into an offline-first browsing experience. It crosses feature UI, navigation, repository consumption, and grounded-content presentation, but it should not expand persistence or networking scope.

## Inputs Consulted

- Project operating rules: `AGENTS.md`, `DIRECTIVES.md`, `CLAUDE.md`, `CONSTITUTION.md`
- Product and architecture context: `README.md`, `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/04-information-architecture-and-ux-flows.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/09-content-model-editorial-guidelines.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`, `docs/sdlc/12-release-readiness-and-app-store-plan.md`
- Prior implementation prompts: `docs/prompt/enhanced/13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md`, `docs/prompt/enhanced/14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md`
- Current feature entry points: `OSA/Features/Library/LibraryScreen.swift`, `OSA/Features/QuickCards/QuickCardsScreen.swift`, `OSA/Features/Ask/AskScreen.swift`
- Current content boundary: `OSA/Domain/Content/Models/HandbookModels.swift`, `OSA/Domain/Content/Models/QuickCard.swift`, `OSA/Domain/Content/Models/SeedContentModels.swift`, `OSA/Domain/Content/Repositories/ContentRepositories.swift`
- Current persistence boundary: `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift`
- User brief: trusted PNW survival source allowlist, map references, Notion dashboard status, and the stated next logical step to build handbook and quick-card browsing UI for the Milestone 1 exit criteria

## Classification Summary

- Core intent: build the offline-first browsing UI that reads the already-defined handbook and quick-card content from the local repository layer, so the app can cold-start offline and still browse seeded content.
- In scope: Library browsing, handbook chapter and section presentation, quick-card browsing, content detail navigation, empty states, and provenance-aware content presentation where the data already carries it.
- Out of scope: new persistence schema, seed import pipeline work, networking, retrieval ranking, Ask orchestration changes, or broad UI polish unrelated to browsing readability.

## Assumptions

- The repository root is the folder containing `project.yml`, `OSA.xcodeproj`, `README.md`, and `docs/`.
- The existing domain and persistence layers are the source of truth for content structure and stable identity.
- `SwiftDataContentRepository` is the concrete repository implementation that the browsing UI should consume through dependency injection or the composition root.
- `LibraryScreen` and `QuickCardsScreen` are the current feature entry points that should be upgraded rather than replaced.
- The trusted-source allowlist is guidance for curated editorial content and provenance, not a license to add live web retrieval.

## Mission Statement

Deliver a calm, readable, offline-first browsing experience for handbook chapters, sections, and quick cards so the app satisfies the Milestone 1 exit criteria without expanding the storage or networking surface.

## Technical Context

The codebase already has the minimum content boundary needed for this task:

- `OSA/Domain/Content/Models/HandbookModels.swift` defines chapter and section values.
- `OSA/Domain/Content/Models/QuickCard.swift` defines quick-card values.
- `OSA/Domain/Content/Models/SeedContentModels.swift` defines seed bundle and version state types.
- `OSA/Domain/Content/Repositories/ContentRepositories.swift` defines the repository contracts.
- `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift` already provides the concrete implementation.
- `OSA/Features/Library/LibraryScreen.swift` and `OSA/Features/QuickCards/QuickCardsScreen.swift` are still placeholder surfaces.

The user brief also establishes a curated PNW survival source policy that should shape any content presentation or editorial metadata surfaced in the UI:

### Trusted Source Allowlist

#### Tier 1 - Top Approved, auto-approve

| # | Source | Why |
| --- | --- | --- |
| 1 | Ready.gov | Federal authority on emergency preparedness |
| 2 | Oregon Dept of Emergency Mgmt | State-level Cascadia/Oregon hazards |
| 3 | Washington Emergency Mgmt | State-level Washington preparedness |
| 4 | USGS | Topo maps, seismic data, hazard info |
| 5 | American Red Cross - Cascades | PNW disaster response, first aid |
| 6 | USDA Forest Service R6 | PNW wilderness maps, fire safety |

#### Tier 2 - Approved, auto-approve with periodic review

| # | Source | Why |
| --- | --- | --- |
| 7 | Pacific NW Seismic Network | Cascadia earthquake science |
| 8 | OSU Extension - Cascadia | Research-backed earthquake prep |
| 9 | The Prepared | Expert gear reviews and scenario planning |
| 10 | Surviving Cascadia | Monthly PNW-specific preparedness |
| 11 | Cascadia Ready | Cascadia kits and recommendations |
| 12 | Seattle Emergency Hubs | Community urban preparedness |

#### Tier 3 - Reference Only, flagged for review

| # | Source | Why |
| --- | --- | --- |
| 13 | Oregon Hazards Lab | Academic earthquake research |
| 14 | Mountain House Blog | Outdoor survival tips |
| 15 | Survival Common Sense | Wilderness survival, land navigation |

#### Map References

- PNW: USGS topoView, Forest Service R6 Avenza maps, PNTA strip maps, Nat Geo Trails Illustrated for PCT OR/WA
- US-wide: USGS US Topo Series for all 50 states, Nat Geo US trail maps

The browsing UI should respect this editorial posture by presenting content as curated local knowledge, not as general-web search output.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `LibraryScreen` is a placeholder with a single empty-state message. | Library shows chapters, chapter summaries, and drill-in navigation to chapter detail. |
| `QuickCardsScreen` is a placeholder with a single empty-state message. | Quick Cards shows browseable quick cards optimized for stress-state reading. |
| The content models exist but are not yet visible in the primary browsing surfaces. | Handbook and quick-card data are rendered from the repository layer with stable ordering. |
| Provenance and review metadata are only present in the domain model. | The UI surfaces what is already available without inventing new source data. |
| Offline readiness exists in storage but not yet in the user-facing browsing experience. | The app cold-starts offline and remains browseable from local seed content. |

## Pre-Flight Checks

1. Confirm the current state of the Library and Quick Cards feature files before editing.
   *Success signal: the agent can name the exact views it will modify and whether new detail views are required.*

2. Confirm the repository and domain types that will feed the UI.
   *Success signal: the agent can point to the repository protocols and the concrete SwiftData-backed repository implementation without guessing file names.*

3. Confirm that no new persistence schema is needed for this task.
   *Success signal: the browsing UI can be built entirely on top of existing domain and persistence contracts.*

4. Confirm the intended offline-first behavior for empty, loading, and error states.
   *Success signal: the agent can explain how the screens behave when content is missing, stale, or unavailable locally.*

## Phased Instructions

### Phase 1: Freeze The Browsing Scope

1. Define the minimum browsing experience required for Milestone 1 exit criteria.
   *Success signal: the agent explicitly states whether the task includes chapter lists only, chapter detail, section drill-down, quick-card detail, or all of them.*

2. Keep the task focused on local content browsing, not editorial authoring.
   *Success signal: there is no new editing, creation, or sync workflow introduced in the UI.*

3. Preserve the seeded content model and trusted-source posture from the domain layer.
   *Success signal: the UI plan uses the existing chapter, section, and quick-card identity and ordering fields instead of inventing new presentation-only data.*

### Phase 2: Implement Handbook Browsing In Library

1. Replace the Library placeholder with chapter browsing backed by the repository layer.
   *Success signal: the screen shows actual chapter rows with title, summary, and stable ordering.*

2. Add a chapter detail path that reveals sections in a readable hierarchy.
   *Success signal: a user can tap a chapter and reach content for its sections without leaving the offline local corpus.*

3. Present section content in a stress-friendly reading layout.
   *Success signal: the layout is legible, compact enough for one-handed use, and does not rely on animation or chrome to communicate content.*

4. Add sensible empty, loading, and failure states.
   *Success signal: the screen remains understandable when the repository returns no chapters or throws an error.*

### Phase 3: Implement Quick Card Browsing

1. Replace the Quick Cards placeholder with browseable quick-card content.
   *Success signal: the screen shows real quick cards with a clear ordering and summary presentation.*

2. Add quick-card detail views that favor immediate action over decorative presentation.
   *Success signal: the detail screen foregrounds the body text, related metadata, and other concise guidance.*

3. Optimize the layout for one-handed reading under stress.
   *Success signal: typography, spacing, and hierarchy support fast scanning instead of a dense card grid or overly ornamental layout.*

4. Keep quick cards visibly distinct from handbook chapters where that improves usability.
   *Success signal: the browsing model makes it clear which content is a quick card and which content is a longer handbook chapter.*

### Phase 4: Surface Provenance And Curated Context

1. Surface source or review metadata only when the domain data already provides it.
   *Success signal: the UI can display provenance, review dates, or trust-tier labels without fabricating missing values.*

2. Preserve the distinction between Tier 1, Tier 2, and Tier 3 source posture in any content-aware presentation.
   *Success signal: the UI or supporting copy does not flatten all sources into the same trust level.*

3. Avoid turning the browsing experience into a live web browser.
   *Success signal: the user is always looking at local curated content, not a search result stream.*

### Phase 5: Integration And Verification

1. Wire the screens into the existing navigation shell or composition root with minimal disruption.
   *Success signal: the new browsing screens are reachable from the app shell without rewriting unrelated navigation.*

2. Keep dependency injection simple and aligned with the current repository boundary.
   *Success signal: the feature layer depends on repository abstractions or a small injected container, not on SwiftData details.*

3. Add or update tests only where they verify browsing behavior or data mapping that the UI depends on.
   *Success signal: tests prove the browsing contract, ordered content, or empty-state behavior rather than just compiling the new views.*

4. Run the relevant build or test checks for the touched files.
   *Success signal: the implementation is verified or any blocker is explicitly labeled as unverified.*

## Guardrails

- Do not add new persistence models or alter the seed import pipeline unless the UI truly cannot be built without it.
- Do not expose `SwiftData` types in feature views.
- Do not add live web retrieval or online browsing behavior.
- Do not collapse the trusted-source tiers into a single undifferentiated list.
- Do not overbuild with speculative abstractions, generic repositories, or unnecessary view models.
- Do not sacrifice offline readability for visual polish.

## Verification Checklist

- [ ] The real Library screen replaces the placeholder state.
- [ ] The real Quick Cards screen replaces the placeholder state.
- [ ] Chapter browsing uses the existing repository layer.
- [ ] Quick-card browsing uses the existing repository layer.
- [ ] Any chapter or quick-card detail view is reachable from the list surface.
- [ ] Offline empty and error states are handled.
- [ ] Provenance or review metadata is surfaced only from existing data.
- [ ] The UI does not introduce new persistence or networking scope.
- [ ] Build or test verification was run, or blockers were reported explicitly.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| Library or Quick Cards data is unavailable locally | Show a clear empty state and keep the navigation shell stable. |
| A repository call throws | Present a graceful failure state and preserve the rest of the app experience. |
| Provenance data is missing for a record | Hide the provenance badge or metadata rather than inventing a value. |
| The trusted-source list conflicts with seed content | Defer the conflicting item and keep the curated allowlist authoritative. |
| A new view wants to import persistence details directly | Move the dependency behind the domain repository boundary before proceeding. |

## Out Of Scope

- New seed content creation or editorial expansion.
- Persistence schema changes.
- Seed import or migration work.
- Ask assistant changes.
- Retrieval ranking or online knowledge refresh.
- Map tile rendering or a full map subsystem.

## Report Format

When the implementation is complete, report in this structure:

1. Files added and files changed.
2. Browsing scope chosen and why.
3. Library navigation changes.
4. Quick-card navigation changes.
5. Provenance or trust-tier handling.
6. Verification commands run and outcomes.
7. Remaining risks or deferred work.
