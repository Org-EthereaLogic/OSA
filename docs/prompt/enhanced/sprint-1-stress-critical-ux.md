# Implement Sprint 1: Stress-Critical UX Flows

**Date:** 2026-03-28  
**Prompt Level:** Level 3 (Task Execution/Feature Prompt)  
**Complexity:** Complex (5+ files, 13 specific UX enhancements, cross-cutting structural changes)

---

## Inputs Consulted

| Source | Key Takeaways |
|--------|---------------|
| Original Prompt | Build out "Sprint 1: Stress-Critical UX Flows" (13 items, Moderate Effort, High Impact) |
| Notion Backlog | *(Note: Link was inaccessible, but inferred from UI Audit)* The 13 items correspond directly to stress and emergency accessibility recommendations. |
| `UI_Audit_and_Improvement_Opportunities.md` | Provides explicit benchmarks & gaps for Emergency Mode, Touch Targets, Accessibility, and Contrast. |
| `AGENTS.md` / `DIRECTIVES.md` | Offline-first, stress-state usability is a non-negotiable priority. |
| `CLAUDE.md` | Validates file paths (`OSA/Features/Home/EmergencyModeView.swift`, etc.). |

---

## Mission Statement

Implement 13 stress-critical UX and accessibility enhancements across the iOS application to ensure robust, panic-proof usability during emergencies, upgrading views mapping to accessibility and navigation.

---

## Technical Context

During high-stress scenarios (emergencies, natural disasters), complex gestures are harder to perform, small touch targets lead to critical miss rates, and cognitive capacity drops. The app’s primary stress surface, `EmergencyModeView.swift`, currently relies on a `.sheet` presentation, which carries an inherent risk of accidental dismissal.

By elevating touch targets to HIG minimums (44x44), enriching VoiceOver with semantic focus management, implementing red-tinted night-vision/high-contrast, and redesigning structural routing to favor `.fullScreenCover`, we minimize the cognitive and physical burden on users during panic states.

---

## Problem-State Table

| Component | Current State | Target State |
|-----------|---------------|--------------|
| **1. Emergency Mode Routing** | Presented as swipeable `.sheet` | Presented as strict `.fullScreenCover` with explicit "Exit" button |
| **2. Night Vision Mode** | Not available | Red-tinted overlay toggle in `EmergencyModeView` |
| **3. Persistent "Call 911"** | Might scroll off-screen | Fixed bottom-bar CTA button (`EmergencyModeView`) |
| **4. SOS Audible Alarm** | Not available | Dedicated play/pause SOS alarm button |
| **5. Header Text Contrast** | `opacity(0.72)` failing contrast checks | `opacity(0.95)` / solid colors for readability |
| **6. Emergency Card `accessibilityLabel`** | 4 action cards lack labels | Each card has a descriptive `.accessibilityLabel` |
| **7. Map Route `accessibilityHint`** | Shelter/Hospital links lack hints | `.accessibilityHint("Opens in Apple Maps")` added |
| **8. Ask Submit Button Size** | 42x42 points | 44x44 points (`AskScreen.swift`) |
| **9. Pin Button Touch Target**| System default (~30pt) | Minimum 44x44 padded area (`QuickCardDetailView.swift`) |
| **10. Accessibility Headers** | Missing VoiceOver headers | `.accessibilityAddTraits(.isHeader)` on section titles |
| **11. Protocol Focus State** | VoiceOver loses context on next step | `@AccessibilityFocusState` follows active step |
| **12. Critical Text Scaling** | Truncates on AX5 | Added `.minimumScaleFactor(0.7)` |
| **13. Step Transitions** | Instant/abrupt layout flips | Smooth asymmetric structural transitions |

---

## Pre-Flight Checks

