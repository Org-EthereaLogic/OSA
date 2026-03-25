# Checklist SwiftData Runtime Investigation And Test Recovery Enhanced Prompt

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Bugfix
**Complexity:** Complex
**Complexity Justification:** The primary failure is a SwiftData runtime crash in the checklist persistence graph under Xcode 16.2 and iOS 18.3 test execution. The work requires reproducibility, model-graph inspection, careful isolation between framework behavior and repository code, and disciplined recovery of adjacent failing tests without regressing the now-green build.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow`
- User-provided status summary:
  - Build succeeds after Swift 6 and Xcode 16.2 compilation fixes.
  - 11 of 13 unit test suites pass.
  - `ChecklistRepositoryTests` crashes with a SwiftData runtime issue.
  - `SafetyRegressionTests` still has 2 failures and needs rebuild verification after the sensitivity-policy fix.
  - `OSAAppLaunchUITests.testAppLaunchesToHomeTab` fails because the tab label assertion no longer matches the navigation structure.
  - The sensitivity-policy phrase-matching fix for phrases such as `gas leak`, `first aid`, and `power line` is already present in code.
- Project governance: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Relevant product and quality docs: `docs/sdlc/02-prd.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Primary code and test surfaces:
  - `OSATests/ChecklistRepositoryTests.swift`
  - `OSA/Persistence/SwiftData/Repositories/SwiftDataChecklistRepository.swift`
  - `OSA/Persistence/SwiftData/Models/PersistedChecklistTemplate.swift`
  - `OSA/Persistence/SwiftData/Models/PersistedChecklistTemplateItem.swift`
  - `OSA/Persistence/SwiftData/Models/PersistedChecklistRun.swift`
  - `OSA/Persistence/SwiftData/Models/PersistedChecklistRunItem.swift`
  - `OSA/Persistence/SwiftData/Models/ChecklistRecordMappings.swift`
  - `OSA/Domain/Checklists/Models/ChecklistTemplate.swift`
  - `OSA/Domain/Checklists/Models/ChecklistRun.swift`
  - `OSA/Domain/Checklists/Repositories/ChecklistRepositories.swift`
  - `OSATests/SafetyRegressionTests.swift`
  - `OSA/Assistant/Policy/SensitivityPolicy.swift`
  - `OSAUITests/OSAAppLaunchUITests.swift`
  - `OSA/App/Navigation/AppTabView.swift`
  - `OSA/App/Navigation/AppTab.swift`

## Assumptions

- The build-success state is valuable and should be preserved; this task is not a reopening of the Swift 6 migration.
- The checklist failure is either caused by a mis-specified SwiftData relationship graph, an unsafe persistence access pattern, or a framework/runtime defect exposed by the current graph and test setup.
- The checklist model graph is small enough to isolate with in-memory `ModelContainer` tests and, if needed, a reduced reproduction.
- The sensitivity-policy fix is likely correct in code and primarily needs clean rebuild and targeted test verification.
- The UI launch failure is probably an assertion drift caused by the navigation restructure rather than a fundamental app-launch defect.
- If the SwiftData crash turns out to be an Apple framework bug, the task still requires a repository-safe mitigation, isolation, and explicit documentation rather than hand-waving.

## Mission Statement

Investigate and resolve the checklist SwiftData runtime crash without regressing the now-green build, then close the remaining safety-policy and UI-launch test failures so the repository returns to a stable, credibly verified state.

## Current State Snapshot

| Surface | Current State | Target State |
| --- | --- | --- |
| Build | Succeeds after Swift 6 / Xcode 16.2 fixes. | Remains green throughout this investigation. |
| `ChecklistRepositoryTests` | Crashes at runtime in SwiftData-backed checklist persistence tests. | Runs reliably without runtime crash and preserves checklist behavior. |
| `SafetyRegressionTests` | Two failures remain after a code-level phrase-matching fix. | Passes after rebuild or any necessary small correctness adjustment. |
| `OSAAppLaunchUITests` | `testAppLaunchesToHomeTab` fails due to tab label mismatch after navigation changes. | Launch assertion matches the real UI contract and passes. |

## Technical Context

