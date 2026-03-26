# Lantern Branding And UI Polish Sprint

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** This sprint is a cross-surface presentation pass that likely touches 8-12 existing SwiftUI files plus shared design-system files. It stays inside the current architecture, but it requires coordinated updates across shared tokens, emergency-first hierarchy, Quick Cards presentation, Ask trust cues, and consistency states without widening product scope.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | The request is to "Proceed with the Branding & UI polish sprint," which implies execution of a release-focused visual and interaction pass rather than new product capability work. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Preserve offline-first behavior, keep changes proportional, stay inside presentation boundaries where possible, and report any blocked verification as `unverified`. |
| `docs/sdlc/02-prd.md` | OSA is an offline-first iPhone preparedness app whose core value is calm, local, trustworthy access to handbook content, quick cards, organizer data, and a grounded Ask surface. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | Major milestone work is already in place; this sprint should polish the existing product before further expansion, not add new capabilities. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Home is the launch surface, Quick Cards are central to product identity, Home and Quick Cards must be the fastest stress-state path, and the current 4-primary-tab plus `More` model should stay intact. |
| `docs/sdlc/05-technical-architecture.md` | Keep the work in `App`, `Features`, and `Shared`; do not cross into persistence, retrieval, or networking changes unless a presentation-only change cannot avoid a small wiring adjustment. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Ask must remain a bounded, cited, local retrieval tool, not a general chatbot. UI polish must reinforce that boundary instead of softening it. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Quality risks for this sprint are readability, stress-state usability, state clarity, and regressions in offline/core flows; verification must include build, tests, and manual UI review. |
| `docs/prompt/enhanced/20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md` | Prior OSA polish prompts are explicit, file-aware, and tightly bounded. This sprint should follow the same pattern while focusing on brand consistency and UI cohesion. |
| Current UI surfaces | The design system is still minimal, `ConnectivityBadge` is generic, Quick Cards are functional but visually plain, Home already has live data but can better express emergency-first brand identity, and several empty/loading/failure states remain inconsistent across screens. |

## Mission Statement

Deliver a release-focused branding and UI polish sprint that makes Lantern feel cohesive, calm, and trustworthy under stress by strengthening shared visual tokens, emergency-first hierarchy, and local-trust cues across existing SwiftUI surfaces without changing the app's navigation model, offline-first contract, or assistant scope.

&lt;technical_context&gt;

## Technical Context

The current codebase already contains the product structure that this sprint should polish rather than redesign. The highest-value work is not new capability work. It is the consolidation of visual language and state communication across the surfaces users hit first and most often.

Primary code surfaces and why they matter:

- `OSA/Shared/DesignSystem/ColorTokens.swift` defines the semantic color starting point, but it currently exposes only a small set of generic surface tokens.
- `OSA/Shared/DesignSystem/Typography.swift` defines a minimal type scale that can be expanded or refined for stronger hierarchy without introducing new UI architecture.
- `OSA/Shared/Components/ConnectivityBadge.swift` is the main reusable expression of offline and online state, but its current treatment is generic and not yet strongly integrated with the Lantern brand tone.
- `OSA/Shared/Support/AppBrand.swift` and `OSA/Shared/Components/BrandMarkView.swift` establish the shipped Lantern identity and should remain the source of truth for brand presentation.
- `OSA/Features/Home/HomeScreen.swift` is already repository-backed and therefore the correct launch surface for an emergency-first visual pass.
- `OSA/Features/QuickCards/QuickCardsScreen.swift` and `OSA/Features/QuickCards/QuickCardDetailView.swift` are the most natural place to make the app feel distinct, because Quick Cards are already documented as central to product identity and stress-state use.
- `OSA/Features/Ask/AskScreen.swift` already supports grounded citations and scope control, but it still needs stronger locality, confidence, and refusal-state hierarchy so it reads as a bounded tool rather than a chat surface.
- `OSA/App/Navigation/AppTabView.swift` and `OSA/App/Navigation/AppTab.swift` define the current 4-primary-tab plus `More` structure, which should be polished but not reorganized.
- `OSA/Features/Library/LibraryScreen.swift`, `OSA/Features/Inventory/InventoryScreen.swift`, `OSA/Features/Checklists/ChecklistsScreen.swift`, `OSA/Features/Notes/NotesScreen.swift`, and `OSA/Features/Settings/SettingsScreen.swift` should share a more consistent card, row, and state-treatment language after the sprint.

Why this approach is correct:

- The product contract values speed, legibility, and trust over decorative novelty.
- The shared design system is still small enough that targeted semantic-token expansion will improve many screens at once.
- Quick Cards and Home carry the most visible stress-state UX burden, so polishing them first produces the highest leverage.
- Ask polish must clarify product boundaries, not blur them. Stronger local-trust cues reduce user confusion about what Ask can and cannot do.
- A presentation-layer sprint is the smallest coherent next step before broader hardening and launch preparation.

