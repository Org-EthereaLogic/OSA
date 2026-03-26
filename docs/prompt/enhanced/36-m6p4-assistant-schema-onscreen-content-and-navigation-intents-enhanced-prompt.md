# Milestone 6 Phase 4 AssistantSchema, Onscreen Content, And Navigation Intents Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** M6P4 crosses Apple Intelligence system-surface integration, App Intents schema metadata, app-owned deep-link navigation state, on-screen context publishing, and focused verification. It must stay narrow and reuse the existing grounded retrieval and App Entity layers rather than creating a second assistant or navigation stack.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | Milestones 1 through 5 are complete, M6P1 through M6P3 are complete, and the next unblocked slice is M6P4. |
| User brief | The recommended next step is `AssistantSchema` plus on-screen content, with navigation intents for quick cards and handbook sections to complete the Siri story before M6P5 and device-only RC work. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, keep the app offline-first and grounded, preserve privacy boundaries, avoid speculative abstraction, and report blocked verification as `unverified`. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M6P4 is explicitly defined as `AssistantSchema` conformance for `AskLanternIntent`, on-screen content exposure for handbook and quick-card reading, and `OpenQuickCardIntent` plus `OpenHandbookSectionIntent` for deep-linking from Siri results. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | The app shell is tab-based with Library, Ask, and Quick Cards surfaces already first-class; stress-state UX favors direct card opening and clear local/offline cues. |
| `docs/sdlc/05-technical-architecture.md` | `App/Intents/` is already the correct home for Siri-facing surfaces, `SharedRuntime` already supports non-SwiftUI entry points, and the boundary discipline matters more than adding targets. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Siri remains only another entry point into grounded local retrieval. No live-web answers, no uncited substantive prose, and no model-prior-only behavior are allowed. |
| `docs/sdlc/10-security-privacy-and-safety.md` | System surfaces must not widen private-data exposure. Inventory notes, personal notes, and imported-knowledge detail should not be pushed into on-screen system context in this phase. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | New assistant-adjacent code requires focused tests plus explicit build or test evidence. Device-only Siri validation must be reported separately if unavailable locally. |
| `docs/adr/ADR-0002-grounded-assistant-only.md` | The assistant is a bounded, grounded assistant only. M6P4 must preserve that contract while improving Siri semantic understanding and navigation. |
| `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md` | The target remains iOS 18 with capability-based behavior on supported hardware. M6P4 should not change the deployment target or add a remote model dependency. |
| `OSA/App/Intents/AskLanternIntent.swift` | `AskLanternIntent` already routes through `SharedRuntime.dependencies.retrievalService` and must remain the single Siri question-answering path. |
| `OSA/App/Intents/LanternAppShortcutsProvider.swift` | Shortcut registration already exists and is the right place to add the new deep-link shortcuts once the navigation intents exist. |
| `OSA/App/Intents/Entities/HandbookSectionEntity.swift` and `OSA/App/Intents/Entities/QuickCardEntity.swift` | M6P2 already provides the entity layer needed for parameterized navigation intents. M6P4 should reuse these types instead of inventing new identifiers or lookup models. |
| `OSA/App/Navigation/AppTabView.swift` | The current tab selection is local `@State`, which is sufficient for taps inside the app but not for App Intent-triggered navigation requests. |
| `OSA/Features/Ask/AskScreen.swift` | Ask already deep-links to `QuickCardRouteView` and `HandbookSectionDetailView`, confirming those views are the correct content destinations for Siri follow-through. |
| `OSA/Features/QuickCards/QuickCardRouteView.swift` and `OSA/Features/Library/HandbookSectionDetailView.swift` | These are the current reading surfaces for quick cards and handbook sections and are the narrowest places to publish current on-screen content. |
| `OSATests/AskLanternIntentExecutorTests.swift` and `OSATests/AppEntityQueryTests.swift` | Existing test style favors focused, narrow XCTest coverage using stub dependencies and coordinator-style seams rather than UI-heavy end-to-end tests for system surfaces. |
| `docs/prompt/enhanced/33-m6p1-app-intents-foundation-enhanced-prompt.md`, `34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md`, `35-m6p3-fm-powered-inventory-completion-enhanced-prompt.md` | The current M6 prompt series is phase-scoped, explicit about file paths and commands, and intentionally narrow about what each slice should not absorb. |

