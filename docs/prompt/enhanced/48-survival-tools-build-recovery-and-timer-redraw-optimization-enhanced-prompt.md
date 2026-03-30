Developer: # Repair Survival Tools Build Breakage And Timer Redraw Invalidation

**Date:** 2026-03-30
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Fix/Debug
**Complexity Classification:** Moderate
**Complexity Justification:** The task is tightly bounded to the Survival Tools screen and its existing UI verification path, but it still requires preserving a structural syntax repair, rerunning the end-to-end visual suite, and implementing a performance-safe timer refresh strategy that may touch 2-5 Swift files plus focused verification.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt and user-provided status summary | The immediate problem was an `xcodebuild` build failure caused by stray braces in `SurvivalToolsScreen.swift`; that structural repair is already understood, the full `OSAFullE2EVisualTests` suite reportedly passed afterward, and a new redraw or invalidation bug was then identified in the timer implementation. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Preserve offline-first behavior, keep changes proportional, verify claims with concrete commands, and prefer the smallest coherent fix over broad redesign. |
| `docs/sdlc/05-technical-architecture.md` | `Tools` belongs in `OSA/Features/Tools/`; feature views should stay presentation-focused and avoid unnecessary persistence or networking changes. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | `OSAFullE2EVisualTests` is the current end-to-end visual regression seam, and Sprint 4 already established Tools-screen assertions for Morse, timer, converter, and declination content. |
| `OSA/Features/Tools/SurvivalToolsScreen.swift` | The current screen is large and now owns a root-level `@State private var currentTick = Date()` plus a `.onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect())`, which invalidates the entire screen five times per second while timing is active. |
| `OSAUITests/OSAFullE2EVisualTests.swift` | The dedicated UI suite currently includes `testToolsScreen` and totals 16 end-to-end visual tests across Home, Library, Ask, Inventory, Checklists, Quick Cards, Tools, Notes, and Settings surfaces. |
| `docs/prompt/enhanced/39-sprint-4-survival-tools-and-communication-utilities-enhanced-prompt.md` | Survival Tools is already a bounded offline utility surface with explicit limitations; this fix should optimize the existing timer implementation, not redesign the feature. |

## Assumptions

- The stray-brace repair in `OSA/Features/Tools/SurvivalToolsScreen.swift` is already correct and must be preserved rather than reworked.
- The current redraw problem is real because the ticking state lives on the root `SurvivalToolsScreen` view, which forces unrelated sections such as the hero card, Morse controls, radio reference, and declination content to recompute every 0.2 seconds while the timer runs.
- The preferred fix is to use `TimelineView(.periodic(from:by:))` for the timer display, ideally inside a dedicated child view so refresh scope is explicit and local.
- If `TimelineView` does not preserve the exact stopwatch or countdown behavior cleanly, a dedicated `TimerToolCardView` with local timer state is an acceptable fallback, but the ticking state must not remain on the root `SurvivalToolsScreen` type.
- Full Xcode may or may not be available locally; if `xcodebuild` cannot run, verification must be reported as `unverified` with the exact blocker.

## Mission Statement

Preserve the repaired `SurvivalToolsScreen` structure, reverify the 16-test end-to-end visual suite, and eliminate the root-level timer-driven redraw bug by isolating timer refreshes to the smallest possible Survival Tools subview.

&lt;technical_context&gt;

## Technical Context

The current issue is two-part, but the parts are not equal.

First, the earlier build break was structural: an extra closing brace split `SurvivalToolsScreen` so static properties and related members escaped to top-level scope. That prevented `xcodebuild` from compiling the app. The user already identified and repaired that syntax problem. This prompt must preserve that repair and treat it as a regression boundary, not as an open investigation.

Second, the current performance problem is architectural inside the view layer. `SurvivalToolsScreen.swift` is a large SwiftUI screen that renders multiple sections: hero messaging, Morse signaling, bright-screen tools, whistle playback, timer or stopwatch controls, converter, radio reference, and declination. The screen now owns both:

- a root-level ticking state value: `@State private var currentTick = Date()`
- a root-level timer publisher: `.onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect())`

That means starting the stopwatch or countdown invalidates the whole view tree five times per second. The timer text does need periodic updates. The rest of the screen does not. On iOS 18, `TimelineView(.periodic(from:by:))` is the native SwiftUI mechanism for this exact job because it localizes periodic redraws to the view subtree that actually depends on time.

The smallest correct shape is:

