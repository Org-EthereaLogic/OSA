# Milestone 5 Hardening And Launch Enhanced Prompt

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** Milestone 5 spans persistence hardening, offline stress validation, assistant safety coverage, release-readiness artifacts, and a TestFlight feedback loop. It touches tests, persistence bootstrapping, release documentation, and evidence capture across multiple repository areas, but it must stay strictly inside hardening-and-launch scope rather than drifting into new product capability work.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow` | Milestones 1 through 4 plus the branding sprint are complete. The next logical execution target is Milestone 5: Hardening and Launch. |
| User brief | M5 must cover migration tests, offline stress and edge-case tests, safety regression hardening, App Store materials, and a TestFlight feedback loop. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, preserve offline-first and grounded-assistant rules, keep SwiftData details out of feature code, and make every verification claim evidence-backed. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | Milestone 5 is the release gate between completed M1-M4 work and planned M6 Apple Intelligence work. Its exit criterion is the release-readiness doc, not additional features. |
| `docs/sdlc/06-data-model-local-storage.md` | Migration strategy must use explicit versioning, cold-start migration checks, seed updates as migrations, and rollback-safe thinking during beta and launch preparation. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Launch work must preserve local-first privacy, user-visible networking, and bounded safety behavior. App Store privacy answers must match shipped behavior. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Migration, offline, transition, and safety scenarios are mandatory release-quality concerns. Existing tests already cover retrieval, connectivity, import, and safety baselines. |
| `docs/sdlc/12-release-readiness-and-app-store-plan.md` | Release gating requires migration coverage, offline cold-start validation, citation/refusal validation, end-to-end imported-source behavior, and repo-backed App Store/TestFlight readiness work. |
| `docs/sdlc/risk-register.md` | Migration brittleness, stale content, privacy, and safety remain release-blocker risk areas and are explicitly deferred to M5 hardening. |
| `OSA/App/Bootstrap/AppModelContainer.swift` | Cold start currently creates the shared `ModelContainer`, imports bundled seed content, and skips seed import only in unit-test hosts. This is the main bootstrap seam for migration hardening. |
| `OSA/Persistence/SeedImport/SeedContentLoader.swift` | Bundled seed manifests, content hashes, and record counts already exist, which means seed-content migration tests can be rooted in real versioned artifacts rather than synthetic prose-only assumptions. |
| `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift` | Seed-content import already tracks `schemaVersion` and content-pack state, making this repository a primary target for migration verification. |
| `OSA/Persistence/Migrations/README.md` | The migration surface exists structurally, but the repo still needs M5-level implementation and test proof rather than a placeholder directory alone. |
| `OSATests/SafetyRegressionTests.swift` | A safety baseline already exists; M5 should extend it with harder adversarial, privacy, stale-content, and mixed-intent cases instead of creating a second safety suite. |
| `OSATests/ConnectivityServiceTests.swift`, `OSATests/ImportedKnowledgeRefreshCoordinatorTests.swift`, `OSATests/AskTrustedSourceImportFlowTests.swift` | These tests provide the current foundation for offline and transition behavior and should be expanded where possible rather than bypassed. |
| `report/README.md`, `screenshot/README.md` | Release-readiness evidence belongs under dated human-readable reports and screenshot artifacts, not in scratch files or undocumented ad hoc notes. |
| `docs/prompt/README.md`, `docs/prompt/enhanced/README.md` | Enhanced prompt artifacts live under `docs/prompt/enhanced/` and should stay aligned with the current SDLC structure. |

## Classification Summary

- Core intent: complete Milestone 5 by hardening persistence and offline behavior, expanding safety regression coverage, and producing repo-backed launch artifacts that prove the release criteria in `docs/sdlc/12-release-readiness-and-app-store-plan.md` are met or precisely blocked.
- In scope: migration-test implementation, offline stress and transition tests, safety regression expansion, release-readiness and App Store materials, TestFlight feedback-loop artifacts, and evidence-backed build or test verification.
- Out of scope: Milestone 6 Siri or App Intents work, new user-facing features, broad visual redesign, sync or backup architecture, analytics adoption, and broad content expansion unrelated to launch criteria.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- Full Xcode may or may not be available locally; blocked verification must be reported as `unverified` rather than guessed.
- The codebase may not yet contain a complete `VersionedSchema` or `SchemaMigrationPlan`; if so, M5 should introduce the smallest explicit migration scaffolding needed for real tests.
- The repo may not contain a persisted historical store fixture yet; if not, derive one from actual git history or construct a test-only legacy schema fixture that matches a real historical checkpoint rather than inventing arbitrary legacy data.

## Mission Statement

Complete Milestone 5 by implementing evidence-backed migration and offline hardening tests, extending assistant safety regression coverage, and producing concrete App Store and TestFlight launch artifacts that satisfy the existing release-readiness criteria without widening product scope.

## Technical Context

OSA has already completed its major MVP implementation milestones. The remaining release risk is no longer feature breadth. It is proof: can the app survive app updates, offline and degraded conditions, adversarial Ask usage, and launch-review scrutiny without violating the offline-first, grounded, and local-first contract?

The current codebase gives Milestone 5 strong starting points:

1. `OSA/App/Bootstrap/AppModelContainer.swift` is the single cold-start container seam for app storage and bundled seed import.
2. `OSA/Persistence/SeedImport/SeedContentLoader.swift` and `SwiftDataContentRepository` already encode explicit seed manifest versions, content hashes, and import/update rules.
3. Existing tests already cover repositories, retrieval, connectivity, import, refresh, and safety. M5 should extend those proven seams rather than building parallel test frameworks.
4. `report/` and `screenshot/` already exist as evidence sinks, which means launch artifacts can stay inside repository conventions instead of being scattered externally.

This milestone should be executed in the roadmap order already recommended by the user brief:

- M5P1: schema and seed migration tests
- M5P2: offline stress and edge-case tests
- M5P3: safety regression hardening
- M5P4: App Store materials
- M5P5: TestFlight beta and feedback loop

That order matters. Migration and offline behavior are the highest-risk release blockers because they affect the app's core local value and can silently corrupt trust. Safety regression expansion comes next because the assistant's refusal and citation boundaries are a release gate. Only after those engineering risks are covered should launch packaging, screenshots, store copy, and TestFlight templates be finalized.

The prompt must stay disciplined in two ways:

- It must not widen into Milestone 6 work or fresh feature development.
- It must not claim migration coverage, offline resilience, or launch readiness without repository-backed test evidence and dated human-readable artifacts.

Preferred repository-backed outputs for this milestone:

- focused test files under `OSATests/` and `OSAUITests/` only where the existing harness can support them
- migration scaffolding under `OSA/Persistence/Migrations/` only if required for real tests
- dated reports under `report/`
- dated screenshot directories under `screenshot/`

If canonical SDLC docs become inaccurate after the work, update them narrowly. Do not fork the release plan into a second source of truth.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Migration coverage | The repo has versioned seed metadata and a migration directory, but no proven M5 migration test evidence tied to a real historical or legacy state. | Migration behavior is covered by focused tests that prove current bootstrap and seed-update paths behave correctly across at least one earlier-state scenario. |
| Offline hardening | Offline and connectivity behavior are covered in targeted areas, but M5 adversarial and stress-style scenarios are not yet consolidated into release-gating evidence. | Offline cold start, degraded transitions, interrupted import or refresh handling, and local-only core flows are proven by focused tests and evidence-backed notes. |
| Safety regression depth | `SafetyRegressionTests.swift` already covers key prompt injection and blocked-topic cases, but Milestone 5 requires broader release-grade adversarial coverage. | Safety regression coverage includes tougher mixed-intent, privacy-bounded, stale-source, unsupported-topic, and override-pressure cases with deterministic outcomes. |
| Launch artifacts | Release-readiness guidance exists in SDLC docs, but repo-backed App Store copy, screenshot inventory, and TestFlight feedback templates are not yet finalized as dated artifacts. | Repo-backed release materials exist under `report/` and `screenshot/`, aligned with the shipped behavior and privacy boundaries. |
| Exit-criteria traceability | The roadmap says M5 is complete when `docs/sdlc/12-release-readiness-and-app-store-plan.md` criteria are met, but there is no milestone-specific evidence pack tying claims to artifacts yet. | A dated release-readiness report maps each criterion to code, tests, screenshots, or blockers, with `unverified` used wherever tooling or environment prevents proof. |

## Pre-Flight Checks

1. Verify the repository root and artifact folders.

```bash
pwd
test -d report && test -d screenshot && echo "release artifact folders present"
# Expected: /Users/etherealogic-mac-mini/Dev/OSA
# Expected: release artifact folders present
```

*Success signal: the task runs in the repo that contains the existing evidence folders and SDLC docs.*

1. Verify the core M5 source files exist.

```bash
test -f OSA/App/Bootstrap/AppModelContainer.swift \
  && test -f OSA/Persistence/SeedImport/SeedContentLoader.swift \
  && test -f OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift \
  && test -f OSA/Persistence/Migrations/README.md \
  && test -f OSATests/SafetyRegressionTests.swift \
  && test -f OSATests/ConnectivityServiceTests.swift \
  && test -f docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md \
  && test -f docs/sdlc/12-release-readiness-and-app-store-plan.md \
  && echo "m5 surfaces present"
