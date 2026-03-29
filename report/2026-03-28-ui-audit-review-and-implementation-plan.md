Date: 2026-03-28
Subject: UI audit verification pass and implementation plan
Status: Reviewed, partially verified, ready for backlog execution

## Target

Source reviewed:

- `UI_Audit_and_Improvement_Opportunities.md`

Repo sources checked during this review:

- `AGENTS.md`
- `CLAUDE.md`
- `CONSTITUTION.md`
- `DIRECTIVES.md`
- `docs/sdlc/00-doc-suite-index.md`
- `docs/sdlc/02-prd.md`
- `docs/sdlc/03-mvp-scope-roadmap.md`
- `docs/sdlc/04-information-architecture-and-ux-flows.md`
- `docs/sdlc/05-technical-architecture.md`
- `docs/sdlc/06-data-model-local-storage.md`
- `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md`
- `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`
- `docs/sdlc/10-security-privacy-and-safety.md`
- `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- `docs/adr/ADR-0001-offline-first-local-first.md`
- `docs/adr/ADR-0002-grounded-assistant-only.md`
- `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`
- `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`

## Verdict

WARN

The audit is directionally useful and correctly identifies several real UI gaps, especially around accessibility coverage, Home complexity, and the lack of explicit motion and skeleton states. It should not be implemented literally as written. A few findings are stale, some items are only inferential and need runtime validation, and several recommendations require product-policy decisions before code work starts.

## Findings

- [high] Emergency Mode presentation finding is stale.
  Issue: the audit says `EmergencyModeView` is presented as a `.sheet`, then recommends moving it to `.fullScreenCover`.
  Evidence: `OSA/Features/Home/HomeScreen.swift` already uses `.fullScreenCover` for Emergency Mode.
  Correction: remove that item from the backlog. Keep only follow-up improvements such as stronger exit copy, better contrast, and persistent emergency CTA behavior.

- [high] The ConnectivityBadge touch-target item is misclassified.
  Issue: the audit treats `ConnectivityBadge` as a tappable control and applies the 44x44 rule.
  Evidence: `OSA/Shared/Components/ConnectivityBadge.swift` has no interaction handler and is used as status display in `HomeScreen` and `SettingsScreen`.
  Correction: do not spend time enlarging the badge as if it were a button. Focus touch-target remediation on actual small controls: the Ask submit button, toolbar pin buttons, and any other measured interactive icons.

- [medium] The accessibility and animation findings are supported by code inspection, but several compliance findings remain unverified until runtime inspection.
  Evidence:
  - `6` `.accessibilityLabel(...)` usages in `OSA/`
  - `0` `.accessibilityHint(...)` usages
  - `0` `.accessibilityValue(...)` usages
  - `0` explicit `withAnimation`, `.animation`, `.transition`, or `contentTransition` usages in `OSA/Features` and `OSA/Shared`
  - `HomeScreen.swift` is `1,241` lines
  Correction: treat contrast failures, AX5 layout risk, VoiceOver order, and gloved/wet-screen concerns as validation tasks until confirmed with Accessibility Inspector, Simulator accessibility sizes, and manual device checks.

- [medium] Some recommendations need product and policy review before implementation.
  Issue:
  - Voice input adds speech recognition permissions and user-facing disclosure work.
  - Audible SOS is safety-sensitive and needs deliberate product review.
  - "Mark as reviewed" on handbook sections would blur editorial review state and user state.
  - Keyboard shortcuts are low-priority relative to an iPhone-first MVP.
  Evidence:
  - `docs/sdlc/10-security-privacy-and-safety.md` says to minimize permissions.
  - `docs/sdlc/02-prd.md` and `docs/sdlc/04-information-architecture-and-ux-flows.md` define an iPhone-first product.
  - `AGENTS.md` and `DIRECTIVES.md` require editorial content and user state to stay separated.
  Correction: keep these items out of the initial implementation wave unless product explicitly approves them and the docs are updated where needed.

- [low] A few report statements are framed as "not audited" even though the current code does show likely gaps.
  Evidence:
  - `OSA/Features/Weather/WeatherAlertRow.swift` is an interactive `Button` with no explicit accessibility label or hint.
  - `OSA/Features/Weather/WeatherForecastRow.swift` has no explicit accessibility grouping or value treatment.
  - `OSA/Features/Maps/MapAnnotationPin.swift` has no accessibility treatment.
  Correction: include Weather and Map in the accessibility pass instead of treating them as optional follow-up.

## Planning Principles

1. Fix compliance and stress-state usability before visual polish.
2. Prefer measured validation over inferred defects where static inspection is insufficient.
3. Keep offline-first, local-first, and grounded-assistant rules unchanged.
4. Avoid new permissions or data-model changes unless the user value clearly justifies them.
5. Extract only the shared UI primitives that are immediately needed for consistency and risk reduction.

## Implementation Plan

### Phase 0: Validation Baseline

Goal:

- Turn inferred audit items into a verified defect list before broad UI changes begin.

Work:

- Run a screen-by-screen accessibility audit for `Home`, `Ask`, `Emergency Mode`, `Quick Cards`, `Checklists`, `Inventory`, `Notes`, `Settings`, `Map`, and `Weather`.
- Verify touch-target sizes on actual interactive controls.
- Verify Dynamic Type at AX1 through AX5 in portrait and landscape.
- Run light-mode and dark-mode contrast checks on hero gradients, badge text, metadata text, and disabled states.
- Record exact VoiceOver order, heading behavior, and focus problems per screen.

Evidence targets:

- Accessibility Inspector captures or written findings
- AX-size screenshots for the critical flows
- measured contrast results

Notes:

- This phase should close or downgrade stale audit items before they turn into implementation work.

### Phase 1: Accessibility Compliance Pass

Goal:

- Close the highest-priority compliance and usability gaps without changing product scope.

Primary files:

- `OSA/Features/Home/HomeScreen.swift`
- `OSA/Features/Ask/AskScreen.swift`
- `OSA/Features/Home/EmergencyModeView.swift`
- `OSA/Features/QuickCards/QuickCardsScreen.swift`
- `OSA/Features/QuickCards/QuickCardDetailView.swift`
- `OSA/Features/Library/HandbookSectionDetailView.swift`
- `OSA/Features/Checklists/ChecklistsScreen.swift`
- `OSA/Features/Checklists/EmergencyProtocolView.swift`
- `OSA/Features/Inventory/InventoryScreen.swift`
- `OSA/Features/Settings/SettingsScreen.swift`
- `OSA/Features/Maps/MapScreen.swift`
- `OSA/Features/Maps/MapAnnotationPin.swift`
- `OSA/Features/Weather/WeatherAlertRow.swift`
- `OSA/Features/Weather/WeatherForecastRow.swift`
- `OSA/Shared/Components/ConnectivityBadge.swift`

Work:

- Add missing `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`, and grouping modifiers to composed rows, badges, and progress UI.
- Add `.accessibilityAddTraits(.isHeader)` to section headers where appropriate.
- Add `@AccessibilityFocusState` for Ask answer loading completion and Emergency Protocol step progression.
- Raise actual small interactive targets to 44x44 minimum, starting with the Ask send button and toolbar pin buttons.
- Add AX-safe text handling for large sizes using `lineLimit`, layout fixes, and `minimumScaleFactor` where justified.
- Make progress indicators and readiness metrics readable to VoiceOver users.

Acceptance:

- VoiceOver traversal is coherent on the top stress-critical screens.
- No known critical interactive control remains below the minimum target.
- AX5 layouts remain usable on iPhone 16 Simulator.

### Phase 2: Shared UI Primitives And Home Decomposition

Goal:

- Reduce maintenance risk before broadening visual changes across the app.

Primary files:

- `OSA/Features/Home/HomeScreen.swift`
- new shared UI components under `OSA/Shared/Components/`

Work:

- Split `HomeScreen.swift` into smaller view components for header, readiness, pinned content, spotlight, suggestions, checklist, inventory, and notes sections.
- Extract only the shared primitives already justified by current duplication:
  - card surface variants for hero/surface/elevated cards
  - a padded toolbar icon button pattern
  - a reusable skeleton placeholder component
  - an in-app banner/toast component for transient status changes

Acceptance:

- `HomeScreen` is materially smaller and easier to modify safely.
- Shared components are used by more than one screen and do not add speculative abstraction.

### Phase 3: Stress-Critical UX Improvements

Goal:

- Improve the highest-value flows under stress without widening product scope.

Primary files:

- `OSA/Features/Home/HomeScreen.swift`
- `OSA/Features/Ask/AskScreen.swift`
- `OSA/Features/Home/EmergencyModeView.swift`
- `OSA/Features/Home/OnboardingFlowView.swift`

Work:

- Home:
  - hide empty lower-priority sections instead of always rendering empty-state cards
  - add persisted collapse state only for sections that genuinely add cognitive load
  - keep the fastest routes to emergency content obvious
- Ask:
  - replace the centered spinner with an answer-shaped skeleton state
  - increase the send button to at least 44x44
  - add a clear-text affordance
  - add suggested questions and a short recent-query list using lightweight local persistence
- Emergency Mode:
  - increase hero contrast
  - change the dismiss affordance copy from generic "Close" to explicit emergency-exit language
  - keep emergency actions large and obvious
  - evaluate a persistent `Call 911` affordance once the layout work is in place
- Onboarding:
  - convert the single-form flow into 2 to 3 focused steps
  - keep the existing personalized setup logic
  - add progress indication, skip handling, and a final "your setup is ready" payoff screen

Acceptance:

- Home shows less empty chrome for new or sparse users.
- Ask teaches scope better and feels more usable before first query.
- Onboarding better demonstrates immediate value without adding network dependency.

### Phase 4: List Ergonomics And Discoverability

Goal:

- Improve findability and common list actions using existing repository and search boundaries.

Primary files:

- `OSA/Features/QuickCards/QuickCardsScreen.swift`
- `OSA/Features/Notes/NotesScreen.swift`
- `OSA/Features/Checklists/ChecklistsScreen.swift`
- `OSA/Features/Inventory/InventoryScreen.swift`
- `OSA/Features/Inventory/InventoryItemDetailView.swift`

Work:

- Add `.searchable` support to Quick Cards, Notes, and Checklists using the existing `SearchService` rather than feature-local persistence access.
- Replace generic empty states with actionable next steps.
- Add swipe actions where the underlying behavior already exists or is trivial:
  - Inventory: archive
  - Checklists: delete run, resume
  - Quick Cards: pin or unpin
- Re-evaluate "restock" and "pin note" separately:
  - restock needs a clear domain rule
  - note pinning needs new user-state modeling and is not a UI-only change
- Add context menus only for actions that already fit the model.

Explicit non-goal in this phase:

- Do not implement "Mark as reviewed" on handbook content. If a read-state feature is desired later, model it as separate user state with distinct language such as "Mark as read."

Acceptance:

- Users can search and act on more content without leaving the current screen.
- No new feature-layer code depends directly on SwiftData types or persistence details.

### Phase 5: Motion, Haptics, Connectivity Feedback, And Settings Polish

Goal:

- Add polish only after accessibility and core flow clarity are in place.

Primary files:

- `OSA/Features/Home/HomeScreen.swift`
- `OSA/Features/Ask/AskScreen.swift`
- `OSA/Features/QuickCards/QuickCardDetailView.swift`
- `OSA/Features/Checklists/ChecklistRunView.swift`
- `OSA/Features/Checklists/EmergencyProtocolView.swift`
- `OSA/Features/Settings/SettingsScreen.swift`
- `OSA/Shared/Components/ConnectivityBadge.swift`
- shared banner and skeleton components added in Phase 2

Work:

- Add targeted transitions and `withAnimation` blocks for clearly bounded state changes.
- Respect Reduce Motion when introducing new animation.
- Expand haptic coverage to refresh completion, checklist completion, import completion, and visible error states.
- Add a transient connectivity-state banner for online/offline transitions.
- Reorder and clarify Settings sections, especially around Emergency Contacts and Accessibility.

Acceptance:

- Motion explains state change without becoming decorative noise.
- Connectivity changes are visible without blocking local use.

## Deferred Or Gated Items

These should not enter the first implementation wave without explicit approval:

- Voice input via `SFSpeechRecognizer`
- Audible SOS alarm
- red-tinted night-vision mode
- keyboard shortcuts as a meaningful deliverable
- Liquid Glass / iOS 26 aesthetic adaptation
- note pinning or editorial-content user-review flags

Reason:

- They either add permissions, introduce new user-state modeling, or sit outside the highest-value iPhone-first MVP work.

## Verification Plan For Implementation

Automated checks when code lands:

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Recommended additional verification:

- Extend `OSAUITests` for:
  - onboarding step progression
  - Ask zero-state suggestions and recent-query persistence
  - new search surfaces
  - new swipe actions
  - connectivity banner presence
- Add manual QA coverage for:
  - VoiceOver traversal
  - AX1 to AX5 content sizes
  - light/dark contrast
  - Reduce Motion
  - emergency-flow usability under offline and degraded connectivity

Blocked or later-only verification:

- speech-permission flows
- gloved-hand testing
- wet-screen testing
- low-light and bright-light testing

Those require device-level manual QA and should remain `unverified` until run.

## Bottom Line

The audit is useful as a backlog seed, but it needs filtering before execution. The correct order for OSA is:

1. verify the inferred defects
2. land the accessibility and touch-target fixes
3. reduce `HomeScreen` complexity and add shared UI primitives
4. improve the stress-critical flows in `Home`, `Ask`, `Emergency Mode`, and onboarding
5. add search, swipe, motion, haptics, and settings polish

Anything that adds permissions, mixes editorial and user state, or optimizes for non-core devices should stay gated until the core accessibility and stress-state work is complete.
