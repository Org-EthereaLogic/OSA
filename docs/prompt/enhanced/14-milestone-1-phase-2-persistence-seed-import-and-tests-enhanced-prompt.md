# Milestone 1 Phase 2 Enhanced Prompt: Persistence, Seed Import, And Repository Tests

**Date:** 2026-03-22
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This work spans domain contracts, SwiftData schemas, bundled seed-data import, app bootstrap wiring, and substantive repository tests across multiple existing folders and the current test target. It touches architecture boundaries, persistence identity rules, and verification requirements in one phase-sized change.

## Inputs Consulted

- Source prompt: `/Prompt_Enhancement Next Steps` followed by `Milestone 1 Phase 2: Implement the repository protocols in Domain and the SwiftData schema in Persistence. Seed Data: Filling the SeedManifest.json and implementing the SeedImport logic. Focused Tests: Building substantive tests against the repository contracts.`
- Project operating rules: `AGENTS.md`, `DIRECTIVES.md`, `CLAUDE.md`, `CONSTITUTION.md`
- Security/compliance rules: `.github/instructions/codacy.instructions.md`, `snyk_rules.instructions.md`, `docs/sdlc/10-security-privacy-and-safety.md`
- Project context: `README.md`, `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md`, `docs/sdlc/09-content-model-editorial-guidelines.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- ADRs: `docs/adr/ADR-0001-offline-first-local-first.md`, `docs/adr/ADR-0002-grounded-assistant-only.md`, `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`, `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`
- Build and test manifests: `project.yml`, `OSATests/README.md`
- Codebase reality: `OSA/Domain/`, `OSA/Persistence/`, and `OSATests/` scaffolds are present; `project.yml` already defines the `OSATests` unit-test target.

## Classification Summary

- Core intent: complete Milestone 1 Phase 2 by landing the first real persistence slice, first-launch seed import, and repository-contract tests without violating OSA's boundary rules.
- In scope: domain models and repository protocols, SwiftData models and repository implementations, seed manifest population strategy, bundled seed import path, minimal app bootstrap integration, and focused repository tests.
- Out of scope: retrieval ranking, Ask orchestration, online import/refresh, feature UI expansion, sidecar search index implementation, and non-foundation user-data CRUD beyond what the selected schema slice strictly requires.

## Assumptions

- The repository root is confirmed because `AGENTS.md` and `DIRECTIVES.md` exist at the workspace root.
- `OSA`, `OSATests`, and `OSAUITests` are already configured in `project.yml`; no new test target is needed unless the current target cannot host the required tests.
- The first implementation slice should prioritize bundled editorial content and first-launch offline readiness over broader user-state or networking models.
- `OSA/Resources/SeedContent/` is the correct bundle location for seed files because it is already included as a project resource path in `project.yml`.
- If any part of the source prompt conflicts with the docs, the docs and ADRs take precedence.

## Mission Statement

Implement the smallest production-grade persistence foundation that makes OSA cold-start with normalized local seed content, exposes persistence-agnostic repository contracts to the rest of the app, and proves the contract with focused tests.

## Technical Context

Milestone 1 Phase 1 is complete, so the next blocker is not more UI. The roadmap, architecture, and data-model docs all point to the same sequence: define repository boundaries first, persist seed editorial content locally, and verify the offline-first foundation before building retrieval and feature-heavy flows. The current repository already has the right structural scaffolding and an existing unit-test target, so the agent should not spend time inventing a new project shape.

This phase must respect a few hard constraints:

- `OSA/Domain` owns repository contracts and domain-facing types.
- `OSA/Persistence` owns `SwiftData`, `ModelContext`, `@Model`, migration helpers, and seed-import implementation details.
- Seeded editorial content must stay distinct from mutable user-authored state.
- The result must keep the app useful offline and ready for future retrieval and citation work without leaking persistence details into feature code.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `OSA/Domain` contains only folder scaffolds and README guidance. | Domain-facing content models and repository protocols exist in the correct subdomains with no `SwiftData` imports. |
| `OSA/Persistence` has no real schemas or repository implementations. | SwiftData models, mappings, repository implementations, and bootstrap wiring exist for the first editorial-content slice. |
| `OSA/Resources/SeedContent/` is bundled but not yet modeled as versioned app seed data. | Seed manifest content exists, is parseable, and can drive deterministic first-launch import or seed upgrade logic. |
| First-launch offline readiness depends on static resources only. | The app can import bundled seed content into the local store so later browsing, search, and Ask can operate against normalized local records. |
| `OSATests` is scaffolded but does not yet prove repository behavior. | Focused tests validate seed import and repository-contract behavior against the new persistence slice. |

## Pre-Flight Checks

1. Confirm the project root before editing.
   *Success signal: `test -f AGENTS.md && test -f DIRECTIVES.md` prints a positive confirmation from the repository root.*

2. Inspect `project.yml`, `OSA/Domain/`, `OSA/Persistence/`, `OSA/Resources/SeedContent/`, and `OSATests/` before choosing file paths.
   *Success signal: the agent can name the exact files it will add or edit and can state that `OSATests` already exists.*

3. Re-read the Milestone 1 constraints from `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, and `docs/sdlc/06-data-model-local-storage.md` immediately before implementation.
   *Success signal: the chosen entity slice and repository boundaries match the docs without speculative expansion.*