# Expected: m5 surfaces present
```

*Success signal: the migration, hardening, and release-plan seams are present before edits begin.*

1. Determine whether explicit SwiftData migration scaffolding already exists.

```bash
rg -n "VersionedSchema|SchemaMigrationPlan" OSA OSATests
# Expected: either concrete migration files are listed, or no matches are returned and the gap is explicit
```

*Success signal: the implementation knows whether M5 must add minimal migration scaffolding or can wire tests into an existing plan.*

1. Inspect the real historical context before inventing a legacy schema.

```bash
git log --oneline -- OSA/App/Bootstrap/AppModelContainer.swift OSA/Persistence/SwiftData OSA/Persistence/Migrations
```

*Success signal: there is a concrete historical checkpoint to reference, or the absence of one is documented before choosing a fallback test strategy.*

1. Confirm full-Xcode verification availability.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success signal: build and test verification is possible, or the exact blocker is known before implementation starts.*

1. Freeze the milestone scope before editing.

*Success signal: the planned work is limited to M5 hardening, launch materials, and evidence generation. It does not include Milestone 6 features, sync, analytics, or broad UI redesign.*

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the current migration, bootstrap, safety, and release files before editing.

   Required files:

   - `OSA/App/Bootstrap/AppModelContainer.swift`
   - `OSA/Persistence/SeedImport/SeedContentLoader.swift`
   - `OSA/Persistence/SeedImport/SeedContentImporter.swift`
   - `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift`
   - `OSA/Persistence/SwiftData/Models/PersistedSeedContentState.swift`
   - `OSA/Persistence/Migrations/README.md`
   - `OSATests/SafetyRegressionTests.swift`
   - `OSATests/ConnectivityServiceTests.swift`
   - `OSATests/ImportedKnowledgeRefreshCoordinatorTests.swift`
   - `OSATests/AskTrustedSourceImportFlowTests.swift`
   - `docs/sdlc/06-data-model-local-storage.md`
   - `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
   - `docs/sdlc/12-release-readiness-and-app-store-plan.md`

   *Success signal: the plan is grounded in current code and docs rather than inferred from milestone names alone.*

