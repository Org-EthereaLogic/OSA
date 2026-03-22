# OSA Directives

Enforceable repository directives derived from `CONSTITUTION.md`.

## Enforcement Levels

- Critical: blocking requirements enforced by process, CI, or both.
- Important: strong requirements that need explicit written rationale if bypassed.
- Recommended: recurring practices that keep the workspace reliable.

## Critical Directives

### CRIT-001. Canonical Governance and SDLC Docs Must Exist

The following files are mandatory:

- `AGENTS.md`
- `CLAUDE.md`
- `CONSTITUTION.md`
- `DIRECTIVES.md`
- `docs/00-doc-suite-index.md`
- `docs/02-prd.md`
- `docs/03-mvp-scope-roadmap.md`
- `docs/05-technical-architecture.md`
- `docs/06-data-model-local-storage.md`
- `docs/08-ai-assistant-retrieval-and-guardrails.md`
- `docs/10-security-privacy-and-safety.md`
- `docs/11-quality-strategy-test-plan-and-acceptance.md`
- accepted ADRs under `docs/adr/`

### CRIT-002. Core Offline Flows Must Not Depend on Connectivity

Core MVP behavior must remain usable offline. Local browsing, quick cards, local persistence, and offline Ask fallback must not require network availability.

### CRIT-003. The Assistant Must Stay Grounded and Cited

The assistant may answer only from approved local content and allowed app data. No live-web answers, no uncited substantive answers, and no general-chat behavior outside documented scope.

### CRIT-004. Persistence Boundaries Must Hold

- `SwiftData` types, `ModelContext`, `FetchDescriptor`, `@Query`, and `@Model` stay inside `OSA/Persistence` or the app composition root.
- `OSA/Domain` and `OSA/Features` must not depend directly on SwiftData APIs.
- Repository protocols and domain models must remain persistence-framework agnostic.

### CRIT-005. Editorial Content and User State Must Stay Separated

Seeded handbook, quick cards, and imported editorial knowledge must not be modeled as if they were mutable user-authored state. Stable editorial identity, provenance, and versioning are required.

### CRIT-006. Privacy and Secret Hygiene Are Mandatory

- No credentials, private keys, bearer tokens, or inline secrets in repository content.
- No hidden analytics SDKs or undocumented outbound data flows.
- Notes, inventory, prompts, and other sensitive local data must remain device-local unless a future documented feature explicitly changes that behavior.

### CRIT-007. Verification Claims Require Evidence

Build, test, migration, assistant, offline, and security claims require explicit command or artifact evidence. If verification is blocked by the environment, the claim must be reported as `unverified`.

### CRIT-008. Project Generation Must Stay in Sync

When `project.yml` changes, or when target/project structure changes require it, run `xcodegen generate` and keep `OSA.xcodeproj` aligned with the manifest.

### CRIT-009. Security Review Is Required for New First-Party Code or Dependency Changes

When substantive first-party code, networking behavior, import logic, or security-sensitive configuration changes, run `snyk code test --path="$PWD"` if `snyk` is available. Dependency-manifest changes require the matching dependency-security scan when a supported manifest exists.

### CRIT-010. Sensitive-Scope Boundaries May Not Widen Silently

Medical-adjacent guidance, weapon-related content, foraging, and hazardous improvisation rules may not be widened by code or content changes without matching documentation and safety rationale.

## Important Directives

### IMP-001. Code and Docs Must Agree

When implementation changes invalidate canonical docs or ADRs, update the docs or report the drift explicitly.

### IMP-002. Prefer Boundary Discipline Over Target Proliferation

For OSA v1, keep boundaries clean in folders and protocols before introducing additional Xcode targets or packages.

### IMP-003. Online Enrichment Must Preserve Local Trust Boundaries

Imported sources are not assistant-usable until normalization, attribution, local commit, and any required review state complete successfully.

### IMP-004. Report Exact Environment Blockers

When tooling blocks verification, report the exact command, failure mode, and date rather than summarizing vaguely.

### IMP-005. No Premature Abstraction

Do not add generic repositories, plugin systems, service locators, or sync architectures without immediate product need.

### IMP-006. User-Facing Network Behavior Must Be Understandable

The UI and reporting must make it clear when the app is local-only, when local evidence is insufficient, and when an online option is being offered.

## Recommended Directives

### REC-001. Add Focused Tests for Persistence, Retrieval, and Policy Changes

Persistence, import, retrieval, and assistant-policy changes should land with focused tests whenever the project structure supports them.

### REC-002. Keep Files and Functions Manageable

Prefer source files under roughly 500 lines and functions with modest complexity unless a stronger local reason exists.

### REC-003. Capture Durable Identity Early

Use stable IDs, slugs, version markers, and content hashes where the docs call for durable editorial identity.

### REC-004. Use Absolute Dates in Reports

When reporting blockers, verification runs, or review decisions, include concrete dates to avoid ambiguity.

## Verification Commands

```bash
xcodegen generate
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
snyk code test --path="$PWD"
```