4. Identify the seed-content shape already present under `OSA/Resources/SeedContent/` and decide whether `SeedManifest.json` should be filled in-place or created if currently absent.
   *Success signal: the agent knows the manifest filename, record types it will describe, and bundle path from which the app will load it.*

## Workspace Constraints To Respect

- Keep the app offline-first; no connectivity dependency may be introduced into core flows.
- Keep the assistant grounded model intact by preparing local content, not live-web paths.
- Keep `SwiftData` details out of `OSA/Domain` and feature-layer code.
- Keep editorial content identity and user state separated.
- Prefer the smallest coherent implementation that satisfies Milestone 1 Phase 2.
- Use stable IDs, slugs, version markers, and content hashes where the docs call for durable identity.
- Treat build, test, and security outcomes as evidence-backed only; otherwise report them as unverified.
- Run the required verification commands for project generation, build, tests, and Snyk when the environment supports them.

## Phased Instructions

### Phase 1: Freeze The Persistence Slice

1. Choose the minimal editorial-content slice required to satisfy Milestone 1 offline browseability: handbook chapters, handbook sections, quick cards, and any shared metadata needed to import them cleanly.
   *Success signal: the agent explicitly states which entities are included now and which are deferred, such as checklist runs, notes, inventory, imported web knowledge, AI sessions, and search-index persistence.*

2. Define stable identity rules for each included record before writing models.
   *Success signal: each included record has a UUID policy and, where required, a durable slug, sort order, version marker, review date, and content-hash or manifest-trace strategy.*

3. Keep the first slice aligned with the current bundled-content need rather than a generic full-schema pass.
   *Success signal: no broad generic repository or speculative abstraction is introduced just to look future-proof.*

### Phase 2: Create Domain Contracts

1. Add domain-facing content models under `OSA/Domain/Content/` that represent the editorial records needed by this phase.
   *Success signal: the new domain models are plain Swift types or protocol-friendly value types and do not import `SwiftData`.*

2. Add repository protocols in `OSA/Domain/Content/` or adjacent domain subfolders for the concrete workflows this phase needs.
   *Success signal: protocols cover listing chapters, loading chapter detail, loading quick cards, checking or recording seed-manifest version state, and upserting bundled editorial content without exposing persistence-framework types.*

3. Keep repository method signatures concrete and near-term.
   *Success signal: the contracts are shaped around first-launch import, reload, fetch-by-slug or ID, and ordered reads rather than generic CRUD buckets.*

4. Add only the shared supporting types that materially improve correctness, such as repository error types, seed-version descriptors, or import summaries.
   *Success signal: support types exist because the workflow needs them, not as a speculative taxonomy exercise.*

### Phase 3: Implement SwiftData Models And Mappings

1. Add SwiftData `@Model` types under `OSA/Persistence/SwiftData/` for the same editorial slice.
   *Success signal: relationships, delete rules, indexing-related fields, and metadata fields align with `docs/sdlc/06-data-model-local-storage.md` and do not mix mutable user state into seeded editorial records.*

2. Add mapping code between persistence models and domain models.
   *Success signal: repository implementations can translate persistence records into domain-facing values without any `SwiftData` symbol leaking into `OSA/Domain` or future feature code.*

3. Add repository implementations under `OSA/Persistence/` that satisfy the domain protocols using `ModelContext` internally.
   *Success signal: the concrete implementations perform deterministic ordered reads and upserts for the selected editorial-content records.*

4. Add minimal bootstrap wiring in the app composition root so the persistence container and repository implementations have one clear creation path.
   *Success signal: the app target compiles with a concrete model-container setup and a defined handoff point for repository injection, even if the feature UI does not yet consume every repository directly.*

### Phase 4: Fill The Seed Manifest And Implement Seed Import

1. Inspect the bundled seed-content files and finalize `SeedManifest.json` so it describes the versioned seed bundle that will be imported.
   *Success signal: the manifest contains explicit version metadata, content-pack or record counts, and enough identity information to decide whether a first-launch import or seed upgrade is required.*

2. Implement seed-manifest loading and validation under `OSA/Persistence/SeedImport/`.
   *Success signal: the app can read the manifest from bundled resources, decode it deterministically, and surface meaningful errors when required files or fields are missing.*

3. Implement the seed-import coordinator or importer that transforms bundled content into normalized repository writes.
   *Success signal: the importer can upsert bundled chapters, sections, and quick cards in a repeatable order using stable identity rules and can skip or reconcile already-imported seed versions without duplicating records.*

