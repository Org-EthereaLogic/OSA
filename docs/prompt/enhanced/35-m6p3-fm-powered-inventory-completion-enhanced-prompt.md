# Milestone 6 Phase 3 FM-Powered Inventory Completion Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** M6P3 is narrower than M6P4 and M6P5, but it still crosses a new Apple Foundation Models structured-output seam, deterministic fallback heuristics, app dependency wiring, SwiftUI form integration, and focused verification across both FM-capable and fallback-capable paths. The task must stay small and avoid turning inventory entry into a broader assistant or navigation project.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | Milestones 1 through 5 are complete, M6P1 and M6P2 are complete, RC-5 remains device-blocked, and the recommended next engineering step is M6P3 because it is the narrowest self-contained remaining M6 slice. |
| User brief | Implement FM-powered inventory completion now; defer M6P4 and RC-5 because they either depend on M6P2 follow-on work or require a physical device. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, keep the app offline-first and local-first, respect repository boundaries, avoid speculative abstraction, and mark blocked verification as `unverified`. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M6P3 is explicitly defined as FM-powered inventory completion using Apple Foundation Models structured output to suggest category, quantity, unit, and location from partial inventory input, with a static heuristic fallback when FM is unavailable. |
| `docs/sdlc/05-technical-architecture.md` | Services are wired through `AppDependencies` and SwiftUI `EnvironmentValues`; inventory UI should remain feature-layer only, while FM and prompt-shaping logic belong outside `OSA/Features/`. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Foundation Models use in OSA must remain deterministic, bounded, and supportive of offline/local-first behavior. Generation is a formatting or completion step, not a source of truth. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Inventory data remains on device, remote AI services are out of scope, and system surfaces must not leak private content. Completion must not introduce networking or hidden data export. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | New first-party assistant-adjacent code requires focused unit tests, explicit verification evidence, and `snyk code test --path="$PWD"` when available. |
| `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md` | The app target remains iOS 18 with runtime capability branching. M6P3 must reuse the existing Foundation Models guard pattern rather than changing deployment strategy. |
| `OSA/Features/Inventory/InventoryItemFormView.swift` | Inventory creation and edit already share one form with state for name, category, quantity, unit, location, notes, expiry, and reorder threshold. This is the concrete integration point for M6P3. |
| `OSA/Features/Inventory/InventoryScreen.swift` and `OSA/Features/Inventory/InventoryItemDetailView.swift` | Both create and edit flows already route through `InventoryItemFormView`, so UI integration should happen in one place instead of duplicating behavior. |
| `OSA/Domain/Inventory/Models/InventoryItem.swift` | The target data shape is already defined. M6P3 should only suggest `category`, `quantity`, `unit`, and `location`, not invent new inventory fields. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` and `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift` | The app already injects repositories and assistant services through one dependency graph and one environment-values file. M6P3 should reuse this exact seam. |
| `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift` and `OSA/Assistant/ModelAdapters/DeviceCapabilityDetector.swift` | The repository already has the compile-time and runtime Foundation Models availability pattern: `#if canImport(FoundationModels)` plus `@available(iOS 26, *)`. M6P3 should follow this pattern rather than inventing a second capability strategy. |
| `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift` | Prompt construction is already encapsulated in the assistant layer. M6P3 should keep any FM prompt or schema shaping outside the feature layer. |
| `docs/prompt/enhanced/33-m6p1-app-intents-foundation-enhanced-prompt.md` and `docs/prompt/enhanced/34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md` | The existing M6 prompt artifacts use a narrow milestone slice, explicit file paths, phased instructions, and scoped guardrails. M6P3 should preserve the same style and boundary discipline. |

## Classification Summary

