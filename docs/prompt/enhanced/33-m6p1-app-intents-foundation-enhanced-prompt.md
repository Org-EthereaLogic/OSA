# Milestone 6 Phase 1 App Intents Foundation Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** M6P1 is the smallest Milestone 6 slice, but it still crosses app bootstrap, dependency access outside SwiftUI environment injection, a new Siri-facing App Intents surface, citation-preserving answer formatting, and focused verification. The task must remain narrow and reuse the existing retrieval pipeline rather than creating a parallel assistant stack.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | Milestones 1 through 5 are complete enough to start Milestone 6 in parallel with the remaining RC-5 device gate. The requested slice is M6P1 only. |
| User brief | The recommended next step is `AskLanternIntent` plus `AppShortcutsProvider` so Siri can invoke Lantern with phrases such as "Ask Lantern how to purify water." |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, preserve offline-first and grounded-assistant behavior, keep verification evidence explicit, and do not widen sensitive-scope behavior. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M6P1 is explicitly defined as the App Intents foundation: `AskLanternIntent` and `AppShortcutsProvider`, using the existing retrieval chain with no deployment-target change. |
| `docs/sdlc/05-technical-architecture.md` | The app already has a layered architecture with `App`, `Assistant`, `Domain`, `Retrieval`, and `Persistence` boundaries. SwiftUI features consume services via dependency injection, but App Intents will need a bootstrap path outside environment values. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Siri must remain just another entry point into the grounded assistant. No live-web answers, no model-prior-only behavior, and no uncited substantive responses. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Personal data remains local by default. New Siri behavior must not widen notes scope or trigger hidden networking. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | New assistant entry points need focused tests for fallback, citation integrity, and unsupported or blocked prompts. |
| `docs/adr/ADR-0002-grounded-assistant-only.md` | Ask is a bounded assistant, not a general chatbot. Every answer path must be grounded in approved local evidence or refuse clearly. |
| `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md` | The project target remains iOS 18. Runtime capability branching is already part of the assistant architecture and must continue to work through Siri. |
| `OSA/App/Bootstrap/AppModelContainer.swift` | The app already has a single bootstrap seam for `ModelContainer` creation and bundled seed import. This is the safest place to anchor any shared runtime access for App Intents. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` | `AppDependencies.live` already wires the retrieval pipeline, capability detector, import pipeline, and connectivity service. M6P1 should reuse this graph rather than constructing a second assistant stack. |
| `OSA/Domain/Settings/AskScopeSettings.swift` | Personal notes are not in Ask scope by default. Siri must respect the same setting instead of silently widening scope. |
| `OSA/Retrieval/Querying/LocalRetrievalService.swift` | Retrieval already normalizes the query, enforces sensitivity policy, packages citations, and selects grounded generation or extractive fallback. M6P1 should call this service, not reimplement it. |
| `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift` | Grounded generation is already behind a model-adapter boundary. Siri should inherit the same capability behavior through retrieval, not call Foundation Models directly. |
| `OSATests/CapabilityDetectionTests.swift` | The current tests already prove capability-based routing and citation integrity. M6P1 should extend that style with intent-facing tests rather than introducing a different test strategy. |
| `docs/prompt/enhanced/README.md` | New prompt artifacts belong under `docs/prompt/enhanced/` and should stay aligned with current SDLC terminology and repo structure. |

## Classification Summary

- Core intent: add the first Siri and App Intents surface for Lantern by wiring one natural-language App Intent and one shortcut provider onto the existing grounded retrieval pipeline.
- In scope: a shared bootstrap access path for App Intents, `AskLanternIntent`, `AppShortcutsProvider`, a minimal intent-facing execution or formatting seam, citation-preserving answer text, focused unit tests, and evidence-backed build or test verification.
- Out of scope: `AppEntity` work, Spotlight indexing, `AssistantSchema`, navigation intents, inventory completion, web discovery, UI redesign, sync or backup work, and any live-web answer path.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- App Intents code will live inside the existing `OSA` application target, so adding source files under `OSA/` does not require project-structure changes by itself.
- Siri and Shortcuts invocation may still require manual simulator or device validation even if unit tests pass.
- `AskScopeSettings.includePersonalNotesDefault` remains `false`, and the Siri path must honor the same persisted setting key if personal notes are ever included.
- If full Xcode is unavailable on the Mac mini, build or test claims must remain `unverified`.

## Mission Statement

Implement the M6P1 App Intents foundation so Siri can invoke Lantern through a single `AskLanternIntent` and registered shortcut phrases while reusing the existing local retrieval, citation, safety, and capability-routing chain without widening scope or privacy behavior.

## Technical Context

OSA already has the hard part of this feature: the grounded assistant stack exists. `LocalRetrievalService` normalizes the question, enforces `SensitivityPolicy`, searches the local index, ranks evidence, packages `CitationReference` values, and chooses grounded generation or extractive fallback through the existing capability detector and `FoundationModelAdapter`. M6P1 should not add a second assistant path. It should expose the current one to Siri.

The main architectural challenge is not retrieval. It is access. `AskScreen` gets `retrievalService` through SwiftUI environment injection, but `AppIntent` execution runs outside the view hierarchy. The implementation therefore needs one explicit bootstrap seam that App Intents can use safely. The smallest coherent design is to centralize shared runtime access in the app bootstrap layer, then keep the intent itself thin and delegate behavior to a small, testable executor that formats `RetrievalOutcome` into Siri-safe text.

That executor must preserve three product guarantees:

1. The Siri path uses the same retrieval and safety chain as the in-app Ask feature.
2. The Siri path does not silently include personal notes unless the existing Ask setting allows it.
3. The Siri response still carries local provenance in a compact way, even if M6P1 does not yet implement richer `AssistantSchema`, Spotlight, or deep-link entities.

The preferred implementation shape is:

- one shared bootstrap owner for `ModelContainer` and `AppDependencies`
- one intent-facing executor that turns a question into grounded answer text plus compact citation labels
- one `AskLanternIntent` that accepts a natural-language question parameter and delegates to the executor
- one `AppShortcutsProvider` that registers phrases centered on `Ask Lantern`

Keep this phase intentionally small. M6P2 through M6P5 already define the richer Apple Intelligence work. M6P1 succeeds when Siri can invoke the existing grounded Ask capability without changing its trust boundaries.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Siri entry surface | Lantern has no App Intents or App Shortcuts surface. | Siri can invoke a single Lantern intent with a natural-language question. |
| Dependency access outside SwiftUI | `retrievalService` is injected into views through environment values only. | App Intents have one explicit bootstrap path to the existing `AppDependencies` graph. |
| Retrieval behavior | Grounded retrieval, citations, and capability routing exist only for in-app Ask consumers. | Siri uses the same retrieval, citation, refusal, and fallback chain as in-app Ask. |
| Notes scope | Ask scope defaults are defined in `AskScopeSettings`, but Siri has no behavior yet. | Siri honors the same notes-scope key and default instead of widening personal-data access. |
| Citation visibility in Siri | No Siri response format exists. | Siri returns concise grounded text that includes compact local source labels or titles. |
| Test coverage | Capability routing is tested, but there are no intent-facing tests. | Focused tests prove question routing, refusal handling, scope handling, and citation-preserving formatting for the Siri path. |

## Pre-Flight Checks

1. Verify the repository root and the main M6P1 seams.

```bash
pwd
test -f OSA/App/Bootstrap/OSAApp.swift \
  && test -f OSA/App/Bootstrap/AppModelContainer.swift \
  && test -f OSA/App/Bootstrap/Dependencies/AppDependencies.swift \
  && test -f OSA/Retrieval/Querying/LocalRetrievalService.swift \
  && test -f OSA/Domain/Settings/AskScopeSettings.swift \
  && test -f OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift \
  && echo "m6p1 surfaces present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: m6p1 surfaces present
