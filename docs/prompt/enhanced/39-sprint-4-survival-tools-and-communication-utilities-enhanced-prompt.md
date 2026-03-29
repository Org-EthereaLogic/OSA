# Implement Sprint 4 Survival Tools And Communication Utilities

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** This sprint introduces a new offline utility surface with eight distinct tools, stress-state integration, deterministic calculator logic, timed signaling behavior, and focused UI and unit coverage. It should stay inside current navigation, shared-support, and accessibility seams without adding new permissions, persistence architecture, or online behavior, but it will likely touch 8-14 Swift files plus tests.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 4 is a feature slice for lightweight offline-ready survival and communication utilities: Morse, SOS light, whistle, timer or stopwatch, unit conversion, radio reference, signal mirror, and declination. |
| `AGENTS.md`, `CONSTITUTION.md`, `DIRECTIVES.md`, `CLAUDE.md` | Keep the implementation offline-first, minimally scoped, evidence-backed, and safe. Do not add speculative architecture, unverifiable claims, or hidden permissions. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | OSA should continue shipping practical offline value without backend or heavy remote dependencies; utility tooling fits only if it remains local and bounded. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Stress-state flows already prioritize Emergency Mode, Quick Cards, and large touch targets; new utilities should be easy to reach from existing navigation and remain usable offline. |
| `docs/sdlc/05-technical-architecture.md` | New UI belongs in `OSA/Features/*`; reusable deterministic logic should stay small and testable in shared support; feature code must not grow new persistence or networking boundaries. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Minimize permissions, keep everything on device, avoid live radio or camera behavior, and disclose limitations for safety-sensitive guidance such as signaling and compass math. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Favor focused unit tests for pure logic and focused UI tests for visible wiring; mark blocked verification as unverified. |
| `OSA/App/Navigation/AppTab.swift` and `OSA/App/Navigation/AppTabView.swift` | The `More` tab section is the concrete navigation seam for a new utility screen without disrupting the primary emergency-first tabs. |
| `OSA/Features/Home/EmergencyModeView.swift` | Emergency Mode already owns stress-state shortcuts, screen overlays, haptics, and large-target actions, making it the best place for a lightweight shortcut into the new tools surface. |
| `OSA/Features/Settings/SettingsScreen.swift` and `project.yml` | The current app already has location permission for maps and weather, but Sprint 4 must not add any new Info.plist privacy keys such as camera or microphone. |
| `OSAUITests/OSAAccessibilitySmokeTests.swift`, `OSAUITests/OSAContentAndInputTests.swift`, and `OSAUITests/OSAFullE2EVisualTests.swift` | Existing UI suites already validate More-tab navigation, Emergency Mode, and stress-friendly controls, so Sprint 4 should extend those suites rather than introduce a new broad UI harness. |

## Assumptions

- Implement `flashlight` and `signal mirror` as screen-based bright display tools, not hardware torch control, camera capture, AR, or reflective-device measurement.
- Implement the declination utility as an offline estimate based on manual coordinate entry and bundled reference data or interpolation, clearly labeled as approximate rather than instrument-grade.
- Keep the emergency radio feature as a static local reference card with legal and safety notes. Do not implement tuning, scanning, Bluetooth pairing, SDR support, or live reception.
- Implement the whistle tool with local playback only. Prefer generated tone or a bundled local sound. Do not request microphone access or record audio.
- Keep timer and stopwatch behavior app-local and foreground-safe. Do not expand the sprint into background alerts, Live Activities, notifications, or Health integrations.

## Mission Statement

Add a new offline Survival Tools surface that provides Morse signaling, bright-screen SOS and signal mirror modes, whistle playback, timer or stopwatch utilities, unit conversion, radio reference information, and a bounded declination estimate without introducing new permissions, network behavior, or persistence architecture.

## Technical Context

This sprint should land as a bounded feature layer, not as a new subsystem.

