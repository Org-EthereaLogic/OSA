# Implement Sprint 3 Motion Haptics And Settings Polish

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** This sprint is a UX-hardening slice across existing Home, Checklist, Settings, and connectivity surfaces. It should stay inside current view files, existing haptic abstractions, and current local settings patterns, but it likely touches 6-10 Swift files plus focused tests because the work spans motion, feedback, accessibility behavior, and settings information architecture.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 3 focuses on motion, haptic feedback, connectivity notifications, and settings organization and polish. |
| `AGENTS.md`, `CONSTITUTION.md`, `DIRECTIVES.md`, `CLAUDE.md` | Keep the change offline-first, local-first, minimally scoped, and evidence-backed. Do not invent new assistant, network, or persistence architecture for a polish sprint. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Home, Checklists, and Settings are core user-facing surfaces; UX polish should improve clarity and readiness under stress rather than add ornamental motion. |
| `docs/sdlc/05-technical-architecture.md` | Feature views should consume existing services through environment injection; cross-cutting polish should reuse current shared support and component seams instead of creating speculative managers. |
| `docs/sdlc/06-data-model-local-storage.md` | This sprint should not require schema changes; settings and UI polish should reuse current lightweight local storage patterns. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Favor focused unit and UI verification tied to the touched behaviors. Report blocked verification as unverified. |
| `OSA/Shared/Support/Haptics/HapticFeedbackService.swift` and `OSATests/HapticFeedbackServiceTests.swift` | OSA already has a centralized haptic vocabulary, descriptor mapping, and a `criticalHaptics` accessibility gate. Reuse and extend this seam rather than adding ad hoc UIKit generators in views. |
| `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Home/HomeSectionViews.swift` | Home already observes `ConnectivityState`, opens Emergency Mode with haptics, and renders multiple section cards, but state changes mostly appear instantly without guided motion or inline transition feedback. |
| `OSA/Features/Checklists/ChecklistRunView.swift` and `OSA/Features/Checklists/EmergencyProtocolView.swift` | Checklist surfaces already use haptics and, for emergency protocols, directional step transitions. These are the best anchors for polish that emphasizes stress-state clarity rather than decorative animation. |
| `OSA/Features/Settings/SettingsScreen.swift`, `OSA/Shared/Components/ConnectivityBadge.swift`, and `OSA/Domain/Settings/AccessibilitySettings.swift` | Settings already exposes accessibility toggles, emergency contacts, connectivity status, and discovery controls, but the organization is broad and the connectivity status is passive. |
| `OSAUITests/OSAAccessibilitySmokeTests.swift`, `OSAUITests/OSAFullE2EVisualTests.swift`, and `OSAUITests/OSAContentAndInputTests.swift` | The current suites already verify Settings accessibility controls, Home emergency entry, Library recent history, and basic content flows, so Sprint 3 should extend the smallest relevant tests instead of inventing new broad suites. |

## Assumptions

- Interpret `connectivity notifications` as in-app, app-owned status feedback tied to the existing `ConnectivityState` stream, not system notifications, push alerts, or background delivery.
- Interpret `settings organization` as reordering, grouping, and clarifying the current Settings content, not introducing a new settings architecture, onboarding flow, or additional persistence layer.
- Use subtle motion that improves state change comprehension and preserves stress usability. Do not add decorative animation that delays emergency actions or obscures content.
- Respect accessibility by using the system reduce-motion environment where appropriate and by preserving the existing `Critical haptics` opt-out behavior.
- Prefer extending the existing `AppHapticEvent` vocabulary only when a new event clearly represents a distinct app action; otherwise reuse current events.

## Mission Statement

Polish OSA’s stress-critical interaction surfaces by adding purposeful motion, consistent haptic feedback, clearer connectivity status feedback, and a better organized Settings screen using current Home, Checklist, Settings, and shared-component seams without changing the app’s data architecture or online trust boundaries.

## Technical Context

The implementation should stay tightly scoped to existing seams that already own the relevant behavior:

- `LiveHapticFeedbackService` already centralizes event mapping and accessibility gating, so haptic polish should be routed through `AppHapticEvent` instead of direct UIKit calls from views.
- `HomeScreen.observeConnectivity()` and `SettingsScreen.observeConnectivity()` already subscribe to the `ConnectivityService` state stream, making them the natural places to trigger lightweight UI feedback when connectivity changes.
- `ConnectivityBadge` already defines the visual language for offline, limited, usable, and sync-in-progress states, so connectivity polish should refine or complement that component rather than creating a second competing status model.
- `EmergencyProtocolView` already has directional transitions and CPR metronome pacing, and `ChecklistRunView` already plays toggle and completion haptics, so the checklist area is ready for consistent motion-and-feedback polish with minimal structural change.
- `SettingsScreen` already contains the main user-facing controls for preparedness profile, accessibility, emergency contacts, connectivity, and discovery; organization improvements should reshuffle or clarify the existing sections before adding new controls.