1. keep `SurvivalToolsScreen` as the parent composition surface for sections
2. move timer-specific ticking behavior into a dedicated child view or timer card
3. use `TimelineView` for the displayed time value when possible
4. keep countdown-completion and haptic behavior correct without reintroducing screen-wide ticking state

Why this approach is correct:

- It fixes the actual invalidation scope rather than masking symptoms.
- It keeps the feature in `OSA/Features/Tools/` and does not widen into persistence, notifications, Live Activities, or background execution.
- It preserves the existing Tools-screen contract already covered by `OSAUITests/OSAFullE2EVisualTests.swift`.
- It reduces the cost of future maintenance on a file that has already grown large enough to hide structural mistakes.

The E2E visual suite is already the right regression seam. `testToolsScreen` verifies the presence of `Morse Signal`, `Timer / Stopwatch`, `Unit Converter`, and `Declination`, while the rest of `OSAFullE2EVisualTests` exercises the app-wide navigation path that previously exposed the build failure.

&lt;/technical_context&gt;

## Root Cause Analysis

**Hypothesis 1:** The original build failure was caused by a structural brace mismatch in `SurvivalToolsScreen.swift`.

- Investigation: Inspect the view boundary near the end of `SurvivalToolsScreen` and confirm that `private static` members remain inside the type and `private extension SurvivalToolsScreen` begins only after the struct closes.
- Evidence needed: `xcodebuild` compiles the app and there are no top-level orphaned members or parser errors.

**Hypothesis 2:** The current redraw bug is caused by root-level timer state on `SurvivalToolsScreen`.

- Investigation: Confirm that `currentTick` and the 0.2-second publisher are owned by the root screen rather than by a timer-only child view.
- Evidence needed: The current file shows the root `@State` tick value and root `.onReceive`, and the final fix removes that ownership from the parent screen.

**Hypothesis 3:** The timer functionality can be preserved while limiting invalidation scope.

- Investigation: Implement a localized timer display using `TimelineView` or a dedicated child component, then re-run build and UI verification.
- Evidence needed: Timer and countdown controls still render and behave correctly, while the parent screen no longer owns a 5 Hz ticking state.

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Build reliability | `SurvivalToolsScreen.swift` previously failed to compile when stray braces split the view type. | The repaired structure remains intact and `xcodebuild` succeeds. |
| E2E visual coverage | The correct regression suite exists in `OSAUITests/OSAFullE2EVisualTests.swift`, and the user reported a passing 16-test run after the syntax fix. | The same suite is rerun after the timer optimization and remains green. |
| Timer invalidation scope | The root `SurvivalToolsScreen` owns ticking state and a 0.2-second timer publisher, invalidating the entire screen while timing is active. | Only the timer display subtree refreshes periodically; unrelated sections do not depend on ticking state. |
| Feature boundaries | The timer logic currently lives inside a very large screen type. | The timer implementation is isolated to the smallest coherent view boundary without redesigning other tool cards. |

&lt;pre_flight_checks&gt;

## Pre-Flight Checks

1. Verify repository root and standard build target.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && pwd
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
```

*Success: commands are running from the OSA workspace root.*

1. Verify full Xcode availability before promising build or UI-test verification.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success: `xcodebuild` verification is available, or the exact blocker is known before implementation starts.*

1. Confirm the relevant files exist.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Features/Tools/SurvivalToolsScreen.swift && test -f OSAUITests/OSAFullE2EVisualTests.swift && echo "survival tools surfaces present"
# Expected: survival tools surfaces present
```

*Success: the owning screen and the E2E visual suite are both present.*

1. Inspect the current timer coupling on the root screen.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && rg --line-number "@State private var currentTick|Timer.publish\(every: 0\.2|onReceive\(" OSA/Features/Tools/SurvivalToolsScreen.swift
# Expected before the fix: matches showing root-level ticking state and publisher ownership
```

*Success: the current invalidation path is identified in concrete code before editing begins.*

1. Inspect the structural boundary near the end of `SurvivalToolsScreen`.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && sed -n '500,610p' OSA/Features/Tools/SurvivalToolsScreen.swift
```

*Success: the file shows one contiguous `SurvivalToolsScreen` definition followed by `private extension SurvivalToolsScreen`, not a split type.*