Key rules this prompt must enforce:

- Preserve the current top-level IA and offline-first behavior.
- Keep Quick Cards and Home as the fastest stress-state routes.
- Keep Ask grounded, local, and cited.
- Keep persistence, retrieval, and networking behavior unchanged unless a trivial presentation-only wiring change is strictly necessary.
- Prefer extracting shared UI primitives over repeating another screen-local styling patch.
- Treat accessibility, Dynamic Type, contrast, and one-handed readability as sprint deliverables, not follow-up work.

&lt;/technical_context&gt;

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Shared design system | Generic surface tokens and minimal typography encourage per-screen styling drift. | Semantic tokens and reusable presentation primitives define a consistent Lantern visual language. |
| Home | Live data exists, but the header and dashboard treatment do not fully express emergency-first hierarchy or brand identity. | Home feels like the calm, trusted launch surface with stronger local/offline cues and a clearer quick-route emphasis. |
| Quick Cards | Functional browse and detail views are readable but visually plain and under-leveraged as the signature product surface. | Quick Cards become the clearest expression of Lantern's large-type, stress-state identity. |
| Ask | The feature is grounded, but the screen can still read like a generic chat interface rather than a bounded local retrieval tool. | Ask visually communicates local scope, confidence, citations, and refusal boundaries with higher clarity. |
| Cross-feature states | Empty, loading, and failure treatments vary across screens and feel inconsistent. | State treatments are shared, intentional, and recognizably local-first. |
| Navigation identity | The current tab shell works, but the visual continuity between the 4 primary tabs and `More` grouping is utilitarian. | Navigation retains the same IA while presenting a more coherent visual identity and discoverability story. |

&lt;pre_flight_checks&gt;

## Pre-Flight Checks

1. Verify you are in the repository root.

```bash
pwd
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
```

*Success: commands run from the repository that contains `project.yml`, `OSA.xcodeproj`, and `docs/`.*

1. Verify the primary UI files for this sprint exist before planning edits.

```bash
test -f OSA/Shared/DesignSystem/ColorTokens.swift \
  && test -f OSA/Shared/DesignSystem/Typography.swift \
  && test -f OSA/Shared/Components/ConnectivityBadge.swift \
  && test -f OSA/Features/Home/HomeScreen.swift \
  && test -f OSA/Features/QuickCards/QuickCardsScreen.swift \
  && test -f OSA/Features/QuickCards/QuickCardDetailView.swift \
  && test -f OSA/Features/Ask/AskScreen.swift \
  && test -f OSA/App/Navigation/AppTabView.swift \
  && echo "ui polish surfaces present"
# Expected: ui polish surfaces present
```

*Success: the shared design system, Home, Quick Cards, Ask, and navigation shell are all present and ready for inspection.*

1. Confirm build verification is possible with full Xcode.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success: the environment can run the required `xcodebuild` verification commands, or the blocker is documented before implementation starts.*

1. Inspect the current visual baseline before editing.

```bash
rg --line-number "ContentUnavailableView|foregroundStyle\(|background\(|font\(" OSA/Features OSA/Shared
```

*Success: you can identify where styling is already shared and where repeated screen-local patterns should be consolidated.*

1. Freeze the scope to presentation and shared UI work.

*Success: the planned file list stays inside `OSA/App`, `OSA/Features`, and `OSA/Shared`, with no intentional persistence, retrieval, networking, or content-model changes.*

&lt;/pre_flight_checks&gt;

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Freeze

1. Read the current implementations of the shared design-system files and the existing Home, Quick Cards, Ask, and navigation files before editing.

   *Success: you can name the duplicated visual patterns, the weak hierarchy points, and the shared-state cues that need refinement.*

2. Inventory the current empty, loading, failure, badge, card, and metadata-row treatments across `LibraryScreen`, `InventoryScreen`, `ChecklistsScreen`, `NotesScreen`, `QuickCardsScreen`, `HomeScreen`, and `SettingsScreen`.

   *Success: you have a short list of repeated patterns that can be unified without changing feature behavior.*

3. Define a minimal shared-UI plan before changing code: semantic tokens first, then shared primitives, then targeted screen updates.

   *Success: the implementation path reduces styling drift instead of layering more screen-local overrides on top of it.*

**Rationale:** The design-system layer is still compact. Strengthening it first is the fastest way to improve multiple screens without creating a broad refactor.

### Phase 2: Shared Brand And Status Foundation

1. Expand `OSA/Shared/DesignSystem/ColorTokens.swift` with semantic presentation tokens that cover calm emphasis, urgency, reviewed and trust cues, and connectivity states.

   *Success: screens can reference shared semantic colors instead of ad hoc `.orange`, `.blue`, or one-off system color choices for meaning-bearing UI.*