- Core intent: add inventory-form completion that uses Apple Foundation Models structured output when available and deterministic heuristics otherwise, without widening scope beyond the existing inventory create and edit flows.
- In scope: one inventory completion service, one structured suggestion model, dependency injection through `AppDependencies` and `EnvironmentValues`, integration in `InventoryItemFormView`, focused tests, and explicit build or security verification.
- Out of scope: new inventory persistence fields, Siri or App Intents changes, `AssistantSchema`, Notes or checklist completion, online services, deep-linking, analytics, and a broader inventory redesign.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- `InventoryItemFormView` remains the only form used for both create and edit flows.
- M6P3 should suggest values only for `category`, `quantity`, `unit`, and `location`; `notes`, expiry, reorder threshold, tags, and archive state remain manually edited.
- The installed SDK may expose Foundation Models differently over time, but the existing repository pattern of `#if canImport(FoundationModels)` and runtime availability checks must remain the integration boundary.
- If structured generation APIs such as `@Generable` are unavailable in the installed SDK, the task must preserve the service contract and report the exact blocker or fall back to heuristics without inventing a remote dependency.
- If full Xcode is unavailable on this machine, build and test claims must be reported as `unverified`.

## Mission Statement

Implement M6P3 by adding a bounded inventory completion service that uses Apple Foundation Models structured output to suggest missing inventory fields from partial form input, falls back to deterministic local heuristics when FM is unavailable, and integrates into the shared inventory form without leaking model logic into the feature layer.

## Technical Context

OSA already has the three critical pieces this phase should reuse: one shared inventory form, one shared dependency graph, and one established Foundation Models capability pattern. `InventoryItemFormView` is the single form surface for both create and edit. `AppDependencies` and `RepositoryEnvironment` are already the standard injection seams for services. `FoundationModelAdapter` and `DeviceCapabilityDetector` already show how the repository compiles and gates Foundation Models usage.

That means M6P3 is not a persistence project and not a retrieval project. It is a bounded form-assist project. The implementation should introduce one service in the assistant layer that accepts the form's partial state and returns a typed suggestion object. The service should prefer on-device FM structured output when available, but it must keep a deterministic heuristic fallback so the feature remains useful on unsupported devices and safe in tests.

The core design constraint is merge safety. The service should help the user complete missing fields, not silently rewrite values they already entered. The minimal, defensible merge rule for this milestone is:

1. Never overwrite a non-empty text field automatically.
2. Never replace a non-default numeric value automatically.
3. Treat `.other` for category and `1` for quantity as editable defaults that can be replaced when the user requests suggestions.
4. Apply only the fields for which the service has a concrete suggestion.

The preferred implementation shape is:

- one assistant-layer service dedicated to inventory completion
- one typed request and suggestion model for partial form input and structured output
- one heuristics path that can be tested without FM availability
- one `EnvironmentValues` injection seam and app bootstrap wiring
- one small UI affordance in `InventoryItemFormView` that triggers suggestion generation and surfaces no-op or failure states clearly

Keep the phase intentionally small. M6P3 succeeds when the inventory form can infer obvious details like category, quantity, unit, and storage location from partial input on FM-capable devices while still offering useful heuristic suggestions on devices without FM support.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Inventory form assistance | Users must manually enter every field in `InventoryItemFormView`. | Users can request suggested values for missing inventory details from partial input. |
| FM integration | The app uses Foundation Models only for grounded Ask responses. | The app also uses Foundation Models for typed inventory field completion through a separate bounded service. |
| Fallback behavior | No inventory-specific fallback or heuristics exist today. | Deterministic heuristics provide category, quantity, unit, and location suggestions when FM is unavailable or returns nothing usable. |
| Injection seam | Inventory views receive only `inventoryRepository` today. | `InventoryItemFormView` also receives one injected inventory completion service through the existing environment pattern. |
| Edit safety | Any future suggestion feature could accidentally overwrite existing form values. | Suggestions merge conservatively and only replace blank or default values when the user explicitly requests completion. |
| Test coverage | Repository CRUD is covered, but no tests exist for form-completion behavior. | Focused tests verify FM gating, heuristic fallback, merge rules, and no-op behavior for insufficient input. |

## Pre-Flight Checks

1. Verify the repository root and the concrete M6P3 surfaces.