2. Lock the exact output paths before coding.

   Use these repository-backed deliverables unless a narrower existing file is clearly better:

   - `OSATests/SchemaMigrationTests.swift`
   - `OSATests/SeedContentMigrationTests.swift`
   - `OSATests/OfflineStressTests.swift`
   - updates to `OSATests/SafetyRegressionTests.swift`
   - `report/2026-03-26-m5-release-readiness.md`
   - `report/2026-03-26-m5-app-store-materials.md`
   - `report/2026-03-26-m5-testflight-feedback-loop.md`
   - `screenshot/2026-03-26-m5-app-store/`

   *Success signal: every major M5 deliverable has a concrete destination before implementation begins.*

3. Decide the migration-test strategy based on actual repository state.

   Allowed strategies, in order:

   - reuse an existing `SchemaMigrationPlan` if already present
   - add the smallest explicit plan under `OSA/Persistence/Migrations/` and test it
   - if no real historical schema can be reconstructed, use a test-only legacy schema fixture that reflects an actual earlier repository checkpoint, then document that choice in the final report

   *Success signal: migration testing is tied to a real earlier-state model and not a fabricated random schema.*

### Phase 2: M5P1 Migration Tests

1. Add explicit migration scaffolding only if the pre-flight check shows it is missing.

   Preferred file:

   - `OSA/Persistence/Migrations/OSASchemaMigrationPlan.swift`

   If SwiftData requires companion versioned schema files, place them beside that file under `OSA/Persistence/Migrations/`.

   Then update `OSA/App/Bootstrap/AppModelContainer.swift` only as much as needed so the shared container uses the explicit migration path.

   *Success signal: the app bootstrap has a single explicit migration entrypoint and the change remains isolated to `OSA/Persistence/` and the composition root.*

