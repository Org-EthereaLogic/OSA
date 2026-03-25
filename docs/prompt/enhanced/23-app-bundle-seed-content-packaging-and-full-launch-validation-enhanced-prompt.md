# App Bundle Seed-Content Packaging And Full Launch Validation Enhanced Prompt

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Moderate
**Complexity Justification:** The immediate code change is narrow, but the task must connect XcodeGen resource packaging, app-bundle seed-content availability, cold-launch validation, and the decision of whether the main UI surfaces are actually usable or still stubbed before Milestone 4 work proceeds.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow`
- User recommendation: `Fix the app bundle packaging, then validate the full app launch.`
- User constraint: save the enhanced prompt artifact under the prompt-enhanced area for this repository
- Project governance: `AGENTS.md`, `CLAUDE.md`
- Product and architecture docs: `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Current build configuration: `project.yml`
- Prompt workflow conventions: `docs/prompt/README.md`, `docs/prompt/enhanced/README.md`
- Repository memory note confirming the canonical prompt path is `docs/prompt/enhanced/`

## Mission Statement

Fix the app-bundle packaging so bundled seed content is copied into the OSA app target reliably, regenerate the Xcode project from `project.yml`, validate that the app can cold-launch with seed content available, and use that validation pass to determine whether the core UI surfaces render correctly with live data or still expose placeholder or stub behavior.

## Technical Context

OSA is an offline-first iPhone app whose initial handbook and quick-card corpus ships inside the app bundle and is imported into the local store on first launch. If the seed-content folder is not present in the target's generated resource copy phase, first-launch import can fail or the app can launch without the local corpus needed by Home, Library, Ask, Quick Cards, and related screens.

The current recommendation is to fix this packaging issue before starting Milestone 4 online-enrichment work. That ordering matters because a passing full app launch provides two concrete answers: whether the bundle and seed import path are healthy, and whether the top-level screens actually render useful live data instead of placeholder UI. That evidence should shape what remains in UI hardening before networking and import pipeline work accelerates.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| Seed content is not reliably packaged into the app bundle generated from `project.yml`. | `project.yml` produces an Xcode project whose OSA target copies the seed-content folder into the bundle. |
| First launch cannot be trusted as a real validation of bundled offline content. | Cold launch proves whether bundled content is available and importable on-device. |
| The true state of top-level screens with live data is uncertain. | Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings are observed during launch validation and classified as working, stubbed, or blocked. |
| Milestone 4 could begin while a lower-level packaging defect still exists. | The packaging fix is resolved first so M4 starts on a stable offline baseline. |

## Pre-Flight Checks

1. Inspect the OSA target in `project.yml` and confirm how `OSA/Resources/SeedContent` is currently declared.
   *Success signal: the implementation can point to the exact resource configuration that controls whether XcodeGen includes the seed-content folder in the app target.*

2. Confirm whether `xcodegen generate` is required after the manifest change.
   *Success signal: the generated `OSA.xcodeproj` is known to reflect the updated resource configuration.*

3. Identify the first-launch path that depends on bundled seed content.
   *Success signal: the implementation can name the loader, bootstrap, or repository path that consumes the bundle resource.*

4. Define the validation surface list before running the app.
   *Success signal: the verification pass explicitly checks Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings rather than stopping at process launch.*

5. Confirm the exact environment limitation, if any, around building or launching the app locally.
   *Success signal: any unavailable tool, simulator, or Xcode configuration issue is reported precisely instead of guessed around.*

## Phased Instructions

### Phase 1: Fix App-Bundle Packaging

1. Update `project.yml` so the OSA target explicitly includes the bundled seed-content folder in the generated resource copy phase.
   *Success signal: the target configuration makes the seed-content folder part of app resources rather than relying on accidental inclusion.*

2. Keep the change minimal and consistent with the repository's existing XcodeGen style.
   *Success signal: the fix touches only the resource configuration needed for deterministic bundling.*

3. Preserve the offline-first startup path.
   *Success signal: no change assumes network access or moves seed content out of the bundle-backed initialization flow.*

### Phase 2: Regenerate The Project

1. Run `xcodegen generate` after changing `project.yml`.
   *Success signal: `OSA.xcodeproj` reflects the updated target resource-copy configuration.*

2. Inspect the generated project result only as needed to confirm the manifest change propagated.
   *Success signal: the app target is regenerated cleanly with no configuration drift left unresolved.*

### Phase 3: Validate Cold Launch And Seed Availability

1. Build and launch the app using the repository's required local validation path.
   *Success signal: the app process launches from a generated project that includes the bundled seed content.*