```bash
pwd
test -f OSA/Features/Inventory/InventoryItemFormView.swift \
  && test -f OSA/Features/Inventory/InventoryScreen.swift \
  && test -f OSA/Features/Inventory/InventoryItemDetailView.swift \
  && test -f OSA/Domain/Inventory/Models/InventoryItem.swift \
  && test -f OSA/App/Bootstrap/Dependencies/AppDependencies.swift \
  && test -f OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift \
  && test -f OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift \
  && test -f OSA/Assistant/ModelAdapters/DeviceCapabilityDetector.swift \
  && echo "m6p3 surfaces present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: m6p3 surfaces present
```

*Success signal: the form, model, dependency, and FM adapter seams needed for M6P3 are present before edits begin.*

1. Confirm the current codebase has no M6P3 implementation yet.

```bash
rg -n "InventoryCompletionService|inventoryCompletionService|@Generable|InventoryCompletionSuggestion" OSA OSATests
# Expected: no matches
```

*Success signal: the phase starts from a clean inventory-completion surface rather than overlapping hidden existing code.*

1. Confirm the current Foundation Models gating pattern and deployment target.

```bash
rg -n "iOS: \"18\.0\"|@available\(iOS 26|canImport\(FoundationModels\)" project.yml OSA/Assistant OSA/App/Bootstrap/Dependencies/AppDependencies.swift
# Expected: iOS 18.0 deployment target plus the existing FoundationModels compile/runtime guards
```

*Success signal: M6P3 reuses the current platform and availability approach instead of changing deployment strategy.*

1. Confirm the form is the shared create and edit integration point.

```bash
rg -n "InventoryItemFormView\(mode:" OSA/Features
# Expected: matches in InventoryScreen.swift and InventoryItemDetailView.swift
```

*Success signal: a single form integration will cover both create and edit flows.*

1. Confirm whether full-Xcode verification is available.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success signal: build and test verification is possible, or the exact blocker is known before implementation begins.*

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the current inventory form, bootstrap, and Foundation Models files before editing.

   Required files:

   - `OSA/Features/Inventory/InventoryItemFormView.swift`
   - `OSA/Features/Inventory/InventoryScreen.swift`
   - `OSA/Features/Inventory/InventoryItemDetailView.swift`
   - `OSA/Domain/Inventory/Models/InventoryItem.swift`
   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`
   - `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`
   - `OSA/Assistant/ModelAdapters/DeviceCapabilityDetector.swift`
   - `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift`
   - `OSATests/InventoryRepositoryTests.swift`
   - `docs/sdlc/03-mvp-scope-roadmap.md`
   - `docs/sdlc/05-technical-architecture.md`
   - `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`
   - `docs/sdlc/10-security-privacy-and-safety.md`
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
   - `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`

   *Success signal: the implementation plan is anchored in the current form, dependency, and FM guard seams rather than inferred from milestone names only.*

2. Freeze the M6P3 contract before writing code.

   This phase includes only:

   - suggesting `category`, `quantity`, `unit`, and `location`
   - one completion service with FM plus heuristic fallback
   - wiring that service through the existing app dependency and environment seam
   - one user-triggered inventory-form integration
   - focused tests and explicit verification

   This phase excludes:

   - persistence schema changes
   - automatic background completion
   - Ask, Siri, Spotlight, or `AssistantSchema` changes
   - checklist or notes completion
   - remote AI or network calls
   - expiry, reorder threshold, or note summarization

   *Success signal: the implementation remains a narrow form-completion slice and does not absorb later M6 phases or unrelated inventory polish.*

3. Lock the merge rules explicitly before implementation.

   Required rules:

   - blank `unit` and blank `location` may be populated by suggestions
   - `category == .other` may be replaced by a concrete category suggestion
   - `quantity == 1` may be replaced only if the suggestion is clearly parsed from user-provided text
   - non-empty text fields and non-default values must not be overwritten automatically

   *Success signal: the service behaves like completion assistance, not silent rewriting.*

4. Decide the service contract before implementation.

   Preferred shape:

   - one request model representing the current partial form state
   - one suggestion model with optional `category`, `quantity`, `unit`, and `location`
   - one service entry point such as `suggest(for:) async -> InventoryCompletionSuggestion`

   *Success signal: the form integrates against a stable, testable contract instead of direct FM session calls.*

### Phase 2: Implement The Completion Service

1. Add a dedicated assistant-layer completion service.

   Preferred files:

   - `OSA/Assistant/InventoryCompletion/InventoryCompletionService.swift`
   - optionally `OSA/Assistant/InventoryCompletion/InventoryCompletionModels.swift` if a second file materially improves clarity

   Required responsibilities:

   - accept partial inventory input from the form
   - decide whether FM structured completion is available
   - return typed suggestions for `category`, `quantity`, `unit`, and `location`
   - fall back to deterministic heuristics when FM is unavailable, fails, or returns unusable output
   - never perform networking or persistence writes

   *Success signal: inventory completion logic lives outside the feature layer and can be tested without rendering the SwiftUI form.*

2. Keep Foundation Models usage behind the existing compile-time and runtime gates.

   Required rules:

   - reuse `#if canImport(FoundationModels)` and `@available(iOS 26, *)` style guards already used by the repository
   - do not change `project.yml` deployment target
   - do not create a second capability detector if the existing `DeviceCapabilityDetector` can supply the needed signal

   *Success signal: M6P3 follows the repository's established FM integration pattern instead of introducing a conflicting platform strategy.*