```

*Success signal: the app bootstrap, retrieval, and settings seams that M6P1 must reuse are present before edits begin.*

1. Confirm the current repo has no App Intents implementation yet.

```bash
rg -n "AppIntent|AppShortcutsProvider|AskLanternIntent" OSA OSATests
# Expected: no matches
```

*Success signal: the implementation is starting from a clean M6P1 surface rather than overlapping hidden existing intent code.*

1. Confirm the deployment target remains aligned with the roadmap.

```bash
rg -n 'deploymentTarget:|iOS: "18.0"' project.yml
# Expected: the deployment target block shows iOS 18.0
```

*Success signal: M6P1 does not drift into a project-target change.*

1. Confirm the Ask scope default for personal notes.

```bash
rg -n "includePersonalNotesKey|includePersonalNotesDefault|retrievalScopes" OSA/Domain/Settings/AskScopeSettings.swift
# Expected: the file shows the shared setting key and a false default
```

*Success signal: the Siri path can be designed to honor the same scope contract the app already uses.*

1. Confirm whether full-Xcode verification is available.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success signal: build and test verification is possible, or the blocker is known before implementation begins.*

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the existing bootstrap, retrieval, settings, and testing files before editing.

   Required files:

   - `OSA/App/Bootstrap/OSAApp.swift`
   - `OSA/App/Bootstrap/AppModelContainer.swift`
   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/Domain/Ask/Repositories/AskRepositories.swift`
   - `OSA/Domain/Ask/Models/RetrievalModels.swift`
   - `OSA/Domain/Settings/AskScopeSettings.swift`
   - `OSA/Retrieval/Querying/LocalRetrievalService.swift`
   - `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`
   - `OSATests/CapabilityDetectionTests.swift`
   - `docs/sdlc/03-mvp-scope-roadmap.md`
   - `docs/sdlc/05-technical-architecture.md`
   - `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`
   - `docs/sdlc/10-security-privacy-and-safety.md`
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
   - `docs/adr/ADR-0002-grounded-assistant-only.md`
   - `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`

   *Success signal: the implementation plan is anchored in the current assistant chain and not inferred from milestone names alone.*