2. Create `OSATests/SchemaMigrationTests.swift` to prove at least one earlier store shape or schema checkpoint can open and reach the current model without data loss in the scenarios M5 cares about.

   Minimum scenarios:

   - opening a legacy or prior-state store into the current container
   - verifying seeded editorial state is still readable after migration
   - verifying user-authored records are not overwritten by seeded updates

   *Success signal: migration claims are backed by tests against a real or repository-derived earlier-state input rather than only current-state in-memory setup.*

3. Create `OSATests/SeedContentMigrationTests.swift` to cover seed-version behavior already encoded in the current content repository and seed loader.

   Minimum scenarios:

   - same manifest version produces a no-op import
   - newer manifest or content-pack state updates the stored seed-content state correctly
   - content-hash and record-count validation failures remain deterministic and safe
   - user-authored data in other repositories remains untouched by seed migration work

   *Success signal: seed updates are proven to behave like migrations, not ad hoc reinserts.*

### Phase 3: M5P2 Offline Stress And Edge-Case Tests

1. Create `OSATests/OfflineStressTests.swift` for release-gating offline scenarios that cut across the existing foundations without depending on live network access.

   Minimum scenarios:

   - fully offline cold start with bundled seed content available
   - repeated offline bootstrap or relaunch does not corrupt local content state
   - local search and Ask extractive fallback remain usable without connectivity
   - pending refresh or import work does not silently corrupt existing local content when offline

   *Success signal: the highest-risk offline flows have a dedicated M5 suite rather than being scattered only across incidental tests.*

2. Extend existing tests where that yields better coverage than starting over.

   Primary extension points:

   - `OSATests/ConnectivityServiceTests.swift`
   - `OSATests/ImportedKnowledgeRefreshCoordinatorTests.swift`
   - `OSATests/AskTrustedSourceImportFlowTests.swift`

   Add edge cases for degraded transitions, interrupted operations, and retry-safe recovery while preserving current offline-first behavior.

   *Success signal: transition and interruption coverage expands using the repo's existing seams instead of duplicating infrastructure.*

3. Add or extend a UI test only if the existing headless harness can support it reliably.

   Preferred path:

   - extend `OSAUITests/OSAAppLaunchUITests.swift` if a stable offline-launch assertion can be added

   If the headless environment cannot reliably validate the intended UI path, do not fabricate UI coverage. Record the limitation in the report and keep the claim `unverified`.

   *Success signal: UI verification remains factual and environment-aware.*

### Phase 4: M5P3 Safety Regression Hardening

1. Expand `OSATests/SafetyRegressionTests.swift` instead of creating a competing safety suite.

   Add adversarial cases for:

   - mixed safe-topic plus blocked-topic phrasing
   - privacy-pressure prompts that try to extract notes, inventory, or raw prompt history
   - stale or uncertain imported-source phrasing that should still refuse unsupported claims
   - repeated override pressure and policy-bypass wording variants not yet covered
   - unsupported professional-advice pressure framed as urgency or emergency authority

   *Success signal: the existing release-critical safety suite becomes deeper and closer to real-world adversarial use.*