- The best navigation seam is the existing `More` section in `OSA/App/Navigation/AppTabView.swift`; that keeps the tools first-class without displacing `Home`, `Library`, `Ask`, `Inventory`, or `Map`.
- `EmergencyModeView` already owns high-stress shortcuts, haptics, and display overlays, so it should link into the new tools screen rather than reimplement these utilities in place.
- The feature should use one small shared support file for deterministic logic and bundled reference data, for example Morse encoding, unit factors, radio entries, and declination interpolation inputs. Keep this pure and testable.
- Screen brightness, timed pulses, haptics, and local audio playback can all work without new privacy permissions if implemented as app-local display and audio behaviors.
- Do not add SwiftData models, settings persistence, repository protocols, network clients, or assistant integrations for this sprint. These are transient utilities and reference aids, not durable user records.

Use the smallest coherent implementation:

1. Add one new `Tools` destination under `OSA/Features/Tools/`.
2. Add one small pure helper for math, reference data, and encoding.
3. Keep visual and playback state local to the feature screen or narrowly scoped helper types.
4. Reuse existing design-system colors, typography, spacing, and haptic services.
5. Prefer clear limitations copy over pseudo-precision or unsupported hardware integrations.

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Navigation | OSA has no dedicated utilities surface for signaling, timing, or field-reference tools. | `More` includes a `Tools` destination with an optional shortcut from Emergency Mode. |
| Signaling tools | The app has no Morse encoder, screen-flash SOS mode, or signal mirror aid. | Users can encode text to Morse, trigger a bright-screen SOS sequence, and use a bright mirror-style screen with a visual aiming aid entirely offline. |
| Audible signaling | Emergency Mode currently provides haptics for SOS but no whistle-like audible signal utility. | Users can trigger a local whistle simulator with clear start or stop state and no recording permission. |
| Time tools | There is no general timer or stopwatch utility outside checklist-specific timing. | Users can run a simple field timer and stopwatch with large controls and preset durations. |
| Reference tools | There is no conversion utility, radio-frequency reference card, or declination aid. | The app provides deterministic offline conversions, a local radio quick-reference card, and an approximate declination calculator with clear bounds. |
| Permissions and safety | Adding light, audio, or compass-style tools could easily tempt camera, microphone, or location expansion. | Sprint 4 stays inside current app permissions, remains local-only, and clearly labels limitations for safety-sensitive outputs. |

## Pre-Flight Checks

1. Verify the owning navigation and emergency files before editing: `OSA/App/Navigation/AppTab.swift`, `OSA/App/Navigation/AppTabView.swift`, and `OSA/Features/Home/EmergencyModeView.swift`.
   *Success signal: there is a concrete entry point for both normal browsing and stress-state access before tool implementation begins.*

2. Verify the permission baseline in `project.yml`.
   *Success signal: the sprint proceeds without adding `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, Bluetooth, Local Network, or other new privacy keys.*

3. Decide the audio implementation seam up front.
   *Success signal: the plan explicitly chooses either generated local tone playback or a bundled local whistle asset, and any resource-manifest impact is known before code is written.*

4. Identify the pure logic to isolate for tests.
   *Success signal: Morse encoding, conversion math, and declination estimation are assigned to a deterministic helper instead of being embedded in SwiftUI view bodies.*

5. Identify focused verification targets before coding.
   *Success signal: at least one unit-test file and one UI-test file are named up front for Sprint 4 coverage.*

## Phased Instructions

### Phase 1: Add A Bounded Tools Surface

1. Create a new feature folder under `OSA/Features/Tools/` and add a primary screen such as `SurvivalToolsScreen.swift`.
   Structure it into stress-friendly sections such as `Signal`, `Timing`, and `Reference`, with large tap targets and concise copy.
   *Success signal: the app has one clear offline utility destination rather than scattered one-off controls across unrelated screens.*

2. Add a `tools` case to `OSA/App/Navigation/AppTab.swift` and expose it inside the existing `More` tab section in `OSA/App/Navigation/AppTabView.swift`.
   Use a stable SF Symbol such as `flashlight.on.fill`, `dot.radiowaves.left.and.right`, or another field-utility icon that fits the current visual language.
   *Success signal: `Tools` appears in the More section and opens the new screen through the existing tab architecture.*

3. Add one stress-state shortcut from `OSA/Features/Home/EmergencyModeView.swift` into the tools surface.
   Keep the current Protocols, Quick Cards, and `I'm Safe` actions intact; add a single additional row or card rather than redesigning Emergency Mode.
   *Success signal: Emergency Mode offers a direct path to survival tools without losing its current primary shortcuts.*

