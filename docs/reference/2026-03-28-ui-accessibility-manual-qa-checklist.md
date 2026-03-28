# 2026-03-28 UI Accessibility Manual QA Checklist

Use this checklist to verify the Phase 1 accessibility pass after simulator build/test coverage is green.

## VoiceOver

- Home: verify section headers announce as headers, readiness announces a percent and badge counts, and each row reads as one tappable destination.
- Ask: verify the question field, submit button, confidence badge, answer card, citation rows, and trusted-source import affordance all speak meaningful labels and hints.
- Emergency Mode: verify each action card, nearby-resource row, and the `Exit Emergency Mode` button are clear and tappable.
- Quick Cards and handbook detail: verify the toolbar pin buttons announce state correctly and related-content links read as single destinations.
- Checklists: verify progress values, checklist item completion state, and emergency protocol step focus progression.
- Inventory, Notes, and Settings: verify filter/add/archive controls, contact edit rows, and discovery controls all speak useful labels and hints.
- Map and Weather: verify filter chips, map display menu, alert rows, forecast rows, and offline banners read correctly.

## Dynamic Type

- Test AX1 through AX5 on iPhone 16 Simulator in portrait and landscape.
- Verify no clipped emergency headers, no inaccessible toolbar controls, and no unusable list rows.
- Verify large-print reading mode still behaves correctly on Quick Cards, handbook sections, and emergency protocols.

## Contrast

- Verify hero headers and emergency surfaces in light and dark mode.
- Verify quick-card summary text, emergency header copy, metadata captions, and disabled controls remain readable.
- Record any failing token pairs before adjusting visual styles further.

## Touch Targets

- Measure the Ask submit button, toolbar pin buttons, add buttons, filter buttons, and icon-only menus.
- Confirm all interactive controls are at least 44x44 points or have equivalent padded hit areas.

## Deferred Device-Only Checks

- Gloved-hand testing: unverified
- Wet-screen testing: unverified
- Low-light and bright-light readability testing: unverified
