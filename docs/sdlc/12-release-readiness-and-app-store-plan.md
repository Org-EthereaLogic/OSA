# Release Readiness And App Store Plan

Status: Release criteria evaluated through Milestone 6. 5 of 6 criteria passed; RC-5 (device performance) requires physical device testing via TestFlight Stage 1.
Related docs: [PRD](./02-prd.md), [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md), [Security And Privacy](./10-security-privacy-and-safety.md), [Risk Register](./risk-register.md)

## Confirmed Facts

- The app is privacy-sensitive and safety-sensitive enough that release quality depends on more than UI completeness.
- The release plan must account for offline behavior, Ask guardrails, and clear user disclosures.
- Milestones 1–6 are complete. The most recent full `xcodebuild test` run on 2026-03-28 passed 373 tests total: 350 unit and 23 UI.
- M5P4 App Store materials (name, descriptions, review notes, privacy disclosures) are authored.
- M5P5 TestFlight feedback loop (3 tester stages, triage rubric) is documented.
- M5P7 release-readiness evidence pack is at `report/2026-03-26-m5-release-readiness.md`.
- Internal alpha validation (RC-6) confirmed zero permission keys, zero background modes, zero ATS exceptions in the shipped binary.

## Assumptions

- The app will first go through internal testing and likely TestFlight before broad distribution.
- The initial release may be a limited-scope launch with a conservative content set.
- Crash and diagnostic collection, if any, should remain minimal and privacy-aware.

## Recommendations

- Use TestFlight to validate offline behavior, model-capability fallback, and content clarity before public launch.
- Treat App Store metadata and disclosures as part of the product, not late-stage paperwork.
- Require a documented review of sensitive content and assistant guardrails before release sign-off.

## Open Questions

- Is the first release private, unlisted, or public App Store?
- Will any opt-in crash reporting tool be allowed?
- Who signs off on sensitive content review before submission?

## Pre-Release Checklist

- complete seed-content review for MVP chapters, quick cards, and checklist templates
- verify offline cold-start behavior on target devices
- verify Ask citations, refusal paths, and unsupported-device behavior
- complete migration tests from at least one prior beta build
- verify trusted-source import and offline reuse flow
- review privacy disclosures and permission strings
- confirm no hidden network calls occur during offline local use

## TestFlight Plan

Recommended stages:

1. Internal technical alpha
   - focus on seed import, local storage, retrieval, and migration
2. Limited trusted beta
   - focus on stress-state UX, content clarity, and stale-content cues
3. Release candidate
   - focus on App Store text, disclosures, and final defect triage

Suggested feedback prompts:

- Was the app understandable when offline?
- Were quick cards easy to access under stress?
- Did Ask feel trustworthy and properly bounded?
- Did any content feel unsafe, vague, or overly confident?

## Release Criteria

| ID | Criterion | Status |
| --- | --- | --- |
| RC-1 | No open high-severity defects affecting offline core flows | **Passed** — 2026-03-28 full `xcodebuild test` run green (373 tests total: 350 unit, 23 UI), plus offline stress and schema migration suites |
| RC-2 | No open high-severity privacy or safety issues | **Passed** — 53 safety regression tests, no permission keys, no ATS exceptions |
| RC-3 | Ask passes citation and refusal regression suite | **Passed** — `SafetyRegressionTests` (53 tests) cover jailbreak, scope override, privacy pressure, stale-source boundaries |
| RC-4 | Imported-source flow works end to end and remains available offline afterward | **Passed** — M4P4 import pipeline + M4P6 Ask online-offer UX + M6P5 discovery all tested |
| RC-5 | App size, cold start, and local performance are acceptable on target devices | **Pending** — 11 MB app size is acceptable; physical device cold-start timing requires TestFlight Stage 1 |
| RC-6 | App Store privacy answers match the shipped behavior | **Passed** — binary Info.plist inspection confirms zero permission keys, zero background modes, zero ATS exceptions |

## Privacy Disclosures Checklist

- Does any user content leave the device in normal use?
- Are online source queries clearly user-initiated?
- Are prompts stored locally, and if so, is that disclosed in-app?
- Are any analytics or crash logs collected, and under what consent model?
- Are permissions justified by an active feature?

## Content Disclaimers

Recommended baseline disclosures:

- informational reference tool, not emergency services
- not a substitute for medical, legal, or professional advice
- Ask answers are limited to approved local sources and may not cover every scenario
- imported source material retains publisher attribution and may age over time

## Crash And Logging Policy

V1 recommendation:

- prefer local logs during development
- if crash reporting is added, make it minimal and clearly disclosed
- never include full notes, inventory data, or Ask conversations in remote crash payloads

## Documentation Handoff Notes

Before coding expands:

- convert architectural recommendations into issue backlog items
- freeze the first seed-content schema
- create a capability matrix for supported devices
- retain this doc suite as the initial implementation baseline

## Post-Launch Maintenance Plan

- regular content review and freshness checks
- periodic risk-register review
- prompt and safety regression updates as content expands
- monitor storage growth and migration complexity
- plan a separate decision cycle for backup or sync if demand appears

## Done Means

- Release gates cover offline reliability, privacy posture, and safety controls.
- TestFlight usage is structured enough to produce actionable findings.
- App Store submission work is anticipated early rather than deferred.

## Next-Step Recommendations

1. ~~Decide the release channel and tester audience before building onboarding copy.~~ **Resolved:** TestFlight 3-stage plan documented in M5P5.
2. ~~Prepare App Store privacy answers only after the implementation footprint is known.~~ **Resolved:** M5P4 App Store materials authored; RC-6 validates binary matches disclosures.
3. ~~Build a release checklist into the repo once milestone tracking starts.~~ **Resolved:** RC-1 through RC-6 criteria evaluated above.
4. Complete TestFlight Stage 1 on physical device for RC-5 cold-start timing validation.
