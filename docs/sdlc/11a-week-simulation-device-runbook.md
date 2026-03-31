# Week Simulation Device Runbook

Status: Initial draft complete.  
Related docs: [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md), [Security, Privacy, And Safety](./10-security-privacy-and-safety.md), [Release Readiness](./12-release-readiness-and-app-store-plan.md)

## Purpose

This runbook mirrors the automated seven-day simulator persona simulation on a physical iPhone. Use it to validate the flows that the simulator cannot prove reliably: biometric unlock, camera and photo-library import, live network behavior, location permission, and true offline recovery.

## Preconditions

- Install a fresh build on a physical iPhone.
- Use synthetic household data only.
- Start with network available on Day 1 long enough to install the app, then follow the day-by-day connectivity state below.
- Keep the device date and time unchanged. The automated simulation uses the launch-argument clock override; device validation uses real time and a reviewer log.
- Save artifacts under `build/week-sim/<run-id>/device/` when possible: screenshots, screen recordings, and reviewer notes.

## Severity Rules

- `Release Blocker`: crash, uncited Ask answer, persistence loss across relaunch, corrupted import state, privacy-boundary violation, or device-only feature failure in a primary flow.
- `Release Risk`: intermittent permission issue, live-service discrepancy, degraded UX, or a simulator/device mismatch that still needs reproduction and classification.
- `Unverified`: a check was not executed or the evidence is incomplete.

## Day Matrix

| Day | Connectivity | Required Actions | Evidence |
| --- | --- | --- | --- |
| 1 | Offline after install | Create an emergency contact, create a family-plan note, add 4 to 6 inventory items, pin a quick card, relaunch, verify Home state. | Screenshots of Settings, Notes, Inventory, and Home after relaunch. |
| 2 | Offline | Search `water` in Library, open a handbook section and a field reference, ask one supported question, one not-found question, and one bounded out-of-scope question, save a study guide. | Ask screenshots showing citations, not-found, and bounded refusal states. |
| 3 | Offline | Edit inventory, archive one item, start the 72-hour checklist, complete part of it, finish the weekly drill quiz, verify Ask note-scope behavior. | Screenshots of edited inventory, active checklist, weekly drill completion, and Ask note-scope toggle behavior. |
| 4 | Online usable | Use Morse, timer, converter, declination, save a waypoint, accept location permission, load Weather, rotate once, toggle high-contrast and large-print. | Screenshots of the saved waypoint, weather alert/forecast, and rotated accessible UI. |
| 5 | Online usable, then offline | Run manual discovery against the approved fixture/live allowlist source, verify imported knowledge becomes searchable and citeable only after local import, relaunch offline, verify it still works, verify bundled knowledge packs remain installed. | Before/after screenshots for search/import, plus offline Ask citation evidence. |
| 6 | Offline unless capture/import requires temporary access | Unlock Document Vault with biometrics, import a real document, exercise inventory camera and photo-library import, open share/export flows for note, inventory, checklist, quick card, and handbook content, confirm vault content does not leak into Ask or system surfaces. | Biometric prompt evidence, imported document evidence, and screenshots or reviewer notes confirming privacy boundaries. |
| 7 | Offline cold start | Open Emergency Mode, jump to Quick Cards and Survival Tools, resume the active checklist, relaunch again, verify no state loss, summarize all findings. | Final home-state screenshot, active-checklist screenshot, and reviewer summary. |

## Required Device-Only Checks

- Document Vault unlock succeeds with the real biometric prompt.
- Document capture/import creates a vault entry that remains excluded from Ask, widgets, Spotlight, and export actions.
- Inventory camera capture and photo-library import both work with real permissions.
- Map location permission grants correctly and the live position updates when available.
- Live weather behavior, trusted-source import, and reconnect/offline transitions behave acceptably on a real network.

## Reporting Template

- Run ID:
- Device:
- iOS version:
- Build identifier:
- Reviewer:
- Day:
- Action:
- Expected result:
- Actual result:
- Severity:
- Release criterion:
- Attachment paths:

## Exit Criteria

- No `Release Blocker` remains open.
- `Release Risk` items are either fixed or explicitly accepted with documented follow-up.
- Device-only checks are either verified with evidence or marked `Unverified` with a named blocker.