4. Keep this sprint local-only and permission-stable.
   *Success signal: no new repository protocols, SwiftData models, settings keys, online clients, or privacy usage descriptions appear in the change.*

### Phase 2: Add Deterministic Logic And Local Reference Data

1. Add one small support file under `OSA/Shared/Support/` or `OSA/Shared/Support/Tools/` for pure logic and static data, for example `SurvivalToolKit.swift`.
   Include:
   - Morse alphabet mappings and tokenization helpers
   - unit categories and conversion factors
   - emergency radio reference entries and disclaimers
   - declination reference anchors and interpolation helpers
   *Success signal: the core math and reference behavior compiles without SwiftUI state or environment dependencies and is directly unit-testable.*

2. Implement Morse encoding as deterministic text-to-symbol logic.
   Support letters A-Z, digits, spaces between words, and a dedicated `SOS` preset. Unknown characters should be ignored or surfaced non-destructively rather than crashing the tool.
   *Success signal: a user-entered phrase produces a stable Morse output string and a stable playback token sequence.*

3. Implement unit conversion as deterministic local math.
   Cover the highest-value field conversions only, such as:
   - Fahrenheit and Celsius
   - miles and kilometers
   - feet and meters
   - pounds and kilograms
   - gallons and liters
   - ounces and milliliters
   *Success signal: the converter returns correct values locally with no network or repository dependency.*

4. Implement the declination calculation as an approximate offline helper.
   Use manual latitude and longitude entry or a small preset-region selection plus bundled reference points and interpolation. Present output as east or west declination plus a reminder such as `Add east, subtract west` only if the estimate is within the supported coverage area.
   *Success signal: the tool produces an approximate, clearly labeled local result or an explicit unsupported-area message instead of pretending to know unsupported coordinates.*

5. Implement the radio reference card as static local data.
   Include only vetted, non-interactive reference information such as NOAA weather radio ranges, marine VHF Channel 16, CB Channel 9, FRS or GMRS conventions, and amateur-radio calling-frequency examples if and only if they are clearly labeled as reference-only and licensing-dependent where applicable.
   *Success signal: the feature renders a static offline card with legal or safety disclaimers and no transmit or tuning behavior.*

### Phase 3: Build The Signal, Timing, And Reference UI

1. Implement a Morse signaling section in `OSA/Features/Tools/SurvivalToolsScreen.swift`.
   Provide:
   - text input
   - encoded Morse output
   - a one-tap `SOS` preset
   - play or pause signaling that uses screen flashes, haptics, or both
   *Success signal: users can enter text, see Morse output immediately, and trigger a visible local signal sequence offline.*

2. Implement a bright-screen `Flashlight` section as a screen-based light mode, not hardware torch control.
   Use a full-bright white or pale panel, optional temporary screen-brightness boost while the tool is active, and a clear `SOS` mode that reuses the Morse timing pattern.
   Restore previous screen brightness on exit when brightness was changed.
   *Success signal: the tool provides a visibly bright local screen signal mode without adding camera permission or AVCapture torch code.*

3. Implement a `Signal Mirror` section as a bright reflective-style screen aid.
   Use a bright high-contrast screen, a simple aiming reticle or alignment mark, and concise copy explaining that this is a screen-based signaling aid, not an optical mirror or sun-tracking system.
   *Success signal: the app offers a clear manual signaling aid with no camera, location, or motion permission expansion.*

4. Implement a `Whistle` section with local playback only.
   Prefer one of these bounded approaches:
   - generated tone playback through a small helper
   - bundled local whistle sound with simple start or stop playback
   Pair playback with existing haptic services where helpful, but do not require background audio or recording.
   *Success signal: the user can trigger and stop a local whistle-like alert from the tools screen with clear UI state.*