2. Refine `OSA/Shared/DesignSystem/Typography.swift` so the product has a clearer hierarchy for section headers, metadata labels, stress-state large text, and source or status captions.

   *Success: typography hierarchy is strong enough that Home, Quick Cards, Ask, and list rows do not need to invent their own type semantics.*

3. Update `OSA/Shared/Components/ConnectivityBadge.swift` and any closely related shared badge treatment to match the semantic token system and remain legible in light mode, dark mode, and at larger Dynamic Type sizes.

   *Success: connectivity and local-status cues read consistently and do not rely on color alone.*

4. Keep Lantern identity grounded in the existing brand sources in `OSA/Shared/Support/AppBrand.swift` and `OSA/Shared/Components/BrandMarkView.swift`.

   *Success: brand presentation is refined through shared styling and layout, not by inventing a second brand language or renaming the product.*

### Phase 3: Home And Quick Cards As The Signature Surfaces

1. Rework the Home header and section presentation in `OSA/Features/Home/HomeScreen.swift` to strengthen brand hierarchy, local and offline trust cues, and immediate scannability while preserving the existing repository-backed data flow.

   *Success: Home feels intentionally branded, clearly local, and stress-state friendly without losing the live data already wired in M3.*

2. Add a clearer visual emphasis for the fastest route into Quick Cards from Home without changing the current navigation model or adding a new product surface.

   *Success: Quick Cards are more obviously the emergency-first path while Home remains uncluttered.*

3. Polish `OSA/Features/QuickCards/QuickCardsScreen.swift` so card rows, category cues, and reviewed-state metadata feel like a first-class product surface rather than a generic list of content records.

   *Success: Quick Card browse rows have stronger hierarchy, clearer metadata, and more distinct Lantern character.*

4. Polish `OSA/Features/QuickCards/QuickCardDetailView.swift` for large-type readability, low-chrome focus, and calm trust cues such as review metadata or related provenance indicators where already available.

   *Success: Quick Card detail feels optimized for one-handed, fast reading under stress and remains the most visually intentional surface in the app.*

**Rationale:** `docs/sdlc/04-information-architecture-and-ux-flows.md` explicitly treats Quick Cards as central to product identity. This sprint should reflect that in the visible UI.

### Phase 4: Cross-Surface Consistency And Navigation Identity

1. Extract or apply shared card, row, and state-treatment primitives in `OSA/Shared` wherever that reduces repeated styling across `LibraryScreen`, `InventoryScreen`, `ChecklistsScreen`, `NotesScreen`, and `SettingsScreen`.

   *Success: these screens share a recognizable metadata hierarchy and state language without changing their feature-specific behavior.*

2. Replace inconsistent empty, loading, and failure treatments with a more intentional local-first presentation style across the touched screens.

   *Success: zero and error states feel product-specific, calm, and informative rather than generic or accidental.*

3. Polish `OSA/App/Navigation/AppTabView.swift` and `OSA/App/Navigation/AppTab.swift` only for visual continuity, icon consistency, and `More` discoverability.

   *Success: the existing 4-primary-tab plus `More` structure is easier to parse without changing IA, destination order, or top-level screen responsibilities.*

### Phase 5: Ask Trust Polish Without Scope Widening

1. Refine `OSA/Features/Ask/AskScreen.swift` so the scope card, answer card, citations, confidence indicators, and refusal state read more clearly as a bounded local retrieval interface.

   *Success: Ask looks less like open-ended chat and more like a cited, scope-aware local tool.*

2. Preserve the existing Ask contract while polishing it: keep local-only and citation-first cues prominent, keep confidence states distinct, and do not add conversational affordances that suggest unsupported general-chat behavior.

   *Success: the UI reinforces the current assistant policy instead of diluting it.*

### Phase 6: Verification, Accessibility, And Security

1. Run the required project build after the UI changes.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED
```

*Success: the project builds cleanly after the shared-token and UI updates.*

1. Run the test suite after the UI changes.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: TEST SUCCEEDED
```

*Success: existing behavior remains intact and no UI-linked regressions are introduced.*

1. Run a security scan if `snyk` is available.

```bash
command -v snyk >/dev/null && snyk code test --path="$PWD"
# Expected when available: scan completes and reports no newly introduced issues
```

*Success: any new first-party UI code is checked, or the absence of `snyk` is recorded as a verification blocker.*

1. Perform a manual simulator pass for the screens touched by the sprint, covering light mode, dark mode, larger Dynamic Type sizes, and the core offline-first read flows.

   *Success: Home, Quick Cards, Ask, and the `More` destinations remain legible, scannable, and trustworthy across the key display states.*

## Guardrails

&lt;guardrails&gt;