Use the smallest coherent implementation:

1. Reuse existing services, settings keys, and components before adding new helpers.
2. If two screens need the same connectivity callout or transition treatment, extract one small shared view or helper. Do not introduce a global toast or notification framework.
3. Keep new motion fast, interruptible, and accessibility-aware.
4. Keep emergency, checklist, and settings actions immediately reachable even when transitions are present.
5. Do not expand this sprint into Home redesign, assistant behavior, import logic redesign, or new persistent preferences beyond what the polish directly needs.

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Home readiness and hero transitions | Home content loads and swaps state abruptly; emergency entry already has haptics but section-level polish is minimal. | Home uses subtle state-aware transitions that clarify loading or refreshed content, preserve readability, and keep Emergency Mode immediate. |
| Checklist completion and protocol navigation | Checklist toggles and protocol navigation already fire haptics, but motion and feedback are inconsistent across checklist surfaces. | Checklist surfaces use a consistent feedback pattern for toggle, completion, step navigation, and metronome-adjacent controls without adding delay or ambiguity. |
| Connectivity feedback | Connectivity mostly appears as a passive badge or screen-specific fallback copy. | Users receive lightweight, local in-app feedback when connectivity becomes limited, usable, or actively refreshing, using the existing state model. |
| Settings organization | Settings exposes the right controls, but emergency contacts, accessibility, and discovery status compete in a long flat flow. | Settings groups high-value controls more coherently, makes emergency and accessibility controls easier to find, and clarifies connectivity or discovery status. |
| Accessibility alignment | Critical haptics are configurable, but motion polish could easily diverge from accessibility expectations if added casually. | Motion and haptics stay aligned with the current accessibility contract: reduced unnecessary movement, preserved labels and hints, and respect for haptic disablement. |

## Pre-Flight Checks

1. Verify the owning files before editing: `OSA/Features/Home/HomeScreen.swift`, `OSA/Features/Home/HomeSectionViews.swift`, `OSA/Features/Checklists/ChecklistRunView.swift`, `OSA/Features/Checklists/EmergencyProtocolView.swift`, `OSA/Features/Settings/SettingsScreen.swift`, `OSA/Shared/Components/ConnectivityBadge.swift`, and `OSA/Shared/Support/Haptics/HapticFeedbackService.swift`.
   *Success signal: every requested behavior has an explicit owning file before implementation begins.*

2. Confirm whether any new haptic event is actually needed.
   *Success signal: the implementation can explain which existing `AppHapticEvent` values are reused and why any new event is necessary if one is added.*

3. Confirm where connectivity transitions are already observed.
   *Success signal: Home and Settings state-stream observers are identified as the control path for any new connectivity feedback.*

4. Confirm whether reduce-motion handling can stay local to view code.
   *Success signal: no new persisted accessibility setting is introduced unless a concrete requirement cannot be met with the environment and existing toggles.*

5. Confirm the focused verification targets before coding.
   *Success signal: at least one haptics-focused unit test target and one Settings or Home UI verification target are identified up front.*

## Phased Instructions

### Phase 1: Bound The Polish Sprint To Existing Seams

1. Keep Sprint 3 limited to motion, haptics, connectivity feedback, and Settings organization on existing surfaces.
   *Success signal: no new domain models, repository protocols, onboarding flows, assistant features, or system-notification integrations appear in the change.*

2. Route all haptic changes through `OSA/Shared/Support/Haptics/HapticFeedbackService.swift`.
   *Success signal: no touched feature view creates or manages UIKit feedback generators directly.*

3. Treat connectivity notifications as app-local UI state derived from `ConnectivityState`.
   *Success signal: any new connectivity notice is driven by the current stream and remains visible only inside the app UI.*

### Phase 2: Add Purposeful Motion To Existing Home And Checklist Flows

1. Polish Home section appearance and state transitions in `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Home/HomeSectionViews.swift`.
   Prefer short transitions or content transitions that make state changes readable when Home sections load, refresh, or switch spotlight content. Keep Emergency Mode entry immediate and do not animate core actions in a way that adds friction.
   *Success signal: Home state updates feel intentional and readable without changing information hierarchy or delaying emergency entry.*