2. Extend adjacent policy tests where the new safety cases expose a boundary gap.

   Likely extension points:

   - `OSATests/SensitivityPolicyTests.swift`
   - `OSATests/GroundedPromptBuilderTests.swift`

   Keep the output deterministic, privacy-bounded, and citation-aware.

   *Success signal: new safety coverage is backed by the policy or prompt-shaping layer that actually enforces the behavior.*

3. Preserve the assistant contract while hardening tests.

   Do not widen Ask into general chat, live-web answers, or speculative advice. Test that the current scope limits hold under harder prompts.

   *Success signal: M5 makes the assistant safer, not broader.*

### Phase 5: M5P4 App Store Materials

1. Create `report/2026-03-26-m5-app-store-materials.md` as the repository-backed source for launch copy and disclosure-ready notes.

   Minimum contents:

   - app name and subtitle candidates
   - short description and full description
   - keyword candidates
   - review notes that explain offline-first behavior and bounded Ask behavior
   - privacy and disclosure notes aligned to `docs/sdlc/10-security-privacy-and-safety.md`
   - baseline disclaimer copy aligned to `docs/sdlc/12-release-readiness-and-app-store-plan.md`

   *Success signal: App Store material exists as a dated repo artifact tied to actual shipped behavior, not as a vague TODO.*

2. Capture or inventory screenshot requirements under `screenshot/2026-03-26-m5-app-store/`.

   Required outcome:

   - either the actual screenshots are stored there
   - or a manifest in the report records which screens were captured, which remain blocked, and why

   Prefer screenshots that show Home, Library, Ask with citations or refusal clarity, Quick Cards, Inventory, and trusted-source import evidence where stable.

   *Success signal: screenshot work is dated, attributable, and tied to launch-readiness evidence rather than an external memory of what was captured.*

3. Update `docs/sdlc/12-release-readiness-and-app-store-plan.md` only if the canonical release plan becomes stale because of this work.

   Keep the update narrow and factual.

   *Success signal: canonical docs and the new report agree without creating duplicate competing specs.*

### Phase 6: M5P5 TestFlight Feedback Loop

1. Create `report/2026-03-26-m5-testflight-feedback-loop.md`.

   Minimum contents:

   - release channel decision or explicit blocker if undecided
   - tester stages derived from `docs/sdlc/12-release-readiness-and-app-store-plan.md`
   - concrete feedback prompts for offline usability, Quick Card stress access, Ask trustworthiness, and unsafe or vague content
   - a triage rubric separating release blockers from post-launch backlog items

   *Success signal: the TestFlight plan can be executed by a human without re-deriving what to ask testers or how to classify findings.*

2. Tie the feedback loop to release criteria.

   The template must map feedback back to:

   - offline core flows
   - migration durability
   - safety or privacy issues
   - citation or refusal correctness
   - App Store disclosure mismatches

   *Success signal: incoming beta feedback can directly confirm or block M5 exit criteria.*

### Phase 7: Verification, Security, And Evidence Pack