1. Verify target compilation baseline:

   ```bash
   xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

2. Verify all primary files exist:

   ```bash
   test -f OSA/Features/Home/EmergencyModeView.swift && \
   test -f OSA/Features/Ask/AskScreen.swift && \
   test -f OSA/Features/Checklists/EmergencyProtocolView.swift && \
   test -f OSA/Features/Home/HomeScreen.swift && \
   echo "✓ Files exist"
   ```

---

## Instructions

### Phase 1: Investigation & Setup

1. **Audit `EmergencyModeView` usage:**
   Search the codebase to locate where the `.sheet(isPresented:)` presenting `EmergencyModeView` is invoked.

   ```bash
   grep -rn "EmergencyModeView" OSA/Features/
   ```

   *Success: The presenting view (likely `HomeScreen`) is identified.*

### Phase 2: Core Structural & UX Implementations

1. **Transition from Sheet to Full Screen Cover:**
   In the parent view (e.g., `HomeScreen.swift`), replace `.sheet(isPresented: $isEmergencyMode)` with `.fullScreenCover(isPresented: $isEmergencyMode)`.
   *Success: Compiles with updated modifier.*

2. **Add Explicit Exit Button to Emergency Mode:**
   Inside `EmergencyModeView.swift`, add an "Exit Emergency Mode" `Button` linked to `dismiss()`, anchoring it at the top leading corner.
   *Success: View contains a safe dismissal mechanism.*

3. **Implement Persistent "Call 911" Bottom Bar:**
   In `EmergencyModeView.swift`, wrap the main scroll view in a `VStack` or `ZStack` and pin a "Call 911" button to the bottom using `safeAreaInset(edge: .bottom)`.
   *Success: CTA is visually fixed at the bottom.*

4. **Build the Night-Vision Red Tint Overlay:**
   In `EmergencyModeView.swift`, add a `@State private var isNightVisionEnabled = false`. Apply `.overlay(Color.red.opacity(isNightVisionEnabled ? 0.2 : 0).allowsHitTesting(false))` to the outermost container, and a toggle for users to active it.
   *Success: A visual red filter is conditionally renderable without blocking touches.*

5. **Add SOS Alarm Button Mechanism (Stub + UI):**
   In `EmergencyModeView.swift`, add an actionable button for "Audible SOS". For now, attach a strong haptic loop or print statement, pending a full `AVAudioPlayer` implementation.
   *Success: UI for the alarm is present alongside the 911 button.*

6. **Fix Header & Description Contrast:**
   Find `opacity(0.72)` or `opacity(0.84)` text modifiers in `EmergencyModeView` and change them to `opacity(0.95)` or remove the opacity reduction altogether.
   *Success: Contrast is strictly maintained over canopy/ember gradients.*

7. **Fix Small Touch Targets:**
   - In `AskScreen.swift`, update the submit button to `frame(width: 44, height: 44)`.
   - In `QuickCardDetailView.swift`, verify the pin button uses `.contentShape(Rectangle())` and `.frame(minWidth: 44, minHeight: 44)`.
   *Success: All critical icons meet minimum HIT sizes.*

8. **Add Asymmetric Step Transitions:**
   In `EmergencyProtocolView.swift`, apply `.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))` to the active step child views, wrapped in a `withAnimation` block for state changes.
   *Success: Steps slide naturally.*

### Phase 3: Accessibility Enhancements

1. **Add Semantic Headers:**
    Find textual section titles across `HomeScreen.swift` and `EmergencyModeView.swift` and apply `.accessibilityAddTraits(.isHeader)`.
    *Success: VoiceOver rotor can jump between sections.*

2. **Inject Accessibility Labels and Hints:**
    - Attach `.accessibilityLabel("Read Protocols")`, `"View Quick Cards"`, etc. to grid cards in `EmergencyModeView`.
    - Apply `.accessibilityHint("Opens in Apple Maps")` to Shelter/Hospital buttons.
    *Success: Context provided for blind UI navigation.*

3. **Define Focus Management:**
    In `EmergencyProtocolView.swift`, create an `@AccessibilityFocusState private var focusedStep: UUID?`. Focus it automatically inside `{ onChange(of: activeStep) }`.
    *Success: VoiceOver reads newly revealed steps linearly.*

### Phase 4: Verification & Security

1. **Dynamic Type Resilience Check:**
    Apply `.minimumScaleFactor(0.7)` on all multi-line instructions inside `EmergencyProtocolView.swift`.
    *Success: Prevents overflow truncation at AX5 scales.*

2. **Build & Unit Test Verification:**
    Review the modifications compile, then run the app scope builder.

    ```bash
    xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
    ```

    *Success: Build exits with code 0.*

3. **Snyk Vulnerability Scan:**
    Run Snyk to ensure UI updates didn't introduce unexpected regressions.

    ```bash
    snyk code test --path="$PWD"
    ```

    *Success: No new vulnerabilities reported.*

---

## Guardrails

<guardrails>
- **Forbidden:** Moving away from SwiftData constraints during these UI updates.
- **Forbidden:** Modifying color token underlying HEX values directly—only adjust alpha/opacity values in the View layer.
- **Forbidden:** Changing `OSA/App/` routing structures outside of `EmergencyModeView` presentation logic.
- **Required:** Make sure the SOS Alarm button uses appropriate semantic red/warning colors.
- **Budget:** Changes should be strictly confined to Apple's HIG specifications. Do not over-engineer dynamic routing; limit the refactoring cleanly.
</guardrails>

---

## Verification Checklist

- [ ] Presentation switched to `.fullScreenCover`
- [ ] Explicit "Exit" mechanism added
- [ ] Persistent "Call 911" bottom bar renders properly
- [ ] Red-tinted night-vision feature added
- [ ] SOS toggle/button established
- [ ] AskScreen send button is `44x44`
- [ ] QuickCard pin button is effectively padded to `44x44`
- [ ] Contrast constraints fixed
- [ ] VoiceOver `.isHeader` populated on Home
- [ ] `accessibilityLabel` applied to Emergency action buttons
- [ ] `accessibilityHint` added to Maps links
- [ ] `AccessibilityFocusState` handles protocol step transitions
- [ ] `.minimumScaleFactor(0.7)` protects text at Max AX
- [ ] Snyk tests and local xcodebuild clean

---

## Error Handling Table

| Error Condition | Resolution |
|-----------------|------------|
| `fullScreenCover` causes environment environment object loss | Re-inject `.environment(\.dismiss, ...)` or standard context into the presented view body. |
| Contrast fixes make text invisible on light mode | Utilize `lanternDynamic(...)` tokens, preferring generic solid colors like `osaForeground`. |
| VoiceOver focus fails to jump on step change | Ensure `DispatchQueue.main.asyncAfter` gives SwiftUI a ~100ms render tick before applying focus state. |
| Build fails on older dependencies | Regenerate using `xcodegen generate` and rebuild. |

---

## Out of Scope

- Implementing the final CoreAudio `AVAudioPlayer` loop for the SOS alarm (beyond stub UI and standard haptics).
- Changing widget parameters or Core Spotlight integrations.
- Remactoring deep SwiftUI architectural patterns beyond surface-level accessibility modifiers.

---

## Report Format

1. **Summary of Items Completed:** Confirm all 13 checklist points.
2. **Files modified:** Output exact paths of modified swift files.
3. **Challenges Encountered:** Note any contrast tradeoffs or navigation routing bumps resolved.
4. **Verification:** Outcome of the UI inspection and Xcodebuild passes.
5. **Security Status:** Snyk outcome.
