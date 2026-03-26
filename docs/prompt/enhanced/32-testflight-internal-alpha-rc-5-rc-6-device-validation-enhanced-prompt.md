# TestFlight Internal Alpha RC-5 RC-6 Device Validation Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 3 (Task Execution Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Moderate
**Complexity Justification:** This follow-on slice is narrower than Milestone 5 hardening, but it still spans multiple existing artifacts, a real device test matrix, release evidence capture, and release-criteria updates for RC-5 and RC-6. The work should stay inside release validation and documentation, not reopen product implementation.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | The next step after Milestone 5 hardening is TestFlight internal alpha device testing, specifically for RC-5 and RC-6. |
| `AGENTS.md`, `CLAUDE.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`; keep claims evidence-backed; treat blocked validation as `unverified`; preserve offline-first, local-first, and grounded-assistant boundaries. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | Milestone 5 is complete except for the remaining device-testing release gates. RC-5 and RC-6 still require runtime validation on actual builds and devices. |
| `docs/sdlc/12-release-readiness-and-app-store-plan.md` | TestFlight is the intended validation mechanism for offline behavior, model fallback, privacy disclosures, and launch confidence before broader release. |
| `report/2026-03-26-m5-release-readiness.md` | RC-1 through RC-4 are already evidence-backed. RC-5 and RC-6 remain `unverified` pending device testing, performance checks, and privacy-behavior validation against a shipped-style build. |
| `report/2026-03-26-m5-testflight-feedback-loop.md` | Stage 1 internal technical alpha already defines the focus areas, prompts, acceptance criteria, and triage workflow that this task should execute rather than redesign. |
| `report/2026-03-26-m5-app-store-materials.md` | App Store metadata and privacy answers already exist in draft form and now need validation against observed runtime behavior rather than speculative refinement. |
| `docs/prompt/enhanced/31-milestone-5-hardening-and-launch-enhanced-prompt.md` | This task is a bounded follow-on to the broader M5 prompt and should not re-open migration, safety, or launch-artifact creation beyond what the internal alpha proves. |

## Mission Statement

Execute the internal TestFlight alpha for RC-5 and RC-6, capture device-backed evidence for release criteria RC-5 and RC-6, and update the release-readiness artifacts without widening scope beyond launch validation.

## Technical Context

OSA has already completed the engineering-side Milestone 5 hardening work. The remaining gap is no longer missing tests or missing documentation. It is runtime proof that the release candidate behaves acceptably on real devices and that the drafted App Store privacy answers match the observed binary behavior.

The release-readiness report already establishes the split clearly: RC-1 through RC-4 are backed by automated tests and architecture evidence, while RC-5 and RC-6 are blocked on device validation. That means this prompt should treat prior Milestone 5 artifacts as inputs, not rewrite them from scratch. The main job is to execute Stage 1 internal technical alpha in a way that produces durable evidence and only changes release status where measured facts justify it.

Two boundaries matter:

1. RC-5 is about app size, cold start, and local performance on target hardware. Simulator-only evidence is insufficient.
1. RC-6 is about App Store privacy answers matching shipped behavior. Architecture review helps, but final status requires observation of the actual build, permission footprint, and user-visible network behavior during the device test.

Use the existing release artifacts as the backbone: `report/2026-03-26-m5-release-readiness.md` remains the canonical release-gate summary, `report/2026-03-26-m5-testflight-feedback-loop.md` remains the canonical tester workflow and triage rubric, one dated internal-alpha execution report should hold the concrete RC-5 and RC-6 evidence, and screenshots should be kept only when they materially support a performance, privacy, or functional claim.