2. Verify that the seed-content-dependent startup path succeeds.
   *Success signal: bundled handbook and quick-card content is available locally after cold launch, or the exact failure is captured precisely.*

3. Keep verification factual.
   *Success signal: only observed launch behavior, build output, simulator results, and tool-blocker facts are reported.*

### Phase 4: Check Top-Level UI Surfaces With Live Data

1. Visit the top-level screens during launch validation: Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings.
   *Success signal: each screen is classified as rendering correctly with live local data, still showing placeholder or stub behavior, or blocked by a concrete error.*

2. Treat this as a real product-state assessment, not just a smoke test.
   *Success signal: the validation distinguishes between a technically launched app and a materially usable offline UI.*

3. Record any screen-specific follow-up work that remains before or alongside M4.
   *Success signal: unresolved UI work is described concretely enough to turn into backlog items without re-discovery.*

### Phase 5: Preserve M4 Sequencing After Packaging Stabilizes

1. Keep the M4 board sequence intact once packaging and launch validation are complete.
   *Success signal: packaging work is treated as a prerequisite cleanup, not a reason to reorder the existing M4 dependency chain.*

2. Use the following dependency order for the next implementation wave:

| Phase | Task | Dependency |
| --- | --- | --- |
| M4P1 | ConnectivityService (`NWPathMonitor`) | None - can start immediately |
| M4P2 | Import domain models (`SourceRecord`, `KnowledgeChunk`) | None - parallel with P1 |
| M4P3 | Trusted-source allowlist and HTTP client | P1 - needs connectivity state |
| M4P4 | Import pipeline (normalize, chunk, commit) | P2 + P3 |
| M4P5 | Refresh and retry coordination | P4 |
| M4P6 | Ask online search offer UX | P4 + P5 |

1. Do not start M4 by bypassing packaging validation.
   *Success signal: the project enters online-enrichment work only after the offline app bundle and launch baseline are known-good or explicitly blocked by a documented tool issue.*

## Guardrails

- Do not assume the seed-content packaging problem is fixed until the generated project and launch path prove it.
- Do not widen this task into general UI redesign or unrelated refactoring.
- Do not fabricate a successful app launch, simulator run, or screen-state assessment.
- Do not start Milestone 4 implementation inside this task unless the packaging and validation work is complete and explicitly requested.
- Do not treat process launch alone as sufficient verification if the seeded offline surfaces are still blank, stubbed, or broken.
- Do not save the artifact under `docs/prompts/`; this repository's canonical prompt path is `docs/prompt/enhanced/`.

## Verification Checklist

- [ ] `project.yml` explicitly bundles the seed-content folder for the OSA target.
- [ ] `xcodegen generate` was run after the manifest change.
- [ ] The generated project reflects the resource configuration change.
- [ ] App cold launch was attempted from the regenerated project.
- [ ] Seed-content availability at launch was verified or blocked with a precise reason.
- [ ] Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings were checked during validation.
- [ ] Each top-level screen was classified as working, stubbed, or blocked.
- [ ] The M4 dependency board was preserved as the next step after packaging stabilization.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| `project.yml` change does not propagate into the generated project | Re-run `xcodegen generate`, then inspect the regenerated target resource configuration for drift or misdeclared paths. |
| App still launches without seed content | Trace the bundle lookup and first-launch import path to confirm the runtime expects the same folder structure that the bundle now contains. |
| Build or launch fails because full Xcode is unavailable | Report the exact blocker and keep the affected launch-validation claims unverified. |
| A screen opens but still shows placeholder data | Mark that screen as stubbed rather than calling validation complete, and record the exact placeholder or missing data path. |
| M4 planning pressure pushes ahead before verification | Hold the existing M4 sequence, finish packaging validation first, then resume the already-defined dependency order. |

## Out Of Scope

- Implementing Milestone 4 connectivity, import, refresh, or Ask online-offer code.
- Redesigning top-level screens beyond the validation needed to classify their current state.
- Broad seed-content editorial expansion unrelated to proving bundle availability.
- Refactoring architecture layers that are not necessary to fix app-bundle packaging.

## Report Format

When this task is executed, report back in this structure:

1. Files changed for the packaging fix.
2. Whether `xcodegen generate` succeeded and what it changed.
3. Build and launch commands run, with factual outcomes.
4. Seed-content availability result on cold launch.
5. Screen-by-screen validation for Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings.
6. Exact blockers or unverified claims, if any.
7. Confirmation that the next queued work remains M4P1 through M4P6 in the documented order.