## Classification Summary

- Core intent: complete the next Apple Intelligence slice by giving Siri a semantically richer `AskLanternIntent`, adding app-intent deep links for quick cards and handbook sections, and exposing the currently viewed quick card or handbook section as app-owned on-screen context.
- In scope: `AskLanternIntent` schema metadata, `OpenQuickCardIntent`, `OpenHandbookSectionIntent`, one app-owned navigation coordination seam, one app-owned on-screen-content state seam, focused app-shell wiring, focused tests, and evidence-backed verification.
- Out of scope: changes to retrieval ranking, Ask answer formatting, imported-knowledge discovery, note or inventory system-surface exposure, broad navigation redesign, widgets, App Clips, live-web answers, or dependency changes.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- New source files under `OSA/` and new test files under `OSATests/` are already included by the current project source globs unless project generation proves otherwise.
- Apple may have renamed or version-gated the exact `AssistantSchema` and on-screen content symbols in the installed SDK, so implementation must confirm the real types before coding against them.
- M6P4 should expose only handbook-section and quick-card on-screen context, not inventory items, notes, checklist runs, or imported knowledge, to keep scope and privacy boundaries tight.
- Simulator and headless test environments may compile App Intents code without proving Siri semantic behavior end to end. If so, the Siri behavior claim remains `unverified` until device-backed validation occurs.
- If `xcode-select -p` points at Command Line Tools rather than full Xcode, build or test verification must be reported as `unverified` with the exact blocker.

## Mission Statement

Implement M6P4 by extending the existing Siri surface with AssistantSchema-aware `AskLanternIntent` metadata, deep-link navigation intents for quick cards and handbook sections, and app-owned on-screen content publication for the currently viewed quick card or handbook section, while preserving OSA's grounded, offline-first, and privacy-bounded behavior.

## Technical Context

OSA already has the two hard prerequisites for this phase. First, `AskLanternIntent` exists and already reuses the live `LocalRetrievalService` chain through `SharedRuntime`, so M6P4 does not need a new assistant path. Second, M6P2 already established `QuickCardEntity` and `HandbookSectionEntity`, so M6P4 does not need a new semantic object model for deep-link parameters.

The real work in M6P4 is system-surface coordination. Today, `AppTabView` keeps its tab selection as local view state, and route-specific content lives in feature views. That is enough for in-app taps, but not for an App Intent that needs to open the app, select the right surface, and land on a specific quick card or handbook section. The smallest coherent change is to add one app-owned navigation coordinator that the app shell can observe and App Intents can write to through `SharedRuntime`.

The same pattern applies to on-screen content. The product requirement is not to let Siri inspect arbitrary view hierarchies. It is to expose the app's current reading context in a controlled, privacy-bounded way so follow-up questions about the visible quick card or handbook section can remain grounded. The narrowest safe design is to publish lightweight context from `QuickCardRouteView` and `HandbookSectionDetailView` through one app-owned manager that can optionally bridge to Apple's on-screen-content API when the exact SDK surface is confirmed.

Three guardrails matter throughout this phase:

1. Do not create a second retrieval path. `AskLanternIntent.perform()` must continue to use the existing executor and retrieval service.
2. Do not widen system-surface exposure beyond handbook sections and quick cards in this phase.
3. Do not guess Apple API names. Confirm the installed SDK symbols first, then adapt the code to those exact types with availability guards where required.

The preferred implementation shape is:

- one shared app-navigation coordinator under `OSA/App/Navigation/`
- one shared on-screen-content manager under `OSA/App/Intents/` or another app-owned seam
- one schema-aware extension of `AskLanternIntent`
- two focused navigation intents using existing `AppEntity` types
- one update to shortcut registration
- two focused test files proving coordinator and intent behavior without inventing a larger architecture

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Siri question semantics | `AskLanternIntent` exists, but only as a thin `AppIntent` with no schema-specific semantic metadata. | Siri can understand `AskLanternIntent` through the platform's current AssistantSchema/search schema surface without changing the grounded retrieval path. |
| Deep-link actions from Siri | Siri can resolve quick cards and handbook sections as entities, but there are no intents that open those entities inside the app. | `OpenQuickCardIntent` and `OpenHandbookSectionIntent` open the app and route to the correct destination using existing entities. |
| App shell navigation ownership | `AppTabView` stores selected tab in local `@State`, which App Intents cannot control safely. | An app-owned navigation coordinator mediates tab selection and one-shot deep-link requests from App Intents into the UI. |
| On-screen reading context | No app-owned state describes the currently visible quick card or handbook section for Siri follow-up. | A focused manager publishes the currently displayed quick card or handbook section and clears stale context when the user leaves. |
| Privacy on system surfaces | The app has privacy-bounded entity exposure, but no explicit rule for on-screen content publication. | Only handbook-section and quick-card context is published in this phase; notes, inventory notes, checklist runs, and imported knowledge remain out of scope. |
| Verification | M6P1 and M6P2 tests exist, but there is no test coverage for deep-link intent routing or on-screen context state. | Focused tests cover coordinator routing, deep-link intent handoff, and on-screen context publication and clearing. |

## Pre-Flight Checks

1. Verify the repository root and the concrete M6P4 seams.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
pwd
test -f OSA/App/Intents/AskLanternIntent.swift \
  && test -f OSA/App/Intents/LanternAppShortcutsProvider.swift \
  && test -f OSA/App/Intents/Entities/QuickCardEntity.swift \
  && test -f OSA/App/Intents/Entities/HandbookSectionEntity.swift \
  && test -f OSA/App/Navigation/AppTabView.swift \
  && test -f OSA/Features/QuickCards/QuickCardRouteView.swift \
  && test -f OSA/Features/Library/HandbookSectionDetailView.swift \
  && echo "m6p4 surfaces present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: m6p4 surfaces present
```

*Success signal: the existing App Intents, entity, app-shell, and content-route seams are present before implementation starts.*

1. Confirm the exact Apple SDK symbols for `AssistantSchema` and the on-screen content API before writing code against them.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
SDK_ROOT="$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  && rg -n "AssistantSchema|onscreen|Onscreen|ScreenContent" "$SDK_ROOT/System/Library/Frameworks" -g '*.swiftinterface'
# Expected: at least one match showing the real type names or modules available in the installed SDK
```

*Success signal: you have the installed SDK's real symbols or you have explicit evidence that the API is unavailable in this environment.*