Do not broaden this slice into new product work, UI redesign, analytics decisions, or Milestone 6 Siri and Apple Intelligence integration.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| RC-5 status | `unverified`; architecture is lean, but no device-backed measurement proves cold start and local responsiveness are acceptable. | RC-5 is either marked `passed` with device evidence or remains `unverified` with exact blockers and observed gaps. |
| RC-6 status | `unverified`; privacy answers are drafted, but there is no shipped-build validation against permission keys, visible networking, and actual local-only behavior. | RC-6 is either marked `passed` with binary and runtime evidence or remains `unverified` with explicit unresolved discrepancies. |
| Internal alpha execution | The repo has a Stage 1 plan and triage rubric, but no dated execution artifact showing which devices, builds, and scenarios were actually exercised. | A dated internal-alpha validation report records the build mapping, device matrix, scenario outcomes, triage decisions, and release-criteria impact. |
| Build identity | RC-5 and RC-6 are referenced conceptually, but the exact build-number mapping may not yet be captured in repo artifacts. | The execution report explicitly maps RC labels to actual app version and build numbers used in testing. |
| Release evidence | Current reports state what still needs device testing, but they do not yet contain device-backed results. | Existing reports are updated narrowly so the release-readiness state reflects measured runtime facts, not assumptions. |

## Pre-Flight Checks

1. Verify the repository root and existing launch artifacts.

```bash
pwd
test -f report/2026-03-26-m5-release-readiness.md \
  && test -f report/2026-03-26-m5-testflight-feedback-loop.md \
  && test -f report/2026-03-26-m5-app-store-materials.md \
  && echo "release artifacts present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: release artifacts present
```

*Success: the task starts from the current M5 evidence set rather than reconstructing release context from memory.*

1. Confirm the current version and build-number sources before referring to RC-5 or RC-6.

```bash
rg -n "MARKETING_VERSION|CURRENT_PROJECT_VERSION|version|build" project.yml OSA.xcodeproj/project.pbxproj
```

*Success: the prompt executor can map RC labels to concrete build identifiers or document the gap explicitly.*

1. Confirm build and test verification is available locally.

```bash
xcode-select -p
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

*Success: the executor either has a working local baseline before device distribution or records the exact blocker that prevents build and test verification.*

1. Confirm whether security scanning is available.

```bash
command -v snyk || echo "snyk unavailable"
```

*Success: the executor knows whether `snyk code test --path="$PWD"` can be included in the final evidence set or must be reported as blocked.*

1. Freeze scope to Stage 1 internal alpha for RC-5 and RC-6 only.

*Success: the work is limited to internal alpha device validation, evidence capture, and release-readiness updates, not new features or broad release-process redesign.*

## Numbered Phased Instructions

### Phase 1: Investigation And Artifact Setup

1. Read the current release artifacts before editing anything. Required inputs are `report/2026-03-26-m5-release-readiness.md`, `report/2026-03-26-m5-testflight-feedback-loop.md`, `report/2026-03-26-m5-app-store-materials.md`, `docs/sdlc/12-release-readiness-and-app-store-plan.md`, and `docs/sdlc/10-security-privacy-and-safety.md`.

*Success: the internal alpha execution stays aligned with the repo’s current release contract and privacy posture.*

1. Create or reserve the output locations for this alpha run. Use `report/2026-03-26-m5-internal-alpha-rc-5-rc-6-device-validation.md` and `screenshot/2026-03-26-m5-internal-alpha/` unless a same-day file already exists and is clearly the correct target. Update `report/2026-03-26-m5-release-readiness.md` and `report/2026-03-26-m5-testflight-feedback-loop.md` only as required by measured results.

*Success: every runtime finding has a defined repository destination before testing begins.*

1. Map RC-5 and RC-6 to concrete builds. Record the marketing version, build number, human label, and install method in the new execution report.

*Success: the report does not use ambiguous release-candidate labels without a concrete build mapping.*

1. Define the Stage 1 device matrix before execution. Minimum coverage is one physical device that supports Foundation Models if available, one physical device that does not support Foundation Models if available, and the exact device model plus iOS version for each row. If only one physical device is available, record the missing coverage explicitly and keep the unsupported path `unverified`.

*Success: runtime claims are tied to named hardware and OS versions rather than a generic “device tested” statement.*

### Phase 2: Execute The Internal Alpha

1. Produce a release-style build for testing.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'generic/platform=iOS' -configuration Release clean archive -archivePath "$PWD/build/OSA-InternalAlpha.xcarchive"
```

If signing or archive generation is blocked, record the exact failure and continue with the narrowest viable physical-device installation path instead of stopping silently.

