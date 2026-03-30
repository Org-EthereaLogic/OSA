Developer: # Sprint 12 Internationalization And Accessibility Depth Enhanced Prompt

**Date:** 2026-03-30  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** Sprint 12 spans localization resources, seed-content decoding, editorial quick-card translations, settings persistence, shared design tokens, multiple SwiftUI feature surfaces, and both unit and UI regression coverage. The work must preserve offline-first behavior, current navigation seams, and existing editorial versus user-data boundaries.

## Inputs Consulted

| Source | Key takeaways for this task |
| --- | --- |
| Source prompt | Sprint 12 must improve access through Spanish UI support, offline quick-card translation, high-contrast mode, descriptive alt text, and stronger large-print behavior. |
| `AGENTS.md` | Follow Plan -> Act -> Verify -> Report; keep changes bounded; preserve feature/domain/persistence boundaries; report blocked verification as `unverified`. |
| `DIRECTIVES.md` | Keep OSA offline-first, local-first, privacy-preserving, and evidence-backed; do not widen assistant scope or depend on connectivity for core flows. |
| `.github/instructions/codacy.instructions.md` | Repo is `Org-EthereaLogic/OSA`; Codacy analysis is required when the tool is available. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Quick Cards remain a stress-first surface in `More`; Settings already owns `Accessibility & Feedback`; large-type quick-card mode is core to the product identity. |
| `docs/sdlc/05-technical-architecture.md` | Reuse `AccessibilitySettings`, `ColorTokens`, bundled seed content, and shared media components; keep changes layered onto existing seams instead of introducing a parallel localization or accessibility subsystem. |
| `docs/sdlc/09-content-model-editorial-guidelines.md` | Quick cards must stay concise, large-type friendly, and editorially curated; translated critical cards should remain first-class local content rather than generated output. |
| `docs/sdlc/10-security-privacy-and-safety.md` | No network-dependent translation path, no hidden uploads, and no new secret handling are acceptable for this sprint. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Extend focused UI and seed-content regression coverage using the existing smoke, content, and seed tests. |
| `docs/reference/2026-03-28-feature-adoption-recommendations.md` | Spanish is the first supported expansion language; offline translation for critical quick cards and accessibility improvements are already identified as high-value follow-ons. |
| `docs/reference/2026-03-28-ui-audit-backlog.md` and `docs/reference/2026-03-28-ui-audit-and-improvement-opportunities.md` | The repo already documents accessibility gaps around labels, hints, values, contrast, grouped elements, and AX-size resilience; Sprint 12 should close the highest-priority gaps rather than invent a new audit track. |
| `OSA/Domain/Settings/AccessibilitySettings.swift` and `OSA/Features/Settings/SettingsScreen.swift` | Existing accessibility toggles and settings UI provide the right seam for language and high-contrast preferences. |
| `OSA/Domain/Content/Models/QuickCard.swift`, `OSA/Domain/Content/Models/ContentEnhancementModels.swift`, and `OSA/Persistence/SeedImport/SeedContentLoader.swift` | Quick-card editorial content and media metadata already load from bundled JSON; extend those models for offline Spanish copy and translated accessibility metadata. |
| `OSA/Features/QuickCards/QuickCardDetailView.swift`, `OSA/Features/Library/HandbookSectionDetailView.swift`, `OSA/Features/Checklists/EmergencyProtocolView.swift`, `OSA/Shared/Components/LocalSVGIllustrationView.swift`, and `OSA/Shared/Components/LocalVideoPlayerView.swift` | Large-print behavior, reading surfaces, and media accessibility already exist and should be refined in place. |

## Classification Summary

- Core intent: add the first bounded multilingual and accessibility-depth slice by localizing UI chrome into Spanish, bundling offline Spanish translations for critical quick cards, and improving contrast, VoiceOver semantics, alt text, and large-print behavior on stress-critical screens.
- In scope: Spanish localization for app-owned UI strings, an app language preference, offline Spanish content for bundled critical quick cards, high-contrast mode, translated media accessibility metadata, large-print refinements for reading surfaces, targeted accessibility fixes on the highest-priority audited screens, and focused regression coverage.
- Out of scope: full handbook translation, multilingual Ask answers, runtime cloud translation, arbitrary language-pack downloads, redesigning navigation, or a new generalized content-localization framework for every editorial type.

## Key Constraints