The checklist tests exercise an in-memory SwiftData container that includes persisted handbook, quick card, inventory, note, seed-state, checklist-template, and checklist-run models. The checklist persistence graph uses parent-child relationships with cascade delete rules between templates and template items, and between runs and run items. The current repository creates run and item records explicitly and then saves the context. Because the failure is a runtime crash rather than a straightforward assertion failure, the investigation must focus first on reproduction and model-graph validity before making speculative fixes.

The adjacent failures should be handled with strict separation of concerns. The safety-policy bug was already fixed in `SensitivityPolicy.swift`, where phrase-based matching now checks full lowered text for multi-word phrases. That needs targeted verification, not re-design. The UI test appears to be tied to the new tab/navigation structure in `AppTabView.swift`, so the likely work is aligning the test with the actual accessibility or tab-bar contract.

## Pre-Flight Checks

1. Reproduce the exact checklist crash in isolation.
   *Success signal: the runtime crash is triggered with a direct test invocation or a narrowed subset of tests, and the failing path is known.*

2. Identify the precise checklist operation that triggers the crash.
   *Success signal: the investigation can name whether the crash occurs during seed import, template fetch, run creation, relationship mutation, update, delete, or container setup.*

3. Inspect the checklist SwiftData relationship graph and mapping code before changing behavior.
   *Success signal: the investigation can explain the ownership and inverse relationships among templates, template items, runs, and run items.*

4. Confirm the expected current UI tab contract.
   *Success signal: the launch test can be updated based on the actual accessible tab label or a more stable launch assertion.*

5. Confirm the sensitivity-policy regression intent.
   *Success signal: the investigation can show whether the current `SensitivityPolicy` implementation already satisfies the failing cases or still needs a small corrective change.*

## Phased Instructions

### Phase 1: Stabilize Reproduction And Bound The Bug

1. Reproduce `ChecklistRepositoryTests` with the narrowest possible command.
   *Success signal: the crash occurs in a focused invocation rather than only in a full-suite run.*

2. Capture the failing test name, stack trace, and the last repository/model operation executed before the crash.
   *Success signal: the investigation has concrete evidence instead of a generic “SwiftData crashed” description.*

3. Verify whether the crash depends on test order or shared state.
   *Success signal: the investigation knows whether the failure is deterministic in isolation.*

4. Keep all unrelated code paths untouched while isolating the checklist issue.
   *Success signal: no speculative repo-wide churn is introduced during reproduction work.*

### Phase 2: Audit The Checklist SwiftData Graph

1. Inspect `PersistedChecklistTemplate`, `PersistedChecklistTemplateItem`, `PersistedChecklistRun`, and `PersistedChecklistRunItem` for relationship symmetry, ownership, delete rules, optionality, and duplicated foreign-key state.
   *Success signal: the investigation can state whether the graph is internally coherent for SwiftData runtime expectations.*

2. Compare the persisted graph against the domain models and the repository’s create/update/delete flows.
   *Success signal: mismatches between domain assumptions and persisted relationship management are identified or ruled out.*

3. Examine whether storing both scalar IDs and object relationships is causing conflicting source-of-truth behavior.
   *Success signal: the investigation can defend whether fields like `templateID`, `runID`, and optional object relationships are safe as currently modeled.*

4. Inspect `ChecklistRecordMappings.swift` and repository mapping/update code for relationship mutation patterns that SwiftData may reject at runtime.
   *Success signal: any crash-inducing mapping or mutation pattern is isolated to a specific implementation step.*

### Phase 3: Implement The Smallest Reliable Fix

1. Prefer a structural fix to the model graph or repository mutation flow over test-only masking.
   *Success signal: the crash is removed by fixing the real runtime trigger rather than weakening assertions or skipping behavior.*

2. Keep the checklist domain contract unchanged unless the current contract is itself invalid.
   *Success signal: callers still see the same meaningful checklist behavior after the fix.*

3. If the root cause is a SwiftData framework limitation, implement the narrowest safe workaround.
   *Success signal: the repository remains correct and testable even if the underlying issue is framework-specific.*

4. Add or refine focused regression coverage if the crash can be expressed as a deterministic scenario.
   *Success signal: the fixed behavior is protected by a stable test rather than only by a manual claim.*