*Success: there is a concrete build artifact or a precisely reported blocker before runtime claims are made.*

1. Install and test the baseline build associated with RC-5. Execute these Stage 1 scenarios on each available device: cold launch in airplane mode, navigation through all core surfaces, Ask cited answer for an in-scope handbook query, Ask refusal or “not found locally” for an out-of-scope query, trusted-source import while online followed by offline reuse after toggling airplane mode, local data integrity checks for inventory, notes, checklists, and imported knowledge, and a local-only session check for visible unexpected networking during offline use. Record measured observations, not summaries.

*Success: the baseline build has device-backed results for every Stage 1 focus area relevant to RC-5 or RC-6.*

1. Install and test RC-6 as an update over RC-5 on the same device set. Verify that the update preserves local user data, keeps previously imported knowledge available offline, keeps Ask grounded and cited after update, introduces no new permission prompts or privacy-surface changes, and maintains acceptable cold-start time and navigation feel relative to RC-5.

*Success: the report captures whether the release-candidate update path preserves data, trust, and acceptable performance across builds.*

1. Capture evidence that directly supports RC-5 and RC-6. Allowed evidence includes measured cold-start timings, screenshots of key states or warnings, screenshots of TestFlight feedback items tied to specific defects, notes from network-observation tools or device console review, and archived-app inspection results such as permission-key review. Do not collect screenshots that add no release value.

*Success: every claim in the updated release-readiness report points to a concrete observation or artifact.*

### Phase 3: Update Release Evidence

1. Create `report/2026-03-26-m5-internal-alpha-rc-5-rc-6-device-validation.md`. Required sections are build mapping, device matrix, execution date and tester identifiers, scenario checklist with pass or fail or unverified status, performance observations for RC-5, privacy and network-behavior observations for RC-6, defects and triage category, and exact blockers for any incomplete coverage.

*Success: the repo contains a single dated source of truth for the internal alpha execution.*

1. Update `report/2026-03-26-m5-release-readiness.md` narrowly. Change RC-5 from `unverified` only if device-backed performance evidence exists. Change RC-6 from `unverified` only if shipped-build privacy behavior and permission footprint were actually checked. If gaps remain, keep the status `unverified` and replace vague language with the exact missing evidence.

*Success: release-gate status changes only where the new alpha evidence justifies them.*

1. Update `report/2026-03-26-m5-testflight-feedback-loop.md` only if execution reveals the current Stage 1 prompts, acceptance criteria, or triage workflow need concrete correction.

*Success: the feedback-loop document stays canonical and only changes when real alpha execution proves the current workflow is incomplete or inaccurate.*

1. If any new defect is found, classify it using the existing rubric. Each defect entry must include a short title, the device and build where observed, reproduction steps, triage category, and mapped release criterion if any.

*Success: no runtime issue is left as a vague note without release impact classification.*

### Phase 4: Verification And Security

1. Run the repository verification commands again after any report changes and before final reporting.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

*Success: the documentation updates are paired with a fresh local build and test baseline, or the exact blocker is reported.*

1. Run the security scan if available.

```bash
snyk code test --path="$PWD"
```

*Success: the final report states either the scan result or the exact reason it could not run.*

1. Inspect the built app’s permission footprint if an archive exists.

```bash
plutil -p "$PWD/build/OSA-InternalAlpha.xcarchive/Products/Applications/OSA.app/Info.plist" | rg "NS.*UsageDescription"
```

If no archive exists, inspect the actual installed app artifact by the narrowest available means and report the limitation.

*Success: RC-6 is grounded in inspected binary metadata rather than only source-level assumptions.*

## Guardrails

- Forbidden: adding new product features, UI redesign work, analytics, crash reporting, or Milestone 6 integrations.
- Forbidden: marking RC-5 or RC-6 as `passed` from simulator-only evidence.
- Forbidden: changing App Store privacy answers to fit assumptions that were not checked against a runtime build.
- Forbidden: rewriting the whole TestFlight plan when only Stage 1 execution evidence is needed.
- Required: keep measured facts separate from interpretation in every updated report.
- Required: use exact device models, iOS versions, build numbers, and execution dates.
- Required: keep unresolved validation gaps marked `unverified`.
- Required: preserve offline-first, local-first, and grounded-assistant behavior throughout the test flow.
- Budget: prefer report and evidence updates only; code changes are allowed only if a concrete release blocker is discovered and fixed within the same bounded slice.
- Budget: introduce no new dependencies, SDKs, permissions, or background network behaviors.