3. Use structured FM output rather than free-form text parsing when the SDK supports it.

   Preferred approach:

   - define a typed structured-output schema using the Foundation Models API available in the installed SDK
   - constrain the schema to `category`, `quantity`, `unit`, and `location`
   - pass only the current partial inventory input needed to infer those fields
   - reject incomplete or contradictory model output instead of heuristically trusting arbitrary prose

   *Success signal: the FM path produces machine-usable structured suggestions and does not depend on brittle string parsing of chat-like output.*

4. Add a deterministic heuristic fallback in the same service boundary.

   Minimum heuristic behaviors:

   - infer `category` from obvious tokens such as water, battery, med kit, flashlight, tarp, radio, soap, or document language
   - parse simple count-plus-unit phrases such as `2 gallons`, `12 cans`, `24 AA batteries`, or `1 first aid kit`
   - infer `location` from explicit storage phrases already present in the user's text, such as `garage`, `basement`, `hall closet`, or `car`
   - return an empty suggestion when the input does not contain enough signal

   *Success signal: unsupported devices still receive useful, predictable completion behavior with no model dependency.*

5. Keep completion inputs bounded and local.

   Required rules:

   - do not look at notes, checklist state, or remote content
   - do not query the web or call any network service
   - do not read unrelated personal records to generate suggestions unless a later milestone explicitly adds that behavior

   *Success signal: M6P3 stays a local form-assist feature and preserves privacy boundaries.*

### Phase 3: Wire The Service Through App Dependencies