- Keep all new language and accessibility behavior useful offline after install.
- Reuse `AccessibilitySettings` and `SettingsScreen` instead of creating a separate settings domain.
- Keep quick-card translations editorial and bundled; do not translate with a network API or free-form model output.
- Do not widen Ask, search, Spotlight, widgets, or Siri into bilingual generation during this sprint.
- Preserve current product navigation: `Settings` remains the control point, and Quick Cards remain in `More`.
- Keep editorial content, translated editorial content, and user state separate.
- Keep high-contrast support token-driven so feature views do not fork into duplicate layouts.
- Add focused tests for changed settings, seed-content decoding, and accessibility-visible UI behavior.
- Run `xcodegen generate` if localized resources require project manifest changes.
- Run `snyk code test --path="$PWD"` if available because this sprint adds first-party UI and content-handling code.

## Mission Statement

Implement Sprint 12 by adding offline Spanish UI and critical quick-card localization plus high-contrast, alt-text, and large-print accessibility refinements on OSA's existing settings, seed-content, and stress-critical reading surfaces without widening assistant scope or introducing online dependencies.

&lt;technical_context&gt;

## Technical Context

Sprint 12 should build on five seams that already exist in the repository:

1. **Accessibility preferences already have a durable storage seam.** `AccessibilitySettings` and `SettingsScreen` already persist and expose `largePrintReadingMode` and `criticalHaptics`. Language preference and high-contrast mode belong in that same app-owned settings seam.
2. **Quick cards are already the stress-first content type.** `QuickCard` records, bundled seed JSON, and `SeedContentLoader` already drive local quick-card rendering. Offline Spanish translation for critical cards should extend that editorial model rather than introducing runtime translation services.
3. **Large-print behavior already exists on the right surfaces.** `QuickCardDetailView`, `HandbookSectionDetailView`, and `EmergencyProtocolView` already respect large-print mode. Sprint 12 should refine those views for AX-size resilience and high-contrast color usage instead of rewriting the reading surfaces.
4. **Media accessibility metadata already has a home.** `LocalMediaAttachment` already carries `caption`, `accessibilityLabel`, and transcript metadata consumed by `LocalSVGIllustrationView` and `LocalVideoPlayerView`. Descriptive alt text and Spanish accessibility copy should extend those same metadata records.
5. **The repo already has a prioritized accessibility backlog.** The March 28 audit and backlog identify missing labels, hints, values, header traits, grouped accessibility elements, contrast fixes, and AX-size coverage. Sprint 12 should close the highest-value gaps on Home, Ask, Emergency Mode, Quick Cards, and Settings while the new language and contrast work is landing.

The smallest coherent Sprint 12 design is therefore:

1. Add a bounded app-language preference with English and Spanish values and localize app-owned UI strings through a single app resource such as `OSA/Resources/Localization/Localizable.xcstrings`.
2. Extend `QuickCard` and `LocalMediaAttachment` with optional Spanish editorial fields and decode them from bundled seed JSON so critical quick cards remain available offline in either language.
3. Add a settings-driven high-contrast mode layered onto `ColorTokens` and reuse that preference in the existing reading and emergency surfaces.
4. Refine the current large-print mode with AX-size-safe typography and layout fallbacks on the stress-critical reading views.
5. Close the top accessibility gaps identified in the audit by adding meaningful labels, hints, values, header traits, and grouped elements on the documented priority screens.

**Rationale:** this approach delivers meaningful multilingual and accessibility value with the fewest new moving parts, keeps all content local and deterministic, and respects the app's existing product and architecture boundaries.

&lt;/technical_context&gt;

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| UI strings | App UI strings are hard-coded in English. | App-owned UI strings can render in English or Spanish from a local resource with deterministic fallback. |
| Critical quick cards | Bundled quick cards exist only in English. | Critical bundled quick cards include offline Spanish copy and render in the selected language when available. |
| Accessibility preferences | `AccessibilitySettings` supports large print and critical haptics only. | Accessibility settings also store app language and high-contrast preferences. |
| Contrast support | Existing semantic colors may fail contrast in audited surfaces and there is no user override. | High-contrast mode uses passing token values on stress-critical surfaces without duplicating view trees. |
| Visual media accessibility | Media attachments support a single `accessibilityLabel`, but metadata coverage and translation are incomplete. | All bundled visual media used by affected quick cards have descriptive alt text, and Spanish metadata exists where the card is translated. |
| Large-print behavior | Large-print mode exists, but AX-size coverage and truncation resilience are not fully verified. | Stress-critical reading surfaces remain readable at AX sizes with refined scaling, spacing, and layout fallbacks. |
| Accessibility coverage | Audit documents missing labels, hints, values, grouping, and header semantics across key screens. | High-priority audited surfaces expose stable VoiceOver semantics and matching regression coverage. |