5. Implement a `Timer / Stopwatch` section with large controls and minimal modes.
   Support a stopwatch plus a countdown timer with a few preset durations such as 1, 5, 15, and 30 minutes. Keep timing local to the foreground session; do not add notifications or background execution claims.
   *Success signal: users can start, pause, resume, and reset timing utilities with large, legible controls.*

6. Implement a `Unit Converter` section and a `Radio Reference` section using the Phase 2 support data.
   Keep both deterministic and immediately readable, with no hidden advanced settings.
   *Success signal: conversion and reference content are available instantly offline from the same tools screen.*

7. Implement the `Declination` section with explicit limitations.
   Require manual input or supported presets, show approximate result text, and include a compact note such as `Approximate field reference only; verify against a current map when precision matters.`
   *Success signal: the declination utility is honest about coverage and precision rather than presenting exact-looking unsupported data.*

### Phase 4: Accessibility, Stress-State Usability, And Integration

1. Reuse existing design tokens, spacing, typography, and haptic vocabulary.
   Keep controls one-handed friendly, compatible with Dynamic Type, and easy to distinguish under stress.
   *Success signal: the new screen looks and behaves like OSA rather than a separate mini-app.*

2. Respect current accessibility and haptic controls.
   Any haptic behavior should flow through the existing environment service. Avoid motion-heavy transitions or noisy looping animations that would fight Emergency Mode readability.
   *Success signal: the tools remain accessible when large type or reduced-motion settings are active, and no direct UIKit haptic generators appear in feature code.*

3. Add short explanatory copy where the tool has real-world limits.
   This includes the screen-based light and mirror modes, radio reference legality, and declination precision.
   *Success signal: the feature teaches limits clearly enough that users are not misled about hardware capabilities or field accuracy.*

### Phase 5: Verification And Quality

1. Add a focused unit-test file such as `OSATests/SurvivalToolKitTests.swift`.
   Cover at minimum:
   - Morse encoding output for ordinary text and `SOS`
   - unit conversion correctness for representative values
   - declination interpolation or supported-area guarding
   - radio reference data integrity where meaningful
   *Success signal: the feature’s deterministic logic is covered without depending on SwiftUI rendering.*

2. Extend focused UI coverage in `OSAUITests/OSAContentAndInputTests.swift`, `OSAUITests/OSAAccessibilitySmokeTests.swift`, and or `OSAUITests/OSAFullE2EVisualTests.swift`.
   Cover at least:
   - navigating to `Tools` from `More`
   - visibility of the Morse or SOS controls
   - visibility of the converter and declination sections
   - accessibility of the Emergency Mode shortcut if one is added
   *Success signal: the new tools surface is visibly wired into the app and exposes its key controls to UI automation.*

3. If `project.yml` changes because a bundled whistle asset or new resource folder is introduced, regenerate the Xcode project first.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodegen generate
```

   *Success signal: `OSA.xcodeproj` matches the manifest before build verification continues.*

1. Run a simulator build after implementation completes.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

   *Success signal: the project builds successfully for the standard simulator destination.*

1. Run a focused test pass for Sprint 4 logic and visible UI wiring.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/SurvivalToolKitTests -only-testing:OSAUITests/OSAContentAndInputTests -only-testing:OSAUITests/OSAAccessibilitySmokeTests -only-testing:OSAUITests/OSAFullE2EVisualTests
```

   *Success signal: the focused unit and UI coverage for Sprint 4 passes, or the exact blocker is reported.*