1. Confirm that app-driven navigation is still local to the app shell and Ask screen.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
rg -n "@State private var selectedTab|navigationDestination\(for: AskDestination" OSA/App/Navigation/AppTabView.swift OSA/Features/Ask/AskScreen.swift
# Expected: AppTabView owns local selectedTab; AskScreen owns AskDestination-based navigation inside Ask only
```

*Success signal: the current state confirms why a shared navigation handoff seam is needed for App Intent deep links.*

## Instructions

### Phase 1: Investigation And API Confirmation

1. **Inspect the installed SDK and record the exact symbol names for the Assistant schema and on-screen content APIs.**

   Use the pre-flight `rg` command to identify the real Apple types, protocols, modules, availability annotations, and any required imports. Save those exact names in the working notes or implementation comments only if needed for clarity.

   *Success signal: the implementation plan references real SDK symbols from the installed toolchain instead of guessed names.*

2. **Read the current Siri and routing seams before editing.**

   Inspect these files in full before implementation:
   `OSA/App/Intents/AskLanternIntent.swift`
   `OSA/App/Intents/LanternAppShortcutsProvider.swift`
   `OSA/App/Intents/Entities/QuickCardEntity.swift`
   `OSA/App/Intents/Entities/HandbookSectionEntity.swift`
   `OSA/App/Navigation/AppTabView.swift`
   `OSA/Features/Ask/AskScreen.swift`
   `OSA/Features/QuickCards/QuickCardRouteView.swift`
   `OSA/Features/Library/HandbookSectionDetailView.swift`

   *Success signal: the implementation uses existing entity, route, and bootstrap seams rather than inventing parallel ones.*

### Phase 2: Implementation

1. **Create one app-owned navigation coordinator for App Intent handoff.**

   Add `OSA/App/Navigation/AppNavigationCoordinator.swift` as the single place that owns selected app tab state, one-shot deep-link requests for quick cards and handbook sections, and simple methods such as `openQuickCard(id:)`, `openHandbookSection(id:)`, and `consumePendingRoute()`.

   Keep it app-owned and UI-facing. Do not put repositories, retrieval logic, or SwiftData in this coordinator.

   *Success signal: App Intents can request navigation without directly reaching into SwiftUI view-local state.*

1. **Update the app shell to use the coordinator instead of local-only tab state.**

   Modify `OSA/App/Bootstrap/OSAApp.swift` and `OSA/App/Navigation/AppTabView.swift`.

   Replace `AppTabView`'s local `@State private var selectedTab` with coordinator-backed state injected from `OSAApp`. Keep the visible tab structure unchanged. Route deep-link requests through the existing quick-card and handbook-detail surfaces rather than creating duplicate destination views.

   **Rationale:** M6P4 needs App Intents to open the app and drive the existing UI, not bypass it.

   *Success signal: tab selection and route handoff are driven by one shared coordinator, while the app's visible navigation model stays the same.*

1. **Add one app-owned on-screen-content manager for currently viewed reading content.**

   Add `OSA/App/Intents/OnscreenContentManager.swift` to represent the current visible content as a narrow enum or value type limited to quick card id, title, and category, plus handbook section id, heading, and chapter title.

   The manager may optionally bridge to Apple's on-screen-content API using the exact symbols confirmed in Phase 1. If the API is unavailable in the installed SDK, keep the manager app-owned and availability-guarded rather than fabricating unsupported integrations.

   *Success signal: the app has a single, privacy-bounded source of truth for visible quick-card and handbook-section context.*

1. **Publish and clear on-screen context from the current reading surfaces.**

   Modify `OSA/Features/QuickCards/QuickCardRouteView.swift` and `OSA/Features/Library/HandbookSectionDetailView.swift`.

   When content successfully loads, publish the current context through `OnscreenContentManager`. Clear or replace stale context when the view disappears or the content fails to load. Do not publish note bodies, inventory notes, checklist runs, or imported-knowledge content in this phase.

   *Success signal: opening a quick card or handbook section updates the on-screen-content manager with the correct lightweight context and removes stale entries when appropriate.*

1. **Extend `AskLanternIntent` with AssistantSchema/search-schema metadata using the installed SDK's real API surface.**

   Update `OSA/App/Intents/AskLanternIntent.swift` or add `OSA/App/Intents/AskLanternIntent+Schema.swift` if a separate extension keeps the file cleaner. The schema work must describe the existing intent semantically for Siri while preserving the current `perform()` behavior and the current executor path.

   Do not add a second retrieval path, do not call repositories directly from the schema layer, and do not weaken the citation or refusal contract.

   *Success signal: `AskLanternIntent` remains the only Siri question-answering entry point and now carries the platform's schema metadata using real SDK types.*

1. **Add deep-link intents for quick cards and handbook sections using existing App Entities.**

   Create `OSA/App/Intents/OpenQuickCardIntent.swift` and `OSA/App/Intents/OpenHandbookSectionIntent.swift`.

   Each intent should accept the corresponding existing entity type as its parameter, set `openAppWhenRun` to `true`, hand off to `AppNavigationCoordinator` through an app-owned seam such as `SharedRuntime`, and return a short dialog that confirms the content being opened.

   Do not add a second lookup layer or bypass the entity system already built in M6P2.

   *Success signal: Siri and Shortcuts can request opening a specific quick card or handbook section by entity identity.*

1. **Register the new deep-link intents in the shortcut provider without bloating shortcut phrasing.**

   Modify `OSA/App/Intents/LanternAppShortcutsProvider.swift` to keep the existing Ask shortcut and add concise shortcuts for the new open intents. Favor phrases that mirror the product language already in the app, such as opening a quick card or handbook section.

   *Success signal: the shortcut provider exposes one ask shortcut plus the two new navigation shortcuts with concise discoverable phrases.*

1. **Keep the Apple-specific API integration availability-safe and fallback-safe.**

    Any new Assistant schema or on-screen-content API usage must be written with the exact availability and import guards required by the installed SDK. If the API is absent or renamed in the toolchain, implement the app-owned coordinator and on-screen manager first, gate Apple-specific integration behind availability, and report the exact blocker rather than inventing substitute behavior.

    *Success signal: the code compiles cleanly or produces a precise, documented Apple-SDK blocker instead of relying on guessed API names.*

### Phase 3: Verification

1. **Add focused tests for navigation handoff and on-screen context state.**

   Create `OSATests/NavigationIntentTests.swift` and `OSATests/OnscreenContentManagerTests.swift`.

   Cover at least these behaviors: quick-card deep-link request selects the correct tab and pending route; handbook-section deep-link request selects the correct tab and pending route; consuming a pending route clears it; on-screen manager publishes quick-card context correctly; on-screen manager publishes handbook-section context correctly; on-screen manager clears stale context.

   Extend existing tests only where that is the narrowest fit. Do not replace focused tests with broad UI tests.

   *Success signal: new tests prove the app-owned state handoff works without requiring live Siri execution.*

1. **Run the focused test slice that covers the Siri entry path, entity layer, and new M6P4 seams.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/AskLanternIntentExecutorTests \
  -only-testing:OSATests/AppEntityQueryTests \
  -only-testing:OSATests/NavigationIntentTests \
  -only-testing:OSATests/OnscreenContentManagerTests
# Expected: test action completes successfully, or the exact Xcode/toolchain blocker is captured verbatim
```

