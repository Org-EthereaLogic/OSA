# 2026-03-28 UI Audit Backlog

Status: Active implementation backlog derived from `UI_Audit_and_Improvement_Opportunities.md` and verified against current repo state.  
Canonicality: Non-canonical working backlog. Use `docs/sdlc/` and `docs/adr/` for product and architecture truth.

## Phase 1

- `UI-001` Validation baseline: capture a dated evidence pack for Home, Ask, Emergency Mode, Quick Cards, Checklists, Inventory, Notes, Settings, Map, and Weather covering VoiceOver order, touch-target measurements, AX1-AX5 screenshots, and contrast results; acceptance is a verified defect list that closes stale audit claims.
- `UI-002` Contrast remediation: replace any failing opacity-based text pairings in hero cards, quick-card rows, and emergency surfaces with passing token values in light and dark mode; depends on `UI-001`.
- `UI-003` Dynamic Type remediation: fix truncation and overflow found at AX1-AX5 in portrait and landscape using layout, line wrapping, and minimum-scale changes only where needed; depends on `UI-001`.
- `UI-101` Home accessibility pass: add header traits, combine readiness content into coherent VoiceOver elements, label spotlight mode changes, add values for readiness percent and badge counts, and make all row cards read as single tappable destinations; depends on `UI-001` and `UI-003`.
- `UI-102` Ask accessibility pass: increase the send button to 44x44, add explicit labels/hints for input and submit, expose confidence state and citation destinations accessibly, and move focus to the answer card on completion; depends on `UI-001`.
- `UI-103` Emergency Mode accessibility pass: label all four action cards and nearby-resource rows, increase emergency hero contrast, and make the dismiss affordance explicit emergency-exit language without changing presentation mode; depends on `UI-001` and `UI-002`.
- `UI-104` Quick Cards and handbook detail accessibility: pad toolbar pin buttons to compliant hit areas, combine related-content rows, ensure large-print layouts remain readable, and prevent decorative chips from being treated as separate controls; depends on `UI-001` and `UI-003`.
- `UI-105` Checklists accessibility pass: add accessibility values for checklist progress, label completion state changes, combine row content, and add focus movement for Emergency Protocol step navigation; depends on `UI-001`.
- `UI-106` Inventory, Notes, and Settings accessibility pass: label archive/filter/add controls, improve menu and form-field accessibility, ensure emergency-contact editing flows are navigable by VoiceOver, and make status/readout rows speak useful values; depends on `UI-001`.
- `UI-107` Map and Weather accessibility pass: keep online annotation titles as the accessible label source, add explicit accessibility treatment for custom/offline annotations, label alert rows and forecast rows, and ensure offline banners and attribution links read correctly; depends on `UI-001`.
- `UI-108` Accessibility regression coverage: extend UI coverage for stable labels and hittable controls on Home, Ask, Emergency Mode, Quick Cards, and Settings, and add a manual QA checklist for VoiceOver, AX sizes, and contrast; depends on `UI-101` through `UI-107`.

## Phase 2

- `UI-201` Shared UI primitives: add internal-only reusable primitives for card variants, padded toolbar icon buttons, skeleton placeholders, and transient banners, only where used in at least two screens.
- `UI-202` Home decomposition: split `HomeScreen` into smaller section views without changing behavior, then migrate duplicated section-card patterns onto the shared primitives; depends on `UI-201`.

## Phase 3

- `UI-301` Home density cleanup: hide empty lower-priority sections, add persisted collapse state only for genuinely noisy sections, and keep emergency access and pinned content above the fold; depends on `UI-202`.
- `UI-302` Ask zero-state and loading improvements: replace the centered spinner with an answer-shaped skeleton, add suggested questions, add recent local queries, and add a clear-text affordance; depends on `UI-201`.
- `UI-303` Emergency Mode refinements: keep full-screen presentation, improve copy hierarchy, and evaluate a persistent `Call 911` affordance after layout cleanup; depends on `UI-103`.
- `UI-304` Onboarding restructure: convert the single-screen form into 2 to 3 focused steps with progress indication, skip handling, and a final personalized payoff screen while preserving existing seeding behavior.

## Phase 4

- `UI-401` Search expansion: add `.searchable` support to Quick Cards, Notes, and Checklists using the existing `SearchService`, not feature-local persistence APIs.
- `UI-402` Actionable empty states: replace generic `ContentUnavailableView` copy with task-oriented empty states for Inventory, Notes, Checklists, and Ask.
- `UI-403` Swipe actions: add archive for Inventory, delete and resume for checklist runs, and pin or unpin for Quick Cards, using existing repository behavior only.
- `UI-404` Context menus: add context menus only for actions already supported by the model, with no editorial-state mutations.

## Phase 5

- `UI-501` Motion pack: add bounded transitions and `withAnimation` blocks for loading-to-loaded changes, Ask results, pin toggles, checklist completion, and protocol step transitions; respect Reduce Motion.
- `UI-502` Haptics and connectivity feedback: add success and error haptics for refresh, import, and checklist completion and add a transient online/offline banner using the shared banner primitive.
- `UI-503` Settings polish: reorganize section order, elevate Emergency Contacts, and improve scanning with clearer grouping after the accessibility work is complete.

## Blocked

- `UI-B01` Voice input: blocked pending product approval, permission and disclosure copy, and a local-only speech-to-text decision.
- `UI-B02` Audible SOS and night-vision mode: blocked pending explicit safety and product review and emergency-flow copy decisions.
- `UI-B03` Keyboard shortcuts and iOS 26 Liquid Glass adaptation: blocked as non-core to the iPhone-first MVP.