1. Extend the app dependency graph with the inventory completion service.

   Required files:

   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`
   - `OSA/App/Bootstrap/OSAApp.swift`

   Required behavior:

   - construct the new service in `AppDependencies.live(modelContainer:)`
   - expose it through a new environment key and `EnvironmentValues` property
   - inject it from `OSAApp` alongside the existing repositories and assistant services

   *Success signal: `InventoryItemFormView` can access the new service through the same dependency pattern already used elsewhere in the app.*

2. Keep the dependency seam minimal.

   Preferred rule:

   - if the service only needs capability detection and no repositories, inject only the minimal collaborators required
   - avoid introducing a generic assistant service registry or extra abstraction layer

   *Success signal: the bootstrap change is proportionate and does not add speculative infrastructure.*

### Phase 4: Integrate Into The Inventory Form

1. Update `InventoryItemFormView` to use the injected completion service.

   Required file:

   - `OSA/Features/Inventory/InventoryItemFormView.swift`

   Required behavior:

   - add one explicit user-triggered action such as `Suggest Details`
   - gather the current partial form state into the completion request
   - show an in-progress state while suggestions are generated
   - apply only the suggested fields allowed by the merge rules
   - surface a simple no-op or failure message when no useful suggestion is available

   *Success signal: users can request completion from both create and edit flows through the shared form without hidden background behavior.*

2. Keep the UI change deliberately small.

   Preferred constraints:

   - do not redesign the form layout
   - do not add a multi-step wizard
   - keep the control near the existing item-detail fields or toolbar where the intent is obvious
   - ensure the action is disabled when there is no meaningful partial input to complete

   *Success signal: the feature feels additive to the current form rather than becoming a separate inventory experience.*

3. Preserve manual control in edit mode.

   Required rules:

   - do not silently rewrite existing edited values when the user opens an item
   - apply suggestions only after the user taps the completion action
   - keep `Save` as the only persistence commit action

   *Success signal: M6P3 assists editing without bypassing the user's explicit save flow.*

### Phase 5: Verification And Tests

1. Add focused tests for the completion service.

   Preferred file:

   - `OSATests/InventoryCompletionServiceTests.swift`

   Minimum scenarios:

   - FM unavailable routes to heuristics
   - obvious water input infers `category = .water`
   - obvious battery input infers `category = .power` and preserves parsed unit language
   - explicit count-plus-unit strings parse into `quantity` and `unit`
   - explicit storage phrases infer `location`
   - empty or vague input returns an empty suggestion
   - merge rules preserve non-default values and apply only blank or default fields
   - FM path invalid output falls back to heuristics or empty suggestion without crashing

   *Success signal: the new service behavior is covered independently of SwiftUI rendering and independent of actual FM availability on the test host.*

2. Add a small form integration test only if it stays high-signal.

   Optional file:

   - `OSATests/InventoryItemFormCompletionTests.swift`

   Keep it limited to request-building or merge behavior extracted into a testable helper. Do not add brittle snapshot or UI-framework-heavy tests if the same behavior is easier to prove in service-level unit tests.

   *Success signal: UI-related logic is tested where it adds real value, without turning the milestone into a SwiftUI-testing project.*

3. Run the focused completion tests first.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/InventoryCompletionServiceTests
# Expected: the targeted M6P3 tests pass with exit code 0
```

   *Success signal: the new completion behavior is proven in isolation before broader regression checks.*

1. Run the full build and test verification when full Xcode is available.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED

xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: the full suite passes, or any unrelated pre-existing failure is reported separately
```

   *Success signal: the new service and form integration compile cleanly and do not regress the broader app.*

1. Perform manual verification of both form paths.

   Minimum manual checks:

   - open Inventory and start a new item with partial input such as `24 AA batteries garage`
   - trigger `Suggest Details` and verify category, quantity, unit, and location populate conservatively
   - open an existing item in edit mode, trigger completion, and verify non-empty user values are not overwritten automatically
   - test a vague input and verify the UI reports no useful suggestion rather than inventing data

   *Success signal: the inventory form behaves predictably for create, edit, and no-signal cases.*

### Phase 6: Security And Quality Review

1. Confirm that M6P3 adds no networking and no hidden data movement.

   Required checks:

   - the completion service does not depend on `ConnectivityService`, `TrustedSourceHTTPClient`, or import pipeline types
   - no remote AI or web service is called
   - suggestions are derived only from current local form input plus local deterministic rules or on-device FM

   *Success signal: the feature stays fully local and private by default.*

2. Run Snyk Code if the CLI is available.

```bash
command -v snyk
# Expected: path to snyk or no output

snyk code test --path="$PWD"
# Expected: security results for the workspace, or an explicit environment blocker
```

   *Success signal: new first-party code is security-reviewed, or the exact blocker is reported as `unverified`.*

1. Update canonical docs only if the milestone is fully implemented and verified.

   Minimum docs to update on successful completion:

   - `docs/sdlc/03-mvp-scope-roadmap.md` to mark M6P3 complete and summarize the shipped behavior
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` to record the new completion-service tests and verification scope

   *Success signal: code, roadmap, and quality documentation agree about M6P3 completion status.*

## Guardrails