1. Run the required project build and test verification if full Xcode is available.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: BUILD SUCCEEDED and a passing test run, or a precisely documented blocker
```

   *Success signal: the implementation has current build and test evidence, or the blocker is recorded exactly and affected claims are marked `unverified`.*

1. Run Snyk Code if the CLI is available and the changes include first-party code.

```bash
snyk code test --path="$PWD"
# Expected: no new high-severity issues introduced by the M5 changes, or a precise blocker if Snyk is unavailable
```

   *Success signal: security verification requirements are satisfied for the touched first-party code, or explicitly blocked.*

1. Create `report/2026-03-26-m5-release-readiness.md` that maps each release criterion in `docs/sdlc/12-release-readiness-and-app-store-plan.md` to evidence.

   Required sections:

   - criterion
   - evidence path or command
   - status: `passed`, `failed`, or `unverified`
   - blocker details where not passed

   *Success signal: Milestone 5 completion is traceable to repository artifacts instead of an informal summary.*

## Guardrails

- Do not add Milestone 6 work, Siri or App Intents, sync, backup, analytics, crash-reporting vendors, or new dependencies.
- Do not widen Ask scope or relax grounding, citation, privacy, or safety boundaries while hardening tests.
- Do not fabricate migration history, build results, test outcomes, screenshot capture, or App Store readiness.
- Do not put SwiftData details into `OSA/Domain` or `OSA/Features`; keep migration mechanics under `OSA/Persistence/` and the app composition root.
- Do not create broad architectural abstractions for launch work. Prefer the smallest coherent change set.
- Required: every substantive implementation step must have matching verification evidence or an explicit blocker.
- Required: dated release artifacts belong under `report/` or `screenshot/`, not in scratch docs.
- Required: use `unverified` for environment-blocked claims.

## Verification Checklist

- [ ] A real migration-test strategy was chosen based on repository state rather than guesswork.
- [ ] `OSATests/SchemaMigrationTests.swift` exists or an exact blocker explains why schema migration coverage could not yet be made real.
- [ ] `OSATests/SeedContentMigrationTests.swift` proves seed updates behave like migrations.
- [ ] `OSATests/OfflineStressTests.swift` or equivalent focused coverage proves key offline hardening scenarios.
- [ ] `OSATests/SafetyRegressionTests.swift` was expanded with release-grade adversarial cases.
- [ ] App Store materials exist as a dated report artifact.
- [ ] TestFlight feedback workflow exists as a dated report artifact.
- [ ] Release screenshots or a screenshot inventory are stored under a dated `screenshot/` path.
- [ ] `xcodebuild` build and test were run, or exact blockers were recorded.
- [ ] `snyk code test --path="$PWD"` was run for first-party code changes, or the blocker was recorded.
- [ ] `report/2026-03-26-m5-release-readiness.md` maps the release criteria to evidence paths and statuses.
- [ ] No new product scope beyond Milestone 5 was introduced.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Full Xcode is unavailable or points at Command Line Tools only | Record the exact `xcode-select -p` output, keep build or test claims `unverified`, and continue with code or documentation work that does not require full Xcode. |
| No existing `VersionedSchema` or `SchemaMigrationPlan` is present | Add the smallest explicit migration plan under `OSA/Persistence/Migrations/` and test it rather than leaving migration coverage implicit. |
| No trustworthy historical schema snapshot can be recovered from git history | Use a repository-derived test-only legacy schema fixture, document the derivation in the report, and avoid inventing arbitrary legacy fields or behavior. |
| Headless UI or simulator limitations block screenshot capture or UI validation | Save the exact blocker in the dated report, keep screenshot-dependent claims `unverified`, and do not substitute guessed visual verification. |
| Snyk is unavailable | Report the exact CLI failure or absence and keep the security-verification claim `unverified`. |
| App Store release channel or tester audience is still undecided | Keep the unresolved decision explicit in `report/2026-03-26-m5-testflight-feedback-loop.md` and avoid pretending the launch plan is fully settled. |
| New tests expose real migration, offline, or safety failures | Treat them as Milestone 5 blockers, fix them if they are within this milestone's scope, and only then mark the related criterion as passed. |

## Out Of Scope

- Milestone 6 Apple Intelligence or Siri surfaces.
- New sync, export, backup, or account features.
- Broad UI redesign or branding work beyond release evidence capture.
- New networking capabilities, analytics services, or crash-reporting backends.
- Editorial content expansion except where a small fixture is required for testing or launch screenshots.

## Alternative Solutions

1. Preferred path: execute M5 as one bounded hardening-and-launch slice, with migration and offline proof first, then release artifacts and TestFlight materials.
2. If migration history is not recoverable in time: finish offline hardening, safety expansion, and launch artifacts now, then record schema-migration coverage as the only remaining blocker in the dated release-readiness report rather than faking completeness.
3. If screenshot or UI validation is blocked by the headless environment: complete the engineering hardening and text-based launch materials, store a screenshot inventory with blockers, and defer only the missing visual artifacts while keeping the affected release criterion `unverified`.

## Report Format

When this prompt is executed, report back in this structure:

1. Files changed.
2. Migration-test strategy chosen and why.
3. Offline stress coverage added or extended.
4. Safety regression coverage added or extended.
5. App Store and TestFlight artifacts created.
6. Build, test, and Snyk commands run with factual outcomes.
7. Release-criteria matrix summary from `report/2026-03-26-m5-release-readiness.md`.
8. Exact blockers and every `unverified` claim.