*Success signal: the focused Siri, entity, navigation, and on-screen-context seams pass in the simulator test environment or the blocker is explicit.*

1. **Run a build for the application target.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED
```

*Success signal: the app target builds with the new App Intents, coordinator, and on-screen-content wiring.*

### Phase 4: Security And Manual Validation

1. **Run the first-party security scan required for new code.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
snyk code test --path="$PWD"
# Expected: no new actionable issues, or a reported blocker if `snyk` is unavailable
```

*Success signal: new first-party Siri and navigation code has a recorded Snyk result or an exact tool-availability blocker.*

1. **Perform manual validation for the system-facing behaviors that unit tests cannot prove.**

   Validate these manually if full Xcode and the relevant runtime are available: ask Siri a grounded question through `AskLanternIntent`; open a quick card via the new deep-link intent; open a handbook section via the new deep-link intent; while viewing a quick card or handbook section, ask a follow-up question that depends on current on-screen context.

   If a physical device, Siri runtime, or Apple Intelligence-capable environment is unavailable, mark these checks `unverified` and record the exact missing prerequisite.

   *Success signal: either the manual system-surface flow is verified, or the report names the exact reason it could not be verified.*

## Guardrails

- Forbidden: creating a second retrieval pipeline, answer formatter, or repository lookup path for Siri.
- Forbidden: exposing notes, inventory notes, checklist runs, imported-knowledge detail, or other personal/private content as on-screen context in this phase.
- Forbidden: broad app-navigation redesign, tab restructuring, or UI polish work unrelated to App Intent handoff.
- Forbidden: introducing new dependencies, analytics, or remote services.
- Required: use the exact Assistant schema and on-screen-content symbols present in the installed SDK; do not guess API names.
- Required: preserve the current grounded-answer, citation, refusal, and notes-scope behavior of `AskLanternIntent`.
- Required: keep SwiftData and persistence APIs out of feature-layer code and out of the navigation coordinator.
- Required: every new implementation seam must have a focused verification step.
- Budget: prefer one coordinator, one on-screen-content manager, two new intents, and targeted shell wiring over a generalized navigation framework.

## Verification Checklist