1. Confirm the target E2E suite shape.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && rg --line-number "@MainActor func test" OSAUITests/OSAFullE2EVisualTests.swift
```

*Success: the suite clearly covers the expected end-to-end surfaces, including `testToolsScreen`.*

&lt;/pre_flight_checks&gt;

## Phased Instructions

### Phase 1: Preserve The Structural Build Fix

1. Treat the stray-brace repair in `OSA/Features/Tools/SurvivalToolsScreen.swift` as a must-keep regression boundary.
   Do not reopen the file structure beyond what is needed to isolate timer updates.

   *Success: the screen still defines one valid SwiftUI view type and the `private extension SurvivalToolsScreen` remains correctly nested after the struct closes.*

2. Confirm the current root-level redraw trigger before implementing the optimization.
   Name the exact screen-level state and publisher that force the whole screen to recompute while timing is active.

   *Success: the investigation can point to the parent-owned 0.2-second tick path in code, not just a generic “SwiftUI is redrawing too much” claim.*

### Phase 2: Localize Timer Refreshes

1. Choose the smallest coherent isolation seam for the timer UI.
   Preferred: create `OSA/Features/Tools/TimerToolCardView.swift` and move timer-specific state and rendering there.
   Acceptable fallback: extract a private child view inside `SurvivalToolsScreen.swift` if a new file would be unjustified.

   *Success: the timer UI has its own bounded view boundary, and `SurvivalToolsScreen` no longer owns periodic refresh state.*

2. Replace the root-level timer publisher with `TimelineView(.periodic(from:by:))` for the displayed elapsed or remaining time when practical.
   Use the timeline only for the subtree that renders the timer text, not the full tools screen.

   *Success: periodic refresh is scoped to the timer display instead of the entire screen.*

3. Remove the root `@State private var currentTick` and the root `.onReceive(Timer.publish(...))` from `OSA/Features/Tools/SurvivalToolsScreen.swift`.
   The parent screen may still own stable timer configuration or paused state if needed, but it must not own the 5 Hz ticking driver.

   *Success: the parent screen no longer has a ticking `@State` or 0.2-second timer publisher.*

4. Preserve existing timer behavior.
   Keep the current stopwatch and countdown modes, the 1 / 5 / 15 / 30 minute presets, start or pause or reset controls, countdown completion semantics, and one-time success haptic behavior when the countdown finishes.

   *Success: the user-facing timer contract matches the current screen while using a more localized refresh path.*

5. If the chosen implementation introduces a pure timing helper or model type, add focused unit coverage for that logic.
   Do not invent a new abstraction solely for testing.

   *Success: any newly extracted pure logic is protected by a small, relevant test instead of only by manual confidence.*

6. Remove any temporary helper files created only for one-off edits before final verification.

   *Success: the final change set contains product code, tests, and documentation only if they are part of the actual fix.*

### Phase 3: Reverify Build And End-To-End Visual Coverage

1. Run a simulator build after the timer optimization.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: ** BUILD SUCCEEDED **
```

*Success: the previously repaired build remains green after the timer refactor.*

1. Re-run the full E2E visual suite.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSAUITests/OSAFullE2EVisualTests
# Expected: Executed 16 tests, with 0 failures
```

*Success: the same end-to-end navigation and Tools-screen assertions still pass after the optimization.*

1. If you added a focused timing unit test, run it explicitly.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/SurvivalToolKitTests
```

*Success: any touched or added timing logic has direct automated verification, or you explicitly report why no unit-testable seam was introduced.*

1. Run a static guard check that the parent screen no longer owns the ticking refresh path.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && rg --line-number "@State private var currentTick|Timer.publish\(every: 0\.2|onReceive\(" OSA/Features/Tools/SurvivalToolsScreen.swift
# Expected after the fix: no match for a root-level ticking state or 0.2-second timer publisher on SurvivalToolsScreen
```

*Success: the static code shape proves the parent screen is no longer the periodic refresh owner.*

1. Perform one manual functional spot-check on the Tools timer.
   Launch the app, open `More -> Tools`, start the stopwatch, then start a countdown preset and observe that the timer text updates while unrelated cards remain visually stable.

   *Success: timer controls still work and the optimization claim stays bounded to the observed scope reduction rather than overclaiming global performance gains.*

### Phase 4: Security And Quality Hygiene

1. Run first-party security scanning if `snyk` is available.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
```

*Success: Snyk Code completes successfully, or the exact environment blocker is reported as `unverified`.*

1. Keep the report conservative.
   Separate build recovery facts, E2E verification facts, and the redraw-optimization claim. Do not present the optimization as benchmarked if you only proved it through code structure and manual observation.

   *Success: the final report distinguishes measured results from inferred performance improvements.*

&lt;guardrails&gt;

## Guardrails

