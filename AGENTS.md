# OSA Repository Guidelines

Operational guardrails for AI coding agents working in OSA.

OSA is an offline-first iPhone preparedness app with a grounded local assistant, local-first privacy, and optional online knowledge enrichment that only becomes usable after local persistence and attribution.

## Mission

Deliver a reliable iPhone app that stays useful under stress, keeps sensitive data on device by default, and never presents assistant output as truth unless it is grounded in approved local evidence.

## Decision Order

When tradeoffs appear, resolve them in this order:

1. User safety and correctness.
2. Grounding, provenance, and citation integrity.
3. Privacy, security, and secret hygiene.
4. Simplicity and proportionality.
5. Reproducibility and operational reliability.
6. Performance and stress-state usability.

## Standard Workflow

Use `Plan -> Act -> Verify -> Report` for every substantive task.

### Plan

- Identify the task contract, scope boundaries, user flows affected, and acceptance criteria.
- Read the governing docs plus the relevant `docs/sdlc/*.md` files and ADRs before editing.
- Confirm whether the change touches offline behavior, assistant scope, privacy, persistence, import, or seed content.

### Act

- Implement the smallest coherent change that satisfies the task.
- Preserve folder boundaries: `App`, `Features`, `Domain`, `Persistence`, `Retrieval`, `Assistant`, `Networking`, and `Shared`.
- Keep SwiftData, networking, and model-adapter details out of feature views.
- Update canonical docs when code changes invalidate them.

### Verify

- Run the appropriate local checks for the files and surfaces touched.
- Confirm code, docs, and reported behavior agree.
- Map each claimed acceptance criterion to evidence.
- Mark blocked verification as `unverified`, not `passed`.

### Report

- State changed files, outcome, and verification evidence.
- Separate measured facts from interpretation or follow-up recommendations.
- Call out blockers, deferred work, or environment limits explicitly.

## Required Pre-Read

Read these before making architecture, persistence, retrieval, assistant-policy, safety, or reporting claims:

- `CLAUDE.md`
- `CONSTITUTION.md`
- `DIRECTIVES.md`
- `AGENTS.md`
- `docs/sdlc/00-doc-suite-index.md`
- `docs/sdlc/02-prd.md`
- `docs/sdlc/03-mvp-scope-roadmap.md`
- `docs/sdlc/05-technical-architecture.md`
- `docs/sdlc/06-data-model-local-storage.md`
- `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`
- `docs/sdlc/10-security-privacy-and-safety.md`
- `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- the relevant ADRs in `docs/adr/`
- the task prompt, issue, or user brief being executed

Also read these when the task depends on them:

- `docs/sdlc/04-information-architecture-and-ux-flows.md` for navigation or UX changes
- `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` for import or online behavior
- `docs/sdlc/09-content-model-editorial-guidelines.md` for seed-content or editorial changes
- `docs/sdlc/12-release-readiness-and-app-store-plan.md` for distribution, privacy disclosure, or launch readiness changes

## Source Precedence

Use sources in this order:

1. Relevant `docs/sdlc/*.md` files and accepted ADRs in this repository
2. Root governance docs
3. Current code reality in this repository
4. The active task prompt or issue
5. Reference repositories supplied for style or precedent only

## Non-Negotiable Constraints

- No fabricated build, test, performance, or security claims.
- No secrets, tokens, or inline credentials in repository content.
- No direct web-answer behavior or general-chat drift in the assistant.
- No SwiftData imports in feature-layer code.
- No core-flow dependency on connectivity for MVP local features.
- No speculative abstractions without immediate need.
- No unsafe widening of medical, tactical, foraging, or hazardous-improvisation scope.

## OSA-Specific Expectations

- The app remains iPhone-first, offline-first, and local-first.
- The primary first-class surfaces remain `Home`, `Library`, `Ask`, `Inventory`, `Checklists`, `Quick Cards`, `Notes`, and `Settings`.
- Quick cards and handbook content are foundational; do not prioritize online enrichment ahead of local browseability and citations.
- Repository protocols belong in `OSA/Domain`; persistence implementations belong in `OSA/Persistence`.
- A single app target is acceptable for now; boundary discipline matters more than package count.
- Trust current code over stale prose, but update stale prose promptly when code becomes the new truth.

## Required Checks

Run the checks that match the task:

- `xcodegen generate` when `project.yml` changes or when target/project structure changes require regeneration
- `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build` when full Xcode is available
- `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test` when a test target exists and full Xcode is available
- `snyk code test --path="$PWD"` when first-party code or security-sensitive configuration changes and `snyk` is available

If a required tool is unavailable, report the exact blocker and keep affected claims unverified.

## Source Provenance

These references informed the governance structure and are preserved as style and process inputs, not as OSA source of truth:

- `/Volumes/etherealogic-2/Dev/FailLens_Core/`
- `/Volumes/etherealogic-2/Dev/ADWS_PRO/`