- Forbidden: changing the app's top-level information architecture, tab layout, or screen responsibilities.
- Forbidden: introducing onboarding, widgets, shortcuts, sync, export, analytics, permissions, or online-first behaviors.
- Forbidden: modifying persistence models, repository contracts, retrieval ranking, networking, or assistant policy logic unless a trivial presentation-only wiring fix is strictly required.
- Forbidden: making Ask feel more conversational if that weakens the local-only, cited, bounded product framing.
- Forbidden: animation-first polish that reduces legibility, slows access, or conflicts with Reduce Motion expectations.
- Required: keep Home and Quick Cards as the fastest stress-state surfaces.
- Required: use shared semantic tokens and reusable primitives where practical instead of repeating screen-local styling patches.
- Required: ensure status indicators are not color-only and remain understandable with Dynamic Type and VoiceOver.
- Required: keep the total change proportional to a polish sprint; do not convert this into a feature or architecture refactor.

&lt;/guardrails&gt;

## Verification Checklist

&lt;verification_checklist&gt;

- [ ] Prompt type is classified as `Feature`.
- [ ] Complexity is classified as `Complex` with justification.
- [ ] Shared semantic tokens exist for the UI meanings introduced by this sprint.
- [ ] Home better communicates Lantern identity, local trust, and emergency-first hierarchy.
- [ ] Quick Cards are the strongest visual surface for large-type, stress-state reading.
- [ ] Ask more clearly communicates local scope, citations, confidence, and refusal boundaries.
- [ ] Empty, loading, and failure states are more consistent across the touched screens.
- [ ] The current 4-primary-tab plus `More` model remains unchanged.
- [ ] Build verification passed, or the exact blocker is reported.
- [ ] Test verification passed, or the exact blocker is reported.
- [ ] Snyk verification ran when available, or the exact blocker is reported.
- [ ] Manual UI review covered light mode, dark mode, Dynamic Type, and core offline read flows.

&lt;/verification_checklist&gt;

## Error Handling Table

&lt;error_handling&gt;

| Error Condition | Resolution |
| --- | --- |
| Shared token expansion starts spreading into domain or persistence work | Stop and re-scope the sprint back to `App`, `Features`, and `Shared` presentation concerns. |
| A screen still needs one-off colors or typography after token updates | Add the smallest missing semantic token or shared style primitive instead of hardcoding a new per-screen override. |
| Dynamic Type causes clipping, truncation, or unreadable stacked metadata | Simplify the row layout, reduce simultaneous metadata, and favor vertical stacking over cramped horizontal treatments. |
| Ask polish starts implying unsupported chat behavior | Revert to clearer local-scope language, stronger citation prominence, and more conservative answer or refusal framing. |
| Quick Cards look more decorative than readable | Remove low-value chrome and prioritize contrast, spacing, and line-length control over visual flourish. |
| `xcodebuild` fails because full Xcode is unavailable | Record the exact `xcode-select -p` output and mark build or test claims `unverified`. |
| `snyk` is unavailable | Record that `snyk` is not installed or not on `PATH` and keep the security-verification claim `unverified`. |

&lt;/error_handling&gt;

## Out Of Scope

&lt;out_of_scope&gt;

- New product features or new app surfaces.
- New content packs, seed-content editorial expansion, or content-model changes.
- Any change to retrieval logic, assistant policies, or online import behavior.
- Replacing the navigation model or promoting additional tabs into the primary tab bar.
- A motion-design or haptics sprint beyond light, accessibility-safe polish already justified by the touched UI.

&lt;/out_of_scope&gt;

## Alternative Solutions

&lt;alternative_solutions&gt;

1. **Recommended: Shared-token-first polish pass.** Expand semantic tokens and shared primitives first, then update Home, Quick Cards, Ask, and secondary surfaces. Pros: best consistency and lowest long-term styling drift. Cons: touches more shared files up front.
2. **Time-boxed fallback: Home + Quick Cards + Ask only.** Limit the sprint to the three highest-leverage surfaces and defer cross-surface state normalization. Pros: fastest visible improvement before release. Cons: styling inconsistency remains in Library, Inventory, Checklists, Notes, and Settings.
3. **Minimal fallback: Status and hierarchy pass only.** Restrict work to Home header, connectivity or status cues, Quick Card detail readability, and Ask trust presentation. Pros: smallest blast radius. Cons: weaker brand cohesion and less payoff from the shared design system.

&lt;/alternative_solutions&gt;

## Report Format

&lt;report_format&gt;

When the sprint is complete, report in this structure:

1. Scope completed and any tasks intentionally deferred.
2. Files changed, grouped by shared design system, primary surfaces, and secondary surfaces.
3. Brand and token changes introduced, including any new semantic UI primitives.
4. Home, Quick Cards, Ask, and navigation polish outcomes.
5. Accessibility and stress-state readability notes.
6. Verification commands run and their exact outcomes.
7. Any remaining risks or claims left `unverified`.

&lt;/report_format&gt;