## Verification Checklist

- [ ] Prompt type is classified as `Feature`
- [ ] Complexity classification is included and justified
- [ ] Mission statement is one sentence and unambiguous
- [ ] Technical context explains why only RC-5 and RC-6 remain in scope
- [ ] All file paths are explicit and repository-relative
- [ ] Pre-flight commands are copy-pasteable
- [ ] Instructions are phased from investigation through verification and security
- [ ] Every action step includes an explicit success signal in italics
- [ ] The execution report path is defined explicitly
- [ ] RC-5 status changes only with device-backed performance evidence
- [ ] RC-6 status changes only with runtime privacy and permission-footprint evidence
- [ ] Guardrails prevent reopening broader Milestone 5 or Milestone 6 scope
- [ ] Error handling covers the likely TestFlight and device-testing blockers
- [ ] Out-of-scope work is explicit
- [ ] Alternative solutions are provided for blocked distribution or missing hardware

## Error Handling

| Error Condition | Resolution |
| --- | --- |
| Apple signing or TestFlight upload is unavailable | Record the exact signing or distribution blocker, continue with the narrowest viable physical-device install path, and keep TestFlight-specific claims `unverified`. |
| Only one physical device is available | Complete the available device run, mark missing hardware coverage explicitly, and do not claim unsupported-device validation. |
| RC-5 or RC-6 labels do not match actual build numbers | Use the real version and build numbers in the report and record the mapping from human label to actual build identity. |
| Cold-start or navigation performance is materially poor | Classify as `Release Risk` or `Release Blocker` depending on severity, capture timings and reproduction conditions, and do not pass RC-5. |
| Unexpected network activity appears during offline local use | Classify as a privacy blocker, capture the exact circumstance, and keep RC-6 `unverified` or mark it failed in the execution report. |
| An unexpected permission prompt appears | Compare it against `report/2026-03-26-m5-app-store-materials.md`, treat any mismatch as an RC-6 blocker, and document the binary evidence. |
| Data is lost or changed between RC-5 and RC-6 | Classify as a release blocker affecting migration and offline trust, document exact reproduction steps, and do not advance release readiness. |
| `snyk` is unavailable | Report `snyk code test --path="$PWD"` as blocked and keep security-scan claims unverified rather than omitting them. |

## Out Of Scope

- New product features or milestone planning beyond Stage 1 internal alpha
- Broad content revisions unrelated to defects uncovered during the alpha
- App Store screenshot production beyond evidence captures needed for RC-5 and RC-6
- Limited trusted beta or public TestFlight planning
- Siri, App Intents, FM-powered inventory completion, or any Milestone 6 work
- Architecture refactors unrelated to a concrete release blocker discovered in this run

## Alternative Solutions

1. Preferred path: distribute RC-5 and RC-6 through TestFlight internal testing on at least two physical devices and update release evidence directly from that run.
1. Fallback path: if TestFlight distribution is blocked, use local release-style physical-device installs from Xcode to gather RC-5 and RC-6 runtime evidence, but keep TestFlight-specific readiness `unverified`.
1. Minimum viable path: if only one device or one build is available, execute the available validation slice, update reports with concrete partial evidence, and leave the remaining release criteria explicitly blocked rather than inflating confidence.

## Report Format

When the task is complete, report the outcome in this order:

1. Build mapping: RC label to actual version and build number.
1. Devices tested: model, iOS version, and Foundation Models capability status.
1. RC-5 result: performance findings, timings if captured, and pass or unverified decision.
1. RC-6 result: privacy and permission-footprint findings, network-behavior findings, and pass or unverified decision.
1. Defects found: triage category and mapped release criterion for each.
1. Files updated: exact report and screenshot paths.
1. Verification: build, test, and `snyk` results or exact blockers.