2. Freeze the M6P1 contract before writing code.

   This phase includes only:

   - one natural-language Siri intent
   - one shortcut provider centered on `Ask Lantern`
   - reuse of the existing retrieval and citation pipeline
   - compact citation-preserving response formatting

   This phase excludes:

   - `AppEntity` and Spotlight work
   - `AssistantSchema`
   - navigation or deep-link intents
   - inventory completion
   - web discovery or import work

   *Success signal: the implementation remains a narrow App Intents foundation and does not absorb later M6 phases.*

3. Choose one shared runtime access seam for App Intents.

   Preferred approach:

   - add a single bootstrap-owned shared runtime entrypoint under `OSA/App/Bootstrap/`
   - ensure both `OSAApp` and App Intents resolve `ModelContainer` and `AppDependencies` through that same seam

   *Success signal: the intent path does not depend on SwiftUI environment values and does not create a parallel dependency graph by accident.*

4. Decide the Siri notes-scope rule explicitly.

   Preferred rule:

   - read the existing `AskScopeSettings.includePersonalNotesKey`
   - default to `AskScopeSettings.includePersonalNotesDefault`
   - if settings access fails, stay with the safe default of not including personal notes

   *Success signal: Siri behavior does not widen personal-data access beyond the current Ask contract.*

### Phase 2: Implement The Intent-Facing Execution Seam

1. Add a small executor or service dedicated to M6P1 intent execution.

   Preferred file:

   - `OSA/Assistant/Orchestration/AskLanternIntentExecutor.swift`

   Responsibilities:

   - accept a plain-language question
   - resolve Ask scopes using `AskScopeSettings`
   - call the existing `RetrievalService`
   - translate `RetrievalOutcome` into Siri-safe text
   - append compact citation labels derived from `CitationReference`

   *Success signal: the App Intent itself stays thin and the business behavior is unit-testable without Siri infrastructure.*

2. Keep the executor strictly on top of the current retrieval pipeline.

   Required behavior:

   - do not duplicate normalization, ranking, sensitivity policy, or model-capability logic
   - do not call `FoundationModelAdapter` directly
   - do not bypass `RetrievalService.retrieve(query:scopes:)`

   *Success signal: all grounded-answer behavior still flows through the same core assistant path used elsewhere in the app.*

3. Define explicit formatting rules for Siri output.

   Minimum format requirements:

   - answered outcome: grounded answer text followed by a compact `Sources:` suffix using local source titles or labels
   - insufficient evidence: a concise `not found locally` style response with no live-web claim
   - blocked or sensitive refusal: deterministic refusal language consistent with the existing assistant boundary
   - service unavailable: explicit local-service unavailable message instead of crash or silent failure

   *Success signal: Siri responses remain grounded, bounded, and provenance-aware even before richer Apple Intelligence surfaces arrive.*

4. Keep the executor dependency-injectable for tests.

   Preferred inputs:

   - `RetrievalService` dependency
   - a narrow notes-scope reader or closure over `UserDefaults`

   *Success signal: unit tests can force answered, refused, and insufficient-evidence paths deterministically.*

### Phase 3: Add The App Intents Surface