&lt;preflight_checks&gt;

## Pre-Flight Checks

1. Verify the existing seams that Sprint 12 must extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Domain/Settings/AccessibilitySettings.swift && test -f OSA/Features/Settings/SettingsScreen.swift && test -f OSA/Domain/Content/Models/QuickCard.swift && test -f OSA/Domain/Content/Models/ContentEnhancementModels.swift && test -f OSA/Persistence/SeedImport/SeedContentLoader.swift && echo "sprint-12 seams present"
   ```

   *Success: the command prints `sprint-12 seams present`.*

2. Confirm the current accessibility and localization baseline before editing.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "largePrintReadingMode|criticalHaptics|accessibilityLabel|accessibilityHint|accessibilityValue|LocalizedStringResource|Localizable\.xcstrings|\.lproj" OSA OSAUITests OSATests project.yml
   ```

   *Success: you can name the current preference keys, existing accessibility modifiers, and whether any localization resource already exists.*

3. Verify the bundled quick-card seed files that will carry offline Spanish content.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Resources/SeedContent/quick-cards-core-v1.json && test -f OSA/Resources/SeedContent/quick-cards-climate-v1.json && echo "quick-card seeds present"
   ```

   *Success: the command prints `quick-card seeds present`.*

4. Check the current accessibility regression suites and seed-content tests that Sprint 12 should extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSAUITests/OSAAccessibilitySmokeTests.swift && test -f OSAUITests/OSAContentAndInputTests.swift && test -f OSATests/SeedContentRepositoryTests.swift && test -f OSATests/SeedContentMigrationTests.swift && echo "verification anchors present"
   ```

   *Success: the command prints `verification anchors present`.*