### Phase 4: Recover Adjacent Test Regressions Without Scope Creep

1. Re-run `SafetyRegressionTests` after the checklist fix or rebuild.
   *Success signal: the existing phrase-matching fix is verified, or any remaining defect is corrected with a minimal policy change.*

2. Update `OSAAppLaunchUITests` to assert the correct and stable launch behavior after the tab/navigation restructure.
   *Success signal: the UI test checks the real launch contract instead of a stale label assumption.*

3. Keep the UI-test repair limited to contract alignment.
   *Success signal: no unnecessary navigation redesign or view churn is introduced just to satisfy the test.*

### Phase 5: Verify And Report Conservatively

1. Run the smallest relevant build and test commands needed to prove the fix.
   *Success signal: the report includes actual commands and outcomes rather than generalized confidence.*

2. Distinguish measured outcomes from interpretation.
   *Success signal: the report states exactly what passed, what was not run, and what remains unverified.*

3. If any part remains blocked by a probable Apple bug, package that clearly.
   *Success signal: the report includes a reduced reproduction path, observed behavior, and the mitigation that keeps the repository workable.*

## Investigation Hints

- Pay special attention to the combination of explicit UUID foreign-key fields and optional object relationships in the checklist models.
- Review whether child records are inserted before or after their parent relationships are fully established.
- Check whether inverse relationships are being relied on implicitly when the repository already stores scalar IDs.
- Verify whether `includePendingChanges` or fetch-and-filter patterns are interacting badly with newly inserted records.
- If necessary, reduce the issue to a minimal in-memory SwiftData model test before making broader repository changes.

## Guardrails

- Do not reopen the completed Swift 6 migration work unless the checklist fix strictly requires it.
- Do not skip or disable the crashing checklist tests as the primary resolution.
- Do not “fix” the issue by removing meaningful persistence behavior from checklists.
- Do not conflate the SwiftData crash with the safety-policy or UI-test cleanup; keep causes and fixes separate.
- Do not fabricate framework-bug claims without a concrete reproduction path and ruled-out app-level causes.
- Do not widen the task into unrelated architecture, networking, import, or assistant-scope changes.

## Acceptance Criteria

- [ ] `ChecklistRepositoryTests` no longer crashes at runtime.
- [ ] The checklist repository still supports template listing, template lookup, run creation, run updates, run deletion, and active/completed run queries.
- [ ] The root cause of the crash is explained in app-code terms, even if the underlying trigger involves SwiftData runtime behavior.
- [ ] `SafetyRegressionTests` passes, or any remaining failure is explained with exact evidence.
- [ ] `OSAAppLaunchUITests.testAppLaunchesToHomeTab` passes with an assertion that matches the current navigation contract.
- [ ] Build and relevant tests are re-run and reported precisely.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| Checklist crash cannot be reproduced consistently | Isolate with direct test invocation, reduce shared state, and determine whether order dependence exists before editing models. |
| Relationship graph appears valid but SwiftData still crashes | Build a minimal reproduction around the exact graph shape and apply the narrowest repository-safe workaround. |
| Proposed fix requires removing needed cascade or ownership semantics | Rework mutation order or graph declarations rather than degrading required checklist behavior. |
| Safety regression still fails after rebuild | Inspect the specific failing phrase cases and adjust the policy only where the tested contract and app safety posture require it. |
| UI launch assertion still fails after label update | Assert a more stable launch indicator tied to the real home surface or accessibility contract. |
| Full verification tooling is unavailable | Report the exact command blocker and keep the affected claims unverified. |

## Out Of Scope

- New checklist features or schema expansion unrelated to the crash.
- M4 networking, import, retrieval, or online knowledge work.
- Broad navigation redesign beyond aligning the launch test with the current app structure.
- Rewriting safety policy beyond what is required to satisfy the already-intended multi-word phrase behavior.

## Report Format

When the work is complete, report back in this structure:

1. Root cause of the checklist crash.
2. Files changed and why each change was necessary.
3. Checklist runtime fix and any model-graph or repository behavior changes.
4. Safety regression verification result.
5. UI launch test fix.
6. Build and test commands run with outcomes.
7. Remaining risks, blocked verification, or suspected framework issues.