- [ ] `AskLanternIntent` remains the single Siri question-answering path and now carries schema metadata using the installed SDK's real types.
- [ ] `OpenQuickCardIntent` exists and opens the app to the targeted quick card via existing entities.
- [ ] `OpenHandbookSectionIntent` exists and opens the app to the targeted handbook section via existing entities.
- [ ] `AppTabView` no longer relies on view-local state alone for App Intent navigation handoff.
- [ ] On-screen context is published only for quick cards and handbook sections.
- [ ] On-screen context is cleared or replaced when stale.
- [ ] Focused tests cover coordinator routing and on-screen-context behavior.
- [ ] `xcodebuild ... test` focused slice passes or is reported with an exact blocker.
- [ ] `xcodebuild ... build` passes or is reported with an exact blocker.
- [ ] `snyk code test --path="$PWD"` is run or reported with an exact blocker.
- [ ] Device-only Siri or Apple Intelligence validation is either completed or explicitly marked `unverified`.

## Error Handling

| Error Condition | Resolution |
| --- | --- |
| `AssistantSchema` symbols differ from the roadmap wording | Use the installed SDK's actual type names and availability annotations discovered in Phase 1. Do not preserve guessed names in source code. |
| On-screen content API is unavailable in the installed SDK | Land the app-owned `OnscreenContentManager` and availability guards first, report the SDK blocker, and keep Apple-specific on-screen publishing `unverified`. |
| App Intent can open the app but cannot reach the target destination | Verify the coordinator is injected from `OSAApp`, confirm tab selection changes before route consumption, and add a focused coordinator test for the failing path. |
| Deep-link intent duplicates entity lookup logic | Remove the duplicate lookup and accept the existing `QuickCardEntity` or `HandbookSectionEntity` directly as the intent parameter. |
| Build fails because full Xcode is unavailable | Report the exact `xcodebuild` or `xcode-select -p` blocker and keep build or test claims `unverified`. |
| Siri semantic behavior cannot be proven in simulator | Keep compile and test claims separate from device-backed Siri validation, and record the manual verification gap explicitly. |
| On-screen context persists after content is dismissed | Clear the manager on disappear or when loading fails, then add or fix a stale-context regression test. |

## Out Of Scope

- M6P5 knowledge-base discovery and any web search API integration
- inventory, checklist, note, or imported-knowledge on-screen context exposure
- redesigning Ask answer text, retrieval ranking, or citation formatting
- widget work, shortcut tiles beyond the new M6P4 intents, or broader Siri marketing polish
- App Store copy, TestFlight release gating, or RC-5 or RC-6 device validation artifacts
- generalized cross-feature navigation framework beyond the narrow coordinator needed for App Intent handoff

## Alternative Solutions

1. **Primary approach:** use a shared `AppNavigationCoordinator` plus a shared `OnscreenContentManager`, both app-owned and reachable from `SharedRuntime`. Pros: smallest coherent fit with current architecture, easy to test, no duplicate routing logic. Cons: introduces a new app-shell state seam that must be wired carefully.
2. **Fallback if Apple on-screen-content APIs are missing or unstable in the installed SDK:** still land the shared on-screen manager and navigation intents, but gate the Apple-specific publishing behind availability or compile-time guards. Pros: preserves forward progress on M6P4's app-owned behavior. Cons: Apple-specific follow-up-question behavior remains partially `unverified` until the correct SDK is available.
3. **Fallback if schema conformance requires a separate file for clarity or availability management:** move only the schema-specific declarations into `OSA/App/Intents/AskLanternIntent+Schema.swift` and keep `perform()` unchanged in `AskLanternIntent.swift`. Pros: isolates SDK-specific code. Cons: one extra file to keep in sync.

## Report Format

When the task is complete, report in this order:

1. **Files modified:** list every source and test file changed, plus any new files created.
2. **SDK symbols used:** name the exact Assistant schema and on-screen-content types or protocols found in the installed SDK.
3. **Navigation outcome:** explain how App Intents hand off into the app shell and which tabs or routes are targeted.
4. **On-screen context scope:** state exactly which content types are published and which remain excluded.
5. **Verification:** provide the exact build, test, and Snyk commands run with pass or blocker status.
6. **Manual validation:** state what Siri or device-backed behavior was verified and what remains `unverified`.