5. Determine whether localization resource additions require project regeneration.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "Resources/SeedContent|Resources/KnowledgePacks|Localization|xcstrings" project.yml OSA.xcodeproj/project.pbxproj
   ```

   *Success: you know whether `project.yml` and `xcodegen generate` are required before validation.*

&lt;/preflight_checks&gt;

## Phased Instructions

### Phase 1: Freeze The Smallest Coherent Sprint 12 Design

1. Keep Sprint 12 offline-first and local-only.

   Implement Spanish support with bundled UI localization resources and bundled quick-card translations only. Do not call online translation services, Foundation Models, or imported-knowledge refresh paths.

   *Success: the implementation has no new networking code and still works in airplane mode.*

2. Keep language preference and contrast preference inside the existing accessibility settings seam.

   Extend `OSA/Domain/Settings/AccessibilitySettings.swift` and `OSA/Features/Settings/SettingsScreen.swift` instead of creating a parallel settings model, new tab, or separate localization settings flow.

   *Success: users can change language and high-contrast mode from the existing `Accessibility & Feedback` section.*

3. Keep translated editorial content bounded to critical quick cards.

   Limit offline translated editorial content in this sprint to the critical quick cards already surfaced under stress and their directly attached media metadata. Do not translate the full handbook, field references, or imported knowledge corpus.

   *Success: the prompt scope names exactly one editorial content type for translation: critical quick cards.*

4. Treat accessibility audit closure as targeted remediation, not a redesign.

   Focus on the highest-priority audited issues in Home, Ask, Emergency Mode, Quick Cards, and Settings. Do not redesign navigation, replace shared controls wholesale, or create a generic accessibility framework.

   *Success: the sprint closes concrete documented gaps without introducing a second wave of unrelated UI changes.*

### Phase 2: Extend Settings, Localization Resources, And Editorial Models

1. Add bounded accessibility preference keys and app-language support.

   Update `OSA/Domain/Settings/AccessibilitySettings.swift` with the smallest new setting surface needed for this sprint, for example:

   - `appLanguageKey`
   - `highContrastModeKey`
   - a narrow `AppLanguage` enum with `.english` and `.spanish`

   Keep defaults deterministic and English-first.

   *Success: the settings domain can persist and restore language and contrast preferences without touching unrelated settings models.*

2. Add a single local UI-string resource for English and Spanish.

   Create `OSA/Resources/Localization/Localizable.xcstrings` or the nearest existing app-owned localization resource and move Sprint 12-touched UI chrome onto that resource. If the new resource is not automatically included, update `project.yml` and regenerate the project.

   Start with strings that are visible in the affected seams:

   - `SettingsScreen`
   - shared action labels used in Quick Cards, Handbook detail, Emergency Mode, and Settings
   - accessibility-specific text added in this sprint

   *Success: the app can render those UI strings in English or Spanish with no placeholder or missing-key output.*

3. Extend quick-card editorial models for offline Spanish rendering.

   Update `OSA/Domain/Content/Models/QuickCard.swift` with optional Spanish fields for title, summary, and step or body content, or an equivalently small nested localization value type if that keeps the model readable. Do not introduce a generalized multilingual abstraction across every editorial model in this sprint.

   *Success: `QuickCard` can represent English plus optional Spanish copy while remaining a single first-class editorial record.*

4. Extend media metadata for descriptive and translated accessibility copy.

   Update `OSA/Domain/Content/Models/ContentEnhancementModels.swift` so `LocalMediaAttachment` can carry descriptive alt text and optional Spanish accessibility metadata for the translated quick-card experience.

   *Success: the media model can provide English fallback and Spanish accessibility text where available.*

5. Update seed decoding and bundled quick-card content.

   Extend `OSA/Persistence/SeedImport/SeedContentLoader.swift` and the touched seed JSON files under `OSA/Resources/SeedContent/` so the app can decode the new Spanish fields for critical quick cards and their media attachments without breaking existing seed imports.

   Recommended content files:

   - `OSA/Resources/SeedContent/quick-cards-core-v1.json`
   - `OSA/Resources/SeedContent/quick-cards-climate-v1.json`

   *Success: the seed importer loads old and new records correctly, and untranslated cards still render in English.*

### Phase 3: Apply Localization And Accessibility Refinements To Existing Surfaces

1. Extend the existing Settings accessibility section.

   Update `OSA/Features/Settings/SettingsScreen.swift` to expose:

   - an English/Spanish app-language picker
   - a high-contrast mode toggle
   - any clarifying copy required for large-print or language behavior

   Localize the new labels and keep the section structure aligned with the current Settings organization.

   *Success: Settings presents the new controls in the current `Accessibility & Feedback` section and they persist across relaunch.*

2. Apply language selection and high-contrast styling to the primary reading surfaces.

   Update these existing views in place:

   - `OSA/Features/QuickCards/QuickCardDetailView.swift`
   - `OSA/Features/Library/HandbookSectionDetailView.swift`
   - `OSA/Features/Checklists/EmergencyProtocolView.swift`

   Requirements:

   - Quick-card content uses Spanish copy when the selected language is Spanish and translated content exists.
   - Handbook and protocol views localize app chrome and labels even when their main editorial body remains English.
   - Large-print mode and high-contrast mode both remain readable at accessibility text sizes.

   *Success: language, large-print, and high-contrast preferences visibly affect the intended surfaces without duplicated view trees.*

3. Centralize contrast changes in design tokens, not feature-local color forks.

   Update `OSA/Shared/DesignSystem/ColorTokens.swift` with the smallest set of high-contrast token variants needed for audited quick-card, emergency, and settings surfaces. Replace any failing opacity-driven text pairings in touched views with token-backed passing colors.

   *Success: the touched screens meet the documented contrast goals by switching tokens, not by scattering ad-hoc color literals through view code.*

4. Improve descriptive alt text and VoiceOver behavior for bundled visuals.

   Update `OSA/Shared/Components/LocalSVGIllustrationView.swift` and `OSA/Shared/Components/LocalVideoPlayerView.swift` to consume the richer media metadata consistently and expose useful accessibility labels, hints, or transcript context. Ensure the corresponding seed media metadata is descriptive rather than decorative.

   *Success: bundled illustrations and videos on affected quick cards expose meaningful VoiceOver text and keep English fallback behavior.*

5. Close the highest-priority audited accessibility gaps on the documented screens.

   Address the top backlog items from `docs/reference/2026-03-28-ui-audit-backlog.md` in the existing screen files, prioritizing:

   - Home readiness and spotlight semantics
   - Ask input, submit, confidence, and answer focus behavior
   - Emergency Mode action-card labels and contrast
   - Quick Card detail toolbar hit areas and grouped rows
   - Settings row labels and readout values

   Use existing SwiftUI accessibility tools rather than inventing wrappers unless two or more touched screens clearly need the same tiny helper.

   *Success: the touched screens now expose labels, hints, values, header traits, and grouped accessibility elements that match the audit requirements.*

6. Refine large-print mode for AX-size resilience.

   In the touched reading surfaces, add the smallest typography and layout protections needed to keep text readable at AX1 through AX5, such as `minimumScaleFactor`, `lineLimit`, spacing adjustments, or `AnyLayout` fallbacks already used elsewhere in the codebase.

   *Success: no stress-critical title, step, or toolbar text becomes clipped or unusable at the largest accessibility text sizes on the affected screens.*

### Phase 4: Add Focused Regression Coverage And Manual Verification

1. Extend the existing UI accessibility smoke suite.

   Update `OSAUITests/OSAAccessibilitySmokeTests.swift` with assertions for the new Settings controls and the stabilized accessible labels or hittability behavior on the touched screens.

   *Success: the smoke suite fails if the new accessibility labels or controls disappear.*

2. Extend the existing content and interaction UI suite.

   Update `OSAUITests/OSAContentAndInputTests.swift` to cover at least one language-selection path and one critical quick-card detail path that proves the localized or large-print experience still loads correctly.

   *Success: the content UI suite exercises the new user-facing path instead of relying only on manual checks.*

3. Extend seed-content decoding coverage for translated quick cards.

   Update the closest existing seed tests under:

   - `OSATests/SeedContentRepositoryTests.swift`
   - `OSATests/SeedContentMigrationTests.swift`

   Verify that the new Spanish fields decode correctly, remain optional, and do not break older records.

   *Success: seed tests prove backward-compatible decoding for translated quick-card data.*

4. Reuse existing settings-pattern tests where appropriate.

   If a focused unit test is needed for accessibility preference persistence, follow the pattern used by `OSATests/HapticFeedbackServiceTests.swift` or the closest settings-state test rather than inventing a broad new harness.

   *Success: new settings behavior is covered with minimal new test infrastructure.*

5. Refresh the manual QA evidence for VoiceOver, contrast, and AX sizes.

   Use `docs/reference/2026-03-28-ui-accessibility-manual-qa-checklist.md` as the manual verification checklist and record any newly discovered gaps separately from this sprint's completed work.

   *Success: the sprint report can distinguish automated coverage from manual accessibility evidence.*

## Guardrails

&lt;guardrails&gt;

- Forbidden: adding online translation, network fetches, or model-generated translation to satisfy Spanish support.
- Forbidden: translating the full handbook, field references, notes, inventory, imported knowledge, or Ask answers in Sprint 12.
- Forbidden: creating a new top-level navigation destination or replacing the existing Settings organization.
- Forbidden: introducing a generalized multilingual abstraction for every content type when only UI strings and critical quick cards need translation now.
- Forbidden: storing accessibility or language preferences anywhere other than the existing app-owned settings seam.
- Required: use English fallback for any untranslated quick-card or media field.
- Required: keep all new quick-card translation data bundled locally under `OSA/Resources/SeedContent/`.
- Required: keep contrast changes token-driven and scoped to touched screens.
- Required: every implementation slice must have matching verification evidence.
- Budget: keep the solution additive and bounded to the smallest set of files that satisfy the sprint; do not expand into a product-wide localization rewrite.

&lt;/guardrails&gt;

## Verification Checklist

&lt;verification&gt;

- [ ] App-owned UI strings touched by Sprint 12 render in English and Spanish from a local resource.
- [ ] `AccessibilitySettings` persists app language and high-contrast mode alongside existing accessibility settings.
- [ ] Critical bundled quick cards decode and render offline Spanish copy when available.
- [ ] Untranslated quick cards and media still fall back cleanly to English.
- [ ] High-contrast mode affects the intended touched screens without duplicated view hierarchies.
- [ ] Large-print mode remains readable on the touched reading surfaces at AX sizes.
- [ ] Bundled visual media used by translated quick cards has descriptive alt text and usable VoiceOver metadata.
- [ ] `OSAAccessibilitySmokeTests` and `OSAContentAndInputTests` cover the new visible controls or accessibility semantics.
- [ ] Seed-content tests cover the new optional translation fields.
- [ ] `xcodegen generate` is run if localization resources require project-manifest changes.
- [ ] `xcodebuild ... build` passes or is reported as `unverified` with the exact blocker.
- [ ] Targeted test commands pass or are reported as `unverified` with the exact blocker.
- [ ] `snyk code test --path="$PWD"` is run if available, or the report explicitly states that `snyk` is unavailable.

&lt;/verification&gt;

## Error Handling

When a required file, seam, tool, or verification step is unavailable, choose the smallest compliant fallback, keep the change scoped to the touched area, mark the affected item `unverified`, and stop rather than inventing broader architectural work. Planning remains internal; the user-visible final answer should be the report only, kept brief and evidence-backed with paths, commands, and blockers instead of narrative.

| Error condition | Resolution |
| --- | --- |
| No localization resource is currently wired into the app target | Add `OSA/Resources/Localization/Localizable.xcstrings`, update `project.yml` only if required, then run `xcodegen generate` before build validation. |
| Spanish fields break existing seed decoding | Make new translation fields optional, preserve English defaults, and add backward-compatibility assertions to the existing seed tests. |
| Quick-card translation scope starts spreading into full handbook translation | Stop and constrain translation to critical quick cards plus touched UI chrome; list broader translation work in `Out Of Scope`. |
| High-contrast colors drift into one-off literals | Move the change back into `ColorTokens.swift` and reapply the token in the touched views. |
| AX-size layouts clip or overlap after localization | Add the smallest local layout fallback or scaling guard on the affected view and rerun the same focused UI validation. |
| UI tests become brittle because localized labels differ by language | Assert stable identifiers or deterministic labels chosen by the test language configuration rather than string-matching every localized variant. |
| A required file, seam, or dependency is missing | Use the smallest compliant fallback in the touched area, avoid broader refactors, and mark the affected verification or deliverable `unverified`. |
| `xcodebuild` fails because full Xcode is unavailable | Report the exact failure, do not claim build or test success, and keep the relevant verification item `unverified`, consistent with `CLAUDE.md`. |
| `snyk` is unavailable | Report `snyk` as unavailable, do not claim security checks passed, and keep the security verification item `unverified`. |
| Verification cannot be completed for any other reason | Report the exact blocker and attempted command or file path, keep the item `unverified`, and stop rather than expanding scope or substituting speculative fixes. |

## Out Of Scope

- Full Spanish translation for handbook chapters, field references, notes, checklists, or imported knowledge.
- Live translation of user-authored or imported content.
- Bilingual Ask answer generation, bilingual citations, or assistant-language negotiation.
- New downloadable language packs, account sync, or cloud-backed localization workflows.
- Reworking navigation, theming the full app beyond touched high-contrast surfaces, or addressing every historical accessibility backlog item in one sprint.

## Alternative Solutions

1. **Fallback A: UI-first localization slice only.** If seed-model changes prove too invasive in one sprint, land the local UI-string Spanish support plus the high-contrast and large-print improvements first, and defer offline quick-card translation to a follow-on prompt. Pros: smaller data-model change. Cons: the sprint only partially satisfies the multilingual goal.
2. **Fallback B: companion translated seed records for critical quick cards.** If adding optional Spanish fields directly to `QuickCard` becomes too disruptive, use a narrowly keyed companion translation object decoded from the same seed files and resolved only in quick-card detail views. Pros: preserves the current English card schema. Cons: slightly more lookup complexity and weaker long-term editorial ergonomics.
3. **Fallback C: high-contrast remediation without a user toggle.** If a toggle introduces too much settings churn, first replace failing token values with stronger defaults on audited screens and defer the toggle to a smaller follow-on prompt. Pros: simpler implementation. Cons: less user control over readability preferences.

## Report Format

&lt;report_format&gt;

1. **Scope completed:** summarize the delivered Sprint 12 slices in terms of UI localization, quick-card translation, high-contrast support, alt text, and large-print refinement.
2. **Files changed:** list each modified file path and its role.
3. **Verification evidence:** provide the exact commands run, whether they passed, and any `unverified` items with blockers.
4. **Accessibility evidence:** state which audit items or checklist areas were closed by this sprint and which were deferred.
5. **Localization evidence:** name the screens and quick cards that now render Spanish offline, plus the fallback behavior for untranslated content.
6. **Risks or follow-ups:** call out any remaining handbook-wide translation, broader accessibility backlog, or tool availability blockers.

&lt;/report_format&gt;