- Do not change the inventory persistence schema or add new item fields.
- Do not introduce any network call, remote AI service, analytics event, or background task.
- Do not leak Foundation Models or prompt-shaping details into `OSA/Features/Inventory/`.
- Do not overwrite non-empty or non-default user-entered values automatically.
- Do not infer or fill expiry dates, reorder thresholds, notes, tags, or archive state in this phase.
- Do not change Ask, App Intents, Spotlight, or `AssistantSchema` code as part of M6P3.
- Do not add new dependencies or a generic completion framework.
- Prefer the smallest coherent service and UI delta that satisfy the milestone.

## Verification Checklist

- [ ] Prompt type is classified as `Feature`
- [ ] Complexity classification is included and justified
- [ ] Mission statement is one sentence and unambiguous
- [ ] Technical context explains why M6P3 should reuse the existing form, dependency graph, and FM guard pattern
- [ ] All file paths are explicit
- [ ] Pre-flight checks verify the form, dependency, and FM seams before implementation
- [ ] Instructions are organized into investigation, implementation, verification, and security phases
- [ ] Every action step has an explicit success signal
- [ ] The completion service returns typed suggestions for `category`, `quantity`, `unit`, and `location`
- [ ] The FM path stays behind the existing compile-time and runtime availability guards
- [ ] A deterministic heuristic fallback exists for unsupported devices or unusable model output
- [ ] `InventoryItemFormView` integrates the service through a user-triggered action
- [ ] Merge rules preserve user-entered values and avoid silent overwrites
- [ ] Focused completion-service tests are added and run
- [ ] Build, full test, and Snyk commands are specified with expected outcomes
- [ ] Guardrails prevent scope creep into M6P4, M6P5, or unrelated inventory redesign work

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| The installed SDK does not expose the expected Foundation Models structured-output API | Keep the inventory completion service contract intact, report the exact API mismatch, and land or validate the heuristic fallback without adding a remote dependency. |
| FM output is missing fields, malformed, or contradictory | Reject the FM payload and fall back to heuristics or an empty suggestion rather than parsing arbitrary prose. |
| User-entered values would be overwritten by a suggestion | Apply only blank or default fields and keep non-empty or non-default values unchanged. |
| Partial input is too vague to infer anything useful | Return an empty suggestion and show a no-op message in the form instead of inventing data. |
| Full Xcode is unavailable or points at Command Line Tools | Report the exact command and blocker and keep build or test claims `unverified`. |
| `snyk` is unavailable | Report the exact blocker and keep the security scan claim `unverified`. |

## Out Of Scope

- Any Siri, App Intents, Spotlight, or `AssistantSchema` work.
- Inventory auto-save, background completion, or multi-item bulk import.
- New inventory fields or persistence migrations.
- Completion for notes, checklists, handbook content, or imported knowledge.
- Remote AI, server-side parsing, analytics, or account-linked personalization.
- Deep UI redesign of the inventory create or edit experience.

## Alternative Solutions

1. Preferred: one bounded completion service with FM structured output plus deterministic heuristics, wired into the shared form through the existing environment seam. Pros: aligns with repository boundaries, works on supported and unsupported devices, and stays easy to test. Cons: requires careful merge rules and platform gating.
2. Fallback A: heuristics-first implementation with the FM branch stubbed behind the same service contract if the installed SDK cannot yet support structured output safely. Pros: preserves milestone momentum and keeps the UI contract stable. Cons: less intelligent on FM-capable devices until the follow-up lands.
3. Fallback B: preview suggestions in a lightweight confirmation sheet before applying them instead of applying blank-field merges directly. Pros: extra user control. Cons: more UI work and more scope than the narrow M6P3 milestone needs.

## Report Format

When implementation is complete, report back in this structure:

1. Files added and files changed.
2. Completion service contract and where it lives.
3. FM availability strategy used and whether the structured-output path compiled on the current SDK.
4. Heuristic fallback behaviors implemented.
5. Inventory form UX change and merge rules applied.
6. Test evidence, build evidence, and manual validation evidence.
7. Security scan result or exact blocker.
8. Any remaining `unverified` claims or deferred follow-up.