1. Create the natural-language App Intent.

   Preferred file:

   - `OSA/App/Intents/AskLanternIntent.swift`

   Required behavior:

   - conform to `AppIntent`
   - expose one question parameter for natural-language input
   - delegate to `AskLanternIntentExecutor`
   - return dialog and value text appropriate for Siri and Shortcuts use
   - keep `openAppWhenRun` disabled unless the implementation proves the intent must foreground the app to work correctly

   *Success signal: the intent can answer a question without embedding retrieval or bootstrap logic directly in the intent type.*

2. Create the App Shortcuts provider.

   Preferred file:

   - `OSA/App/Intents/LanternAppShortcutsProvider.swift`

   Required behavior:

   - conform to `AppShortcutsProvider`
   - register at least one phrase anchored on `Ask Lantern`
   - use Lantern branding for shortcut title and icon metadata
   - keep the phrase set small and focused on the M6P1 Siri invocation path

   *Success signal: the app exposes discoverable shortcut phrases without requiring the user to build a custom Shortcut manually.*

3. Wire shortcut metadata refresh only if the platform behavior requires it.

   Preferred file for a minimal update:

   - `OSA/App/Bootstrap/OSAApp.swift`

   If needed, trigger the provider's parameter refresh during app launch using the lightest possible call.

   *Success signal: shortcut discovery is reliable, and the app bootstrap remains minimal and launch-safe.*

4. Keep all App Intents code inside the current target and folder boundaries.

   Allowed areas:

   - `OSA/App/Bootstrap/`
   - `OSA/App/Intents/`
   - `OSA/Assistant/Orchestration/`
   - `OSATests/`

   *Success signal: the change remains localized and does not leak persistence or platform details into feature views.*

### Phase 4: Verification And Tests

1. Add focused tests for the intent-facing executor.

   Preferred file:

   - `OSATests/AskLanternIntentExecutorTests.swift`

   Minimum scenarios:

   - answered outcome returns answer text plus compact local source labels
   - blocked query returns refusal text and does not claim unsupported capability
   - insufficient evidence returns a `not found locally` style response
   - personal notes stay excluded when the settings key is absent or false
   - personal notes are included only when the existing settings key is enabled
   - unavailable retrieval service returns a deterministic fallback message

   *Success signal: the new Siri-facing behavior is proven without requiring Siri runtime integration for every branch.*

2. Add a thin intent test only if it provides real value.

   Optional file:

   - `OSATests/AskLanternIntentTests.swift`

   Keep it limited to parameter forwarding or wrapper behavior. If direct intent execution is awkward or brittle, keep the intent thin and rely on executor coverage instead.

   *Success signal: tests stay high-signal and do not become a fragile proxy for App Intents framework internals.*

3. Run the primary build and test verification.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED

xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: test session completes without failures in the touched suites
```

   *Success signal: the app target and test target both accept the new App Intents surface.*

1. Perform manual App Shortcuts validation.

   Minimum manual checks:

   - launch the app once after installing the build
   - open Shortcuts or Siri on a supported simulator or device
   - confirm the `Ask Lantern` shortcut appears
   - ask a known seeded question such as `how to purify water`
   - verify the response is local-only, grounded, and includes source labeling

   *Success signal: the Siri surface is discoverable and produces a bounded Lantern answer for a known supported query.*

### Phase 5: Security And Quality Review

1. Confirm no hidden networking or scope widening was introduced.

   Required checks:

   - Siri path still goes through `RetrievalService`
   - Siri path does not call any web import or refresh API
   - Siri path does not include personal notes unless the shared Ask setting allows it

   *Success signal: M6P1 adds only a new entry surface, not new data movement or new knowledge sources.*

2. Run Snyk Code if the CLI is available.

```bash
command -v snyk
# Expected: a path to the snyk executable, or no output if unavailable