1. Run first-party security scanning if `snyk` is available.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
```

   *Success signal: Snyk Code completes, or the exact environment blocker is reported as unverified.*

## Guardrails

- Do not add any new privacy permissions, especially camera, microphone, Bluetooth, Local Network, motion, or additional location usage keys.
- Do not implement hardware torch control, camera capture, audio recording, compass heading APIs, or live radio behavior in this sprint.
- Do not add SwiftData models, migrations, repository protocols, or saved-history features for the tools.
- Do not add online lookup, map downloads, assistant actions, Siri intents, or background-refresh behavior.
- Do not claim the declination output is survey-grade or current beyond the bundled reference data.
- Do not present the radio reference as legal authorization to transmit; include licensing or channel-use cautions where relevant.
- Do not introduce new third-party dependencies for audio, math, or animations.
- Keep shared helpers small and justified by actual reuse across multiple tools.

## Verification Checklist

- [ ] `Tools` appears in the More section and opens a dedicated survival-tools screen.
- [ ] Emergency Mode exposes a bounded shortcut to the new tools surface, if that shortcut is included.
- [ ] Morse encoding works for standard text and `SOS` without network or persistence.
- [ ] Bright-screen flashlight and SOS behavior work without hardware torch or camera permission.
- [ ] Signal mirror is implemented as a clear screen-based aid with explicit limitations.
- [ ] Whistle playback is local-only and requires no microphone permission.
- [ ] Timer and stopwatch support large start, pause, resume, and reset controls.
- [ ] Unit converter covers the intended field conversions with deterministic math.
- [ ] Radio reference content is static, offline, and appropriately caveated.
- [ ] Declination output is approximate, coverage-bounded, and clearly labeled.
- [ ] No new privacy usage descriptions or remote behaviors were introduced.
- [ ] Focused build and test commands were run, or blockers were reported explicitly.
- [ ] Security scan was run when available, or the exact blocker was recorded.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Screen brightness cannot be changed reliably in previews, tests, or simulator | Fall back to the bright white tool UI without brightness mutation; keep the tool functional and note that brightness boost is device-validated only. |
| Audio whistle playback is inconsistent in simulator or silent-mode conditions | Preserve the visible and haptic signal state, validate audio on device when available, and avoid claiming stronger guarantees than were tested. |
| Morse playback timing becomes hard to reason about in SwiftUI view code | Move token scheduling into a tiny deterministic helper or controller and unit-test the token sequence separately from the view. |
| Declination estimates are poor outside the intended coverage area | Show an unsupported-area or low-confidence message instead of extrapolating fake precision. |
| Adding a bundled whistle asset requires new resource wiring | Update `project.yml`, regenerate with `xcodegen generate`, and verify the resource is included before continuing. |
| UI tests become flaky because they wait on timed playback loops | Assert the visible control state and static output instead of trying to verify every pulse or audio burst timing in UI automation. |
| `xcodebuild` or `snyk` is unavailable in the environment | Report the exact command, failure mode, and date; mark the affected verification as unverified. |

## Out Of Scope

- Hardware torch, camera-based mirror alignment, AR overlays, or optical detection.
- Microphone recording, voice decoding, siren generation, or background audio modes.
- Live radio tuning, scanning, Bluetooth radio accessories, or SDR integrations.
- Automatic location-based declination using new permissions.
- Persistent history, saved presets, cloud sync, analytics, or export for the tools.
- Assistant or App Intent integration for the new utilities.
- Notification-based countdown alerts, Live Activities, or lock-screen timing behavior.

## Alternative Solutions

1. **Navigation fallback:** If adding a dedicated `Tools` item in `More` creates unexpected tab churn, keep the tools behind a single `Emergency Mode` shortcut plus one existing secondary entry point, but do not scatter the tools across unrelated screens.
2. **Audio fallback:** If generated tone playback proves unreliable, switch to one small bundled local whistle sound and wire it through the manifest and build step explicitly.
3. **Declination fallback:** If manual latitude and longitude interpolation is too error-prone for the intended launch region, replace it with a curated preset-region declination reference card rather than shipping misleading pseudo-calculation.

## Report Format

When the sprint is complete, report back in this structure:

1. Source prompt quoted verbatim.
2. Files changed and any files added.
3. Navigation and Emergency Mode integration changes.
4. Tool behaviors delivered by section: signaling, timing, and reference.
5. Any resource or manifest changes, and whether `xcodegen generate` was required.
6. Verification commands run and their outcomes.
7. Security scan outcome or exact blocker.
8. Assumptions, tool limitations, deferred work, and any explicitly unverified claims.