4. Ensure seed import is safe for offline-first startup and future reruns.
   *Success signal: an interrupted or repeated seed-import call does not corrupt the local editorial corpus, and the importer can detect whether the bundle version is already active.*

### Phase 5: Add Focused Repository Tests

1. Use the existing `OSATests` target to add substantive tests close to the new persistence behavior.
   *Success signal: tests live under `OSATests/` and do not require creating a new target unless a concrete project limitation blocks them.*

2. Write deterministic tests for seed-manifest decoding, first-run import, repeat import or version-check behavior, and ordered repository reads.
   *Success signal: the tests prove the repository contracts instead of only checking that types compile.*

3. Add at least one test that validates the domain-facing repository contract from the perspective of a consumer.
   *Success signal: the test asserts behavior such as stable chapter ordering, chapter-section relationships, or quick-card retrieval without depending on UI code.*

### Phase 6: Verification And Security

1. Regenerate the Xcode project if `project.yml` or target structure changed.
   *Success signal: `xcodegen generate` completes successfully and `OSA.xcodeproj` stays aligned with `project.yml`.*

2. Build the app target after the persistence and seed-import changes.
   *Success signal: `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build` finishes with `** BUILD SUCCEEDED **`, or any blocker is captured exactly and marked unverified.*

3. Run the test suite for the unit-test target.
   *Success signal: `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test` finishes with `** TEST SUCCEEDED **`, or failures are traced to specific new files and fixed before stopping.*

4. Run the required first-party code security scan.
   *Success signal: `snyk code test --path="$PWD"` is executed from the repository root when `snyk` is available, and any findings tied to this work are fixed or reported explicitly as residual risk.*

## Guardrails

- Do not implement retrieval, ranking, Ask orchestration, or online knowledge refresh in this phase.
- Do not expose `SwiftData`, `ModelContext`, `FetchDescriptor`, `@Model`, or `@Query` outside `OSA/Persistence` or the composition root.
- Do not invent a generic base repository or service locator.
- Do not widen the persistence slice to all entity families just because the docs list them.
- Do not mix seed editorial content with mutable user-authored records in the same model types.
- Do not claim build, test, or security success without command evidence.
- Keep any environment blocker explicitly labeled as `unverified`.

## Verification Checklist

- [ ] Project root was confirmed before edits.
- [ ] The selected entity slice was explicitly frozen before implementation.
- [ ] Domain-facing models exist under the domain boundary with no `SwiftData` imports.
- [ ] Repository protocols exist for the selected Milestone 1 workflows.
- [ ] SwiftData models and mappings exist for the same slice.
- [ ] `SeedManifest.json` is present and populated with versioned seed metadata.
- [ ] Seed-import logic can decode and import bundled content deterministically.
- [ ] The app bootstrap has one clear persistence-container setup path.
- [ ] `OSATests` contains repository and seed-import tests that validate behavior, not just compilation.
- [ ] Build verification was run or reported as blocked.
- [ ] Test verification was run or reported as blocked.
- [ ] Snyk verification was run or reported as blocked.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| `AGENTS.md` or `DIRECTIVES.md` missing at the presumed root | Stop and ask the user to confirm the correct project root before proceeding. |
| The bundled seed-content format is inconsistent or incomplete | Normalize the file shape first, then keep the manifest and importer aligned to the actual bundled-content structure rather than guessing missing fields. |
| A repository protocol starts exposing `SwiftData` or persistence-only concerns | Move those concerns back into `OSA/Persistence` and replace them with domain-facing inputs and outputs. |
| Seed import duplicates records on rerun | Introduce or fix stable identity matching using slugs, UUIDs, manifest version markers, or content hashes before adding more features. |
| Tests require bundle resources that the target cannot currently see | Adjust the test fixture strategy or target resource setup minimally, then rerun tests instead of weakening repository coverage. |
| `xcodebuild` fails because full Xcode or the simulator runtime is unavailable | Report the exact command and failure output, keep build or test claims unverified, and do not claim success. |
| `snyk` is unavailable or unauthenticated | Report the exact blocker and keep the related security claim unverified. |

## Out Of Scope

- Search-index storage or FTS implementation.
- Imported web knowledge models or refresh queues beyond any seed-version state strictly needed for bundled content.
- Inventory, notes, checklist runs, AI sessions, or settings persistence unless a tiny shared type is required by the selected slice.
- UI polish, navigation changes, or feature-surface redesign.
- Foundation Models or assistant answer-generation work.

## Report Format

When implementation is complete, report in this structure:

1. Files added and files changed.
2. Entity slice chosen and deferred entities.
3. Repository protocols and domain models added.
4. SwiftData models, mappings, and bootstrap integration added.
5. Seed-manifest and seed-import behavior implemented.
6. Tests added and what each one proves.
7. Verification commands run and their outcomes.
8. Security-analysis status, including blocked tooling if any.
9. Remaining risks, deferred work, or explicitly unverified claims.