snyk code test --path="$PWD"
# Expected: security results for the current workspace, or an explicit environment blocker
```

   *Success signal: new first-party code is security-reviewed, or the exact blocker is reported as unverified.*

1. Keep any blocked verification explicitly marked.

   Required reporting rule:

   - if Siri voice invocation, simulator support, or full Xcode verification is unavailable, report the exact blocker and keep the affected claim `unverified`

   *Success signal: the milestone result distinguishes verified behavior from environment-limited assumptions.*

## Guardrails

- Do not add `AppEntity`, Spotlight indexing, `AssistantSchema`, navigation intents, inventory completion, or knowledge discovery work.
- Do not create a second retrieval or assistant pipeline for Siri.
- Do not call `FoundationModelAdapter` directly from App Intents code.
- Do not put `SwiftData`, `ModelContext`, or persistence implementation details directly inside feature views or the intent type.
- Do not silently include personal notes in Siri responses.
- Do not add new dependencies, remote AI APIs, analytics, or background network behavior.
- Do not claim live-web knowledge or return uncited substantive answers.
- Prefer the smallest coherent bootstrap change that lets App Intents reach the existing dependency graph.

## Verification Checklist

- [ ] Prompt type is classified as `Feature`
- [ ] Complexity classification is included and justified
- [ ] Mission statement is one sentence and unambiguous
- [ ] Technical context explains why App Intents need a bootstrap seam outside SwiftUI environment injection
- [ ] All file paths are explicit
- [ ] Pre-flight checks verify repo state, deployment target, scope default, and Xcode availability
- [ ] Instructions are organized into investigation, implementation, verification, and security phases
- [ ] Every action step has an explicit success signal
- [ ] `AskLanternIntent` is defined as the single M6P1 natural-language entry point
- [ ] `AppShortcutsProvider` is included and scoped to `Ask Lantern` phrases
- [ ] Siri uses the existing retrieval, safety, capability, and citation chain
- [ ] Personal notes scope is explicitly constrained to the shared Ask setting
- [ ] Unit tests cover answered, refused, insufficient-evidence, and notes-scope behavior
- [ ] Build, test, and Snyk verification commands are specified with expected outcomes
- [ ] Guardrails prevent expansion into later Milestone 6 phases

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| App Intents cannot access `retrievalService` through SwiftUI environment injection | Add one shared bootstrap seam under `OSA/App/Bootstrap/` and resolve dependencies through that seam instead of environment values. |
| Shortcut phrases do not appear in Shortcuts or Siri | Launch the app once after install, verify the provider is compiled into the app target, and add a minimal shortcut-parameter refresh call during launch only if needed. |
| Siri answer loses citation visibility | Append a compact `Sources:` suffix using `CitationReference` display labels or titles instead of returning bare answer text. |
| Personal notes appear when they should not | Read only `AskScopeSettings.includePersonalNotesKey` with the existing default of `false`, and add tests for missing, false, and true settings states. |
| The intent crashes when retrieval services are unavailable | Return a deterministic local-service unavailable message and report the bootstrap failure rather than crashing the process. |
| Full Xcode, Siri runtime, or device validation is unavailable | Report the exact command or environment blocker and keep the affected verification claim `unverified`. |

## Out Of Scope

- `HandbookSectionEntity`, `QuickCardEntity`, `ChecklistEntity`, `InventoryItemEntity`, or any `AppEntity` work.
- Spotlight indexing or entity query implementations.
- `AssistantSchema`, on-screen content APIs, or follow-up-question understanding.
- Deep-link navigation intents such as `OpenQuickCardIntent` or `OpenHandbookSectionIntent`.
- FM-powered inventory completion.
- Knowledge discovery, web search APIs, or changes to the M4 import pipeline.
- UI redesign of `AskScreen` or any unrelated Settings, Home, Library, Inventory, or Notes feature work.

## Alternative Solutions

1. **Preferred:** add a shared bootstrap runtime plus a thin `AskLanternIntentExecutor` on top of `RetrievalService`. Pros: keeps one assistant pipeline, strong testability, minimal scope. Cons: requires a careful bootstrap seam for code outside SwiftUI views.
2. **Fallback A:** let the executor lazily create `AppDependencies.live(modelContainer:)` for each intent invocation if a shared runtime owner becomes lifecycle-heavy. Pros: isolated implementation. Cons: duplicated startup work and a higher risk of drift from the main app bootstrap.
3. **Fallback B:** keep Siri formatting purely extractive even on grounded-capable devices if richer App Intents result formatting is unstable. Pros: lower integration risk while preserving grounding and citations. Cons: reduced fluency compared with the existing grounded-generation path.

## Report Format

When the implementation is complete, report back in this structure:

1. Files added and files changed.
2. Shared runtime access approach used for App Intents.
3. `AskLanternIntent` and `AppShortcutsProvider` behavior implemented.
4. How citations and personal-notes scope were handled.
5. Tests added and what each one proves.
6. Verification commands run and their outcomes.
7. Manual Siri or Shortcuts validation results.
8. Remaining risks, deferred M6 work, or explicitly `unverified` claims.