- Do not redesign Morse, whistle, converter, radio-reference, or declination behavior.
- Do not add notifications, Live Activities, background timers, or persistence for the stopwatch or countdown.
- Do not move SwiftData, networking, or assistant logic into this task.
- Do not keep a 0.2-second ticking `@State` on the root `SurvivalToolsScreen` type.
- Prefer the smallest coherent extraction. Do not split the entire Tools screen into many files unless the timer isolation work truly requires it.
- Do not weaken `OSAFullE2EVisualTests` assertions just to make the suite pass.
- Do not add new dependencies.
- Do not revert unrelated user changes in the worktree.

&lt;/guardrails&gt;

&lt;verification&gt;

## Verification Checklist

- [ ] `SurvivalToolsScreen.swift` remains structurally valid and compiles.
- [ ] The root `SurvivalToolsScreen` no longer owns `currentTick` or a 0.2-second timer publisher.
- [ ] Timer updates are localized to a dedicated child view or timer card.
- [ ] Stopwatch and countdown behavior still work with the existing presets and completion semantics.
- [ ] `xcodebuild ... build` succeeds.
- [ ] `xcodebuild ... test -only-testing:OSAUITests/OSAFullE2EVisualTests` passes.
- [ ] The Tools screen still exposes `Morse Signal`, `Timer / Stopwatch`, `Unit Converter`, and `Declination` content to UI automation.
- [ ] Any new pure timing helper is covered by a focused unit test, or the report explains why no new pure seam was introduced.
- [ ] `snyk code test --path="$PWD"` was run or explicitly reported as blocked.
- [ ] The final report clearly separates user-provided prior pass results from newly rerun verification.

&lt;/verification&gt;

&lt;error_handling&gt;

## Error Handling Table

| Error | Resolution |
| --- | --- |
| `xcodebuild` cannot run because full Xcode is unavailable | Report the exact `xcode-select -p` output or error and keep build or UI-test verification `unverified`. |
| `TimelineView` complicates countdown completion logic | Keep `TimelineView` for display updates, but move countdown state and completion gating into a dedicated timer child view rather than falling back to root-screen ticking state. |
| Countdown completion fires repeatedly | Gate completion on state transition or a completion flag, then re-run focused verification before expanding scope. |
| E2E suite flakes because the simulator is not ready | Re-run once after confirming the named simulator destination exists; do not relax assertions or delete tests. |
| Parent-screen redraw claim cannot be benchmarked precisely | Report the bounded proof you do have: root screen no longer owns periodic refresh state, build and E2E tests passed, and manual observation showed timer-only updates. |
| Structural compile errors reappear in `SurvivalToolsScreen.swift` | Reinspect brace balance around the end of the struct and the start of `private extension SurvivalToolsScreen` before attempting broader changes. |

&lt;/error_handling&gt;

&lt;out_of_scope&gt;

## Out Of Scope

- Redesigning the rest of the Survival Tools screen.
- Broad file decomposition unrelated to the timer invalidation path.
- New timer features such as background alerts, notifications, widgets, or persistence.
- Changes to app navigation, Emergency Mode flows, or other tab surfaces beyond what is required for verification.
- Removing unrelated local worktree changes.

&lt;/out_of_scope&gt;

&lt;alternative_solutions&gt;

## Alternative Solutions

1. **Preferred:** dedicated `TimerToolCardView` plus `TimelineView(.periodic(from:by:))` for the displayed time.
   - Pros: clearest refresh isolation, native SwiftUI approach, easier to reason about invalidation scope.
   - Cons: may require moving some timer-specific logic out of the existing file.

2. **Fallback A:** dedicated child timer view with local `@State` and a local publisher if `TimelineView` cannot preserve the required semantics cleanly.
   - Pros: still isolates invalidation away from the root screen.
   - Cons: less idiomatic than `TimelineView` and easier to misuse.

3. **Fallback B:** private nested child view inside `SurvivalToolsScreen.swift` rather than a new file.
   - Pros: smallest diff if the file boundary is the only concern.
   - Cons: keeps the file large and lessens the maintainability gain.

Unacceptable solution:

- Leaving the 0.2-second ticking `@State` on the root `SurvivalToolsScreen` and merely tweaking the timer math.

&lt;/alternative_solutions&gt;

&lt;report_format&gt;

## Report Format

When the work is complete, report back in this structure:

1. Build-recovery confirmation.
2. Root cause of the redraw or invalidation bug.
3. Solution chosen and why it was selected over the alternatives.
4. Files changed and why each change was necessary.
5. Build and test commands run with outcomes.
6. Performance evidence and the exact scope of the claim.
7. Any blockers, unverified checks, or remaining risks.

&lt;/report_format&gt;