2. Polish checklist completion feedback in `OSA/Features/Checklists/ChecklistRunView.swift`.
   Add minimal visual reinforcement for item toggle and completion progress that complements the existing `.checklistItemToggle`, `.success`, and `.warning` haptics. Keep list interactions fast and compatible with accessibility.
   *Success signal: checklist toggles provide a clearer sense of completion progress without requiring new repository logic.*

3. Refine protocol-step transitions in `OSA/Features/Checklists/EmergencyProtocolView.swift`.
   Preserve the current directional model, but ensure transitions, focus movement, and haptics stay coherent when stepping forward, backward, or starting and pausing the CPR pace. Respect reduced-motion behavior when needed.
   *Success signal: emergency protocol navigation feels deliberate and stress-friendly, with clear step changes and no redundant motion.*

### Phase 3: Improve Connectivity Feedback Without Building A Global Notification System

1. Refine `OSA/Shared/Components/ConnectivityBadge.swift` so state changes are easier to perceive.
   Use small, purposeful polish such as animated state changes, improved sync-in-progress affordance, or clearer differentiated styling between limited and fully usable connectivity.
   *Success signal: the badge communicates state changes more clearly while preserving current labels and accessibility descriptions.*

2. Add lightweight connectivity change feedback to Home and or Settings using the existing observers in `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Settings/SettingsScreen.swift`.
   If a reusable inline banner or callout is justified, extract only one small shared component under `OSA/Shared/Components/`. Do not add a global toast manager or background notification layer.
   *Success signal: users can notice meaningful connectivity transitions such as returning online, limited connectivity, or refresh in progress from the screens that already surface network state.*

3. Align manual discovery feedback in `OSA/Features/Settings/SettingsScreen.swift` with connectivity state.
   Ensure discovery-related status text, disabled states, and any visual polish reinforce why actions are unavailable offline or constrained, and when refresh is active.
   *Success signal: Settings explains discovery availability and network status coherently without adding new backend behavior.*

### Phase 4: Reorganize Settings For Faster Stress-State Scanning

1. Rework section ordering and grouping in `OSA/Features/Settings/SettingsScreen.swift` to surface the most actionable controls sooner.
   Keep Preparedness Profile, Accessibility, Emergency Contacts, Connectivity, and Knowledge Discovery, but arrange them so emergency contacts and accessibility or feedback settings are easier to find. Use concise explanatory copy where grouping alone is not enough.
   *Success signal: Settings reads as a clearer progression from identity and readiness, to accessibility and emergency setup, to connectivity and optional discovery.*

2. Improve emergency-contact discoverability inside Settings.
   Reuse the existing local contact flow, but make the purpose of the section more obvious, especially its relation to the `I’m Safe` shortcut and emergency workflows.
   *Success signal: a user can quickly understand why emergency contacts matter and how to add or edit them without leaving Settings.*

3. Keep accessibility and feedback controls cohesive.
   Large print and critical haptics should remain easy to locate, with labels and hints that match the new motion and haptic polish delivered elsewhere in the sprint.
   *Success signal: Settings presents motion-adjacent accessibility controls clearly and the rest of the sprint honors those controls.*

### Phase 5: Verification And Quality

1. Extend unit coverage in `OSATests/HapticFeedbackServiceTests.swift` if the haptic vocabulary or descriptor mapping changes.
   Cover only the new or adjusted event semantics. Do not rewrite the suite if the behavior stays within current mappings.
   *Success signal: any haptic behavior change is backed by a deterministic test at the service layer.*

2. Extend the smallest relevant UI coverage in `OSAUITests/OSAAccessibilitySmokeTests.swift`, `OSAUITests/OSAFullE2EVisualTests.swift`, and or `OSAUITests/OSAContentAndInputTests.swift`.
   Focus on visible Settings organization, Home accessibility or emergency availability after motion changes, and any new user-visible connectivity feedback that can be asserted without brittle timing assumptions.
   *Success signal: UI verification proves the polished surface is still accessible and visibly wired in the running app.*

3. Run a simulator build after the implementation is complete.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

   *Success signal: the project builds successfully for the standard simulator destination.*

