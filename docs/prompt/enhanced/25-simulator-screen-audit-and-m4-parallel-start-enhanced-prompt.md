# Simulator Screen Audit And M4 Parallel Start Enhanced Prompt

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Validation
**Complexity:** Moderate
**Complexity Justification:** The execution work is short, but this prompt acts as a decision gate between offline-baseline validation and Milestone 4 online-enrichment work. It must distinguish real product readiness from simulator or UI-state noise, define a consistent screen-classification rubric, and preserve the correct dependency split for the next implementation wave.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow`
- User recommendation: `Take a screenshot of each tab in the running simulator and classify each screen as working, stubbed, or blocked. This takes minutes, costs nothing, and tells you whether M4 starts on a solid offline baseline or whether there's UI hardening that should happen first.`
- User sequencing note: `After that, M4P1 (ConnectivityService) and M4P2 (Import domain models) can start in parallel — neither has dependencies.`
- Prior related enhanced prompts: `docs/prompt/enhanced/23-app-bundle-seed-content-packaging-and-full-launch-validation-enhanced-prompt.md`, `docs/prompt/enhanced/24-coresimulator-restart-blocker-and-launch-validation-enhanced-prompt.md`
- Project governance: `AGENTS.md`, `CLAUDE.md`
- Product and architecture docs: `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/04-information-architecture-and-ux-flows.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Milestone context: `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`
- Current app shell: `OSA/App/Navigation/AppTab.swift`, `OSA/App/Navigation/AppTabView.swift`
- Evidence-storage conventions: `screenshot/README.md`, `report/README.md`
- Prompt workflow conventions: `docs/prompt/README.md`, `docs/prompt/enhanced/README.md`
- Repository memory note confirming the canonical prompt path is `docs/prompt/enhanced/`

## Mission Statement

Use the running simulator to capture evidence for every first-class OSA screen, classify each surface as working, stubbed, or blocked using a consistent rubric, and use that audit to decide whether Milestone 4 can begin on a stable offline baseline or whether UI hardening should happen first. If the offline baseline is solid, preserve the next split exactly as `M4P1 ConnectivityService` and `M4P2 import domain models` starting in parallel.

## Technical Context

OSA is explicitly offline-first. Milestones 1 through 3 are documented as complete, and the root navigation shell already exposes the required first-class surfaces: Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings. Milestone 4 introduces optional online enrichment, but those flows are not allowed to become a workaround for unresolved offline UI gaps.

The current codebase shows that the navigation shell exists, the offline domains and Ask flow are implemented, and the major M4 service and import-model work is still largely scaffolded in documentation rather than code. That makes a quick simulator screen audit valuable right now: it confirms whether the product actually presents a stable offline baseline in practice, or whether there is still screen-level hardening needed before networking and import work fan out.

This prompt should treat screenshots and screen classification as evidence, not as ceremony. The output is a factual gate decision for the next workstream.

## Classification Rubric

### Working

- The screen loads and is reachable from the running app.
- It renders intended live local data or a valid domain-appropriate empty state.
- Primary interactions or navigation routes on that screen behave coherently.
- No obvious placeholder copy, stub affordance, blocking runtime error, or blank-state defect is present.

### Stubbed

- The screen loads, but meaningful parts of it are still placeholder, incomplete, or not wired to the intended data or behavior.
- The screen shows scaffolding that is visibly not production-ready, even if it does not crash.
- The screen is usable only as a shell and still needs implementation or hardening before it should count as a stable baseline.

### Blocked

- The screen cannot be reached, fails to render, crashes, shows a blocking error, or depends on an environment issue that prevents meaningful validation.
- The simulator, build, launch path, or navigation failure prevents a trustworthy screen-level conclusion.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| The app may now cold-launch, but the actual usability of every first-class screen is not yet captured as evidence. | Every first-class screen has a screenshot-backed classification: working, stubbed, or blocked. |
| Milestone 4 can be started too early if offline UI quality is assumed instead of verified. | The screen audit produces a clear go or hold decision for M4 based on observed runtime behavior. |
| Connectivity and import work are planned but not yet implemented. | If the offline baseline is solid, `M4P1 ConnectivityService` and `M4P2 import domain models` begin in parallel with no invented dependency between them. |
| Simulator or launch instability can still masquerade as product readiness or product failure. | Environment blockers remain explicitly separated from app-surface findings. |

## Pre-Flight Checks

1. Confirm the simulator is healthy enough to run the app.
   *Success signal: the audit begins from an actually running simulator session, or an exact simulator blocker is recorded.*

2. Confirm the app has launched from the current code state rather than from stale screenshots or assumptions.
   *Success signal: all classifications are based on the current runtime, not prior notes.*

3. Identify the complete first-class surface list from the implemented app shell.
   *Success signal: the audit covers Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings.*

4. Decide where evidence will live if screenshots are exported.
   *Success signal: screenshots are either saved under `screenshot/` with dated or report-linked naming, or the report explicitly notes that screenshots were observed but not persisted as files.*

5. Define the M4 gate before starting the walkthrough.
   *Success signal: the executor knows that the purpose is to choose between `offline UI hardening first` and `start M4P1 + M4P2 in parallel`.*

## Phased Instructions

### Phase 1: Launch And Establish Audit Conditions

1. Start from the currently running simulator session if it is healthy.
   *Success signal: the app can be inspected without reintroducing environment uncertainty.*

2. If the simulator is still unhealthy, stop and record the exact blocker.
   *Success signal: environment failure is classified as blocked instead of being misreported as a UI verdict.*

3. Keep all conclusions tied to observable runtime behavior.
   *Success signal: the audit contains no guessed screen state and no unverified claims.*

### Phase 2: Capture Evidence For Every First-Class Screen

1. Visit Home, Library, Ask, and Inventory from the primary tab bar.
   *Success signal: each primary tab has a current screenshot and an initial screen-state note.*

2. Open the `More` section and visit Checklists, Quick Cards, Notes, and Settings.
   *Success signal: each first-class surface defined in the app shell is examined once in the same audit pass.*

3. Take a screenshot of each screen in its natural top-level state.
   *Success signal: there is one piece of visual evidence per screen, not just a prose summary.*

4. If a screen cannot be reached or rendered, capture the failing state anyway.
   *Success signal: blocked screens still produce evidence instead of disappearing from the audit.*

### Phase 3: Classify Each Screen Consistently

1. Apply the working, stubbed, or blocked rubric to every screen immediately after capture.
   *Success signal: the classification is consistent and attached to the observed screenshot rather than reconstructed later.*

2. Keep the judgment narrow and product-facing.
   *Success signal: each classification states what the user would experience, not a speculative root-cause essay.*

3. Record the specific reason for any screen that is not working.
   *Success signal: each stubbed or blocked status includes a short factual rationale that can become follow-up work.*

### Phase 4: Decide The M4 Gate

1. If the offline baseline is materially solid, mark the audit as a go for M4.
   *Success signal: the report explicitly says the app is ready to start `M4P1 ConnectivityService` and `M4P2 import domain models` in parallel.*

2. If one or more core offline surfaces are still stubbed or blocked in a way that weakens the baseline, hold M4 and prioritize UI hardening first.
   *Success signal: the report names the hardening targets before any new online-enrichment scope is started.*

3. Keep later M4 sequencing intact after the gate decision.
   *Success signal: no new dependency is invented between `M4P1` and `M4P2`, and later import-pipeline work stays downstream of those foundations.*

### Phase 5: Preserve The Next-Step Split

Use the following next-step table after the audit:

| Condition | Next Step |
| --- | --- |
| All first-class offline surfaces are working, or only minor non-blocking polish remains | Start `M4P1 ConnectivityService` and `M4P2 import domain models` in parallel. |
| Any core offline surface is stubbed in a way that undermines the baseline | Create UI-hardening follow-ups first, then re-run the audit before starting M4. |
| Any core offline surface is blocked by launch, navigation, or simulator failure | Resolve the blocker, re-run the audit, and keep M4 unstarted until the result is trustworthy. |

## Guardrails

- Do not classify a screen from memory or from static code inspection alone.
- Do not treat process launch as proof that the offline baseline is solid.
- Do not excuse a stubbed or blocked core screen just because M4 work is attractive or independent.
- Do not invent a dependency between `M4P1 ConnectivityService` and `M4P2 import domain models`; they can start in parallel if the audit passes.
- Do not blur environment blockers and app findings into one status.
- Do not save the artifact under `docs/prompts/`; this repository uses `docs/prompt/enhanced/`.

## Verification Checklist

- [ ] The app was inspected in a currently running simulator session, or the precise simulator blocker was captured.
- [ ] Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings were each visited once in the audit pass.
- [ ] A screenshot exists for each visited screen, or a precise reason explains why capture was blocked.
- [ ] Every screen was classified as working, stubbed, or blocked using the shared rubric.
- [ ] Each stubbed or blocked screen includes a concise factual reason.
- [ ] The report makes a clear go or hold decision for Milestone 4.
- [ ] If the audit passes, the report preserves `M4P1` and `M4P2` as parallel next steps.
- [ ] If the audit does not pass, the report names the UI hardening or blocker-removal work that must happen first.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| Simulator is not healthy enough to run the app | Mark the relevant screens as blocked by environment and route back through the existing CoreSimulator recovery prompt before making any M4 decision. |
| App launches but a screen is blank or obviously placeholder-only | Mark it as stubbed unless a concrete blocking error prevents interaction entirely. |
| A screen crashes or navigation fails when selected | Mark it as blocked and capture the exact failing surface and trigger. |
| Screenshot capture works in the simulator UI but is not saved into the repo | Record the observed result in the report and optionally save later under `screenshot/`; do not lose the classification just because repo-side file persistence was skipped. |
| Mixed results make the M4 decision ambiguous | Default to holding M4 until the core offline baseline is clearly trustworthy. |

## Out Of Scope

- Implementing `ConnectivityService`, import domain models, or any other M4 code in the same task.
- Redesigning screens during the audit.
- Rewriting roadmap dependencies that are already documented.
- Treating expected future M4 settings sections as implemented just because placeholder UI exists.

## Report Format

When this prompt is executed, report back in this structure:

1. Simulator state and whether the audit ran successfully.
2. Screenshot evidence location, if files were saved.
3. A screen table with: screen name, classification, and one-sentence reason.
4. A short summary of whether the offline baseline is solid.
5. The gate decision: `hold for UI hardening` or `start M4P1 + M4P2 in parallel`.
6. Exact blockers or unverified claims, if any.