- Run a focused test pass for the touched surfaces.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/HapticFeedbackServiceTests -only-testing:OSAUITests/OSAAccessibilitySmokeTests -only-testing:OSAUITests/OSAFullE2EVisualTests -only-testing:OSAUITests/OSAContentAndInputTests
```

   *Success signal: the focused unit and UI checks for haptics, Settings accessibility, and visible polished flows pass, or any exact blocker is reported.*

- Run security scanning for the new first-party code if `snyk` is available.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
```

   *Success signal: Snyk Code completes, or the exact environment blocker is reported as unverified.*

## Guardrails

- Do not add new SwiftData models, migrations, or repository protocols for this sprint.
- Do not introduce a global animation manager, toast framework, notification center abstraction, or system-notification feature.
- Do not make Home or Settings dependent on connectivity beyond the current optional online enrichment behavior.
- Do not widen the meaning of `Critical haptics` into a new general feedback preference system unless there is a concrete requirement the existing setting cannot satisfy.
- Do not add long or looping animations that interfere with emergency actions, checklist completion, or screen readability.
- Do not reduce accessibility by hiding controls behind gestures, collapsing labels into icons, or depending on color alone for connectivity meaning.
- Preserve existing accessibility labels, hints, and focus behavior, and adjust them if any reordering or new inline status UI changes reading order.
- Keep any shared polish helpers small and justified by at least two touched call sites.

## Verification Checklist

- [ ] Home uses purposeful, low-friction transitions for the touched state changes.
- [ ] Checklist run interactions have coherent visual and haptic feedback.
- [ ] Emergency protocol navigation remains directional, accessible, and reduced-motion-safe.
- [ ] Connectivity state changes are more legible than the current passive badge-only behavior.
- [ ] Manual discovery feedback in Settings aligns with current connectivity state.
- [ ] Settings organization makes accessibility and emergency-contact controls easier to find.
- [ ] Emergency-contact purpose is clearer in Settings and still backed by the current local flow.
- [ ] Any haptic mapping changes are covered by focused unit tests.
- [ ] Focused build and test commands were run, or blockers were reported explicitly.
- [ ] Security scan was run when available, or the exact blocker was recorded.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Motion polish makes emergency or checklist flows feel slower | Reduce the transition to a shorter, clearer animation or replace it with a content transition. Prioritize immediacy over visual flourish. |
| A proposed connectivity notice needs state that is only available locally in one screen | Keep the notice local to that screen unless a second real call site justifies extraction. Do not build a global notification layer. |
| Haptic polish suggests several nearly identical new events | Reuse the existing `AppHapticEvent` values unless the user-facing meaning is genuinely distinct. Keep the vocabulary small. |
| Reduced-motion support complicates a new transition | Prefer a simpler opacity or content transition, or skip the motion entirely while preserving the same state change. |
| Settings reordering breaks UI tests that depend on scrolling assumptions | Update the smallest stable assertions needed for the new order instead of restoring a weaker information architecture just to preserve test order. |
| Connectivity feedback becomes too noisy during rapid state changes | Coalesce or gate repeated notices locally. Keep the signal tied to meaningful state transitions, not every render. |
| `xcodebuild` or `snyk` is unavailable in the environment | Report the exact command, failure mode, and date; mark the affected verification as unverified. |

## Out Of Scope

- New onboarding, tutorial, or walkthrough flows.
- New settings persistence architecture or cross-device sync of preferences.
- Assistant behavior changes, Ask UX redesign, or trusted-source import redesign.
- System notifications, background alerts, Live Activities, or push infrastructure.
- Broad visual redesign of Home, Settings, or Checklists beyond the motion, feedback, and organization work needed for this sprint.

## Alternative Solutions

1. **Connectivity feedback fallback:** If an inline notification view adds too much state complexity, keep the improvement inside `ConnectivityBadge` plus clearer screen-local explanatory text rather than adding another visual element.
2. **Motion fallback:** If animated transitions prove brittle or inaccessible, replace them with content transitions, progressive disclosure, or stronger static state cues rather than forcing motion.
3. **Settings organization fallback:** If moving whole sections creates test or navigation churn, keep the current section set and improve discoverability with stronger section headers, footers, and local callouts before introducing bigger structural changes.

## Report Format

When the sprint is complete, report back in this structure:

1. Source prompt quoted verbatim.
2. Files changed and any files added.
3. Motion and transition changes by surface.
4. Haptic changes and whether any `AppHapticEvent` mappings changed.
5. Connectivity feedback changes and where they appear.
6. Settings organization changes, especially around accessibility and emergency contacts.
7. Verification commands run and their outcomes.
8. Security scan outcome or exact blocker.
9. Assumptions, deferred work, and any explicitly unverified claims.
