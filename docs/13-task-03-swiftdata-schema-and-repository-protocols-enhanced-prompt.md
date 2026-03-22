# Task 3 Enhanced Prompt: SwiftData Schema And Repository Protocols

**Date:** 2026-03-22
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task establishes the first real persistence boundary for the app, introduces multiple new domain and persistence files, requires project-target awareness, and should include verification for both buildability and repository behavior.

## Inputs Consulted

- Source prompt: `/Prompt_Enhancement next step per the roadmap is Task 3: SwiftData schema and repository protocols (Milestone 1 continuation)`
- Security/compliance rules: `.codacy/codacy.yaml` (Codacy configuration at `.codacy/`)
- Security/compliance rules: `snyk_rules.instructions.md`
- Project context: `README.md`
- Project context: `docs/03-mvp-scope-roadmap.md`
- Project context: `docs/05-technical-architecture.md`
- Project context: `docs/06-data-model-local-storage.md`
- Project context: `docs/10-security-privacy-and-safety.md`
- Project context: `docs/11-quality-strategy-test-plan-and-acceptance.md`
- Build manifest: `project.yml`
- Codebase reality: `OSA/App/*.swift`, `OSA/Features/**/*.swift`, and empty `OSA/Domain`, `OSA/Persistence`, `OSA/Assistant`, `OSA/Networking`, `OSA/Retrieval`

## Assumptions

- `AGENTS.md`, `DIRECTIVES.md`, `CLAUDE.md`, and `CONSTITUTION.md` are present at the repository root.
- The repository root is the folder containing `project.yml`, `OSA.xcodeproj`, `README.md`, and `docs/`.
- The app target remains a single iOS app target for now, with architectural boundaries enforced by folders and protocols rather than separate Swift packages.
- The deployment target remains iOS 18.0 and Swift 6.0 as defined in `project.yml`.
- There is no existing unit test target; if verification requires tests, create the smallest viable unit test target rather than skipping test coverage.

## Mission Statement

Implement the first production-grade local persistence slice for OSA by defining SwiftData schemas and repository protocols for the Milestone 1 content model, with minimal scaffolding that supports seed-content import and future feature work without leaking SwiftData details into feature code.

## Technical Context

Milestone 1 is still in the foundation phase. The roadmap and architecture docs say persistence and repository protocols must land before feature UI expands. The data-model doc already defines candidate entities and explicitly recommends converting them into SwiftData schemas and repository protocols before building more UI. The current codebase contains only app shell and placeholder feature views, so the correct move is to create domain-facing protocols and a persistence implementation scaffold, not full feature CRUD.

The architecture docs also constrain the shape of the solution:

- Use SwiftData for v1.
- Keep repository protocols in the domain boundary.
- Keep persistence details out of feature code.
- Preserve a future path to Core Data replacement by avoiding direct SwiftData calls outside persistence.
- Prioritize offline-first seed content and durable local identity.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `OSA/Domain` and `OSA/Persistence` are effectively empty. | Domain models and repository protocols exist for the first persistence slice. |
| No SwiftData schemas are defined. | SwiftData `@Model` types exist for Milestone 1 foundation records. |
| Feature code has no persistence abstraction to depend on. | Protocol-first repositories define the contract for future content, checklist, notes, and inventory services. |
| No persistence container/bootstrap path exists. | A minimal persistence bootstrap exists and can be injected into the app shell. |
| No automated verification exists for this layer. | Build verification exists, and repository or model tests cover the new slice. |

## Pre-Flight Checks

1. Confirm the project root before changing files.
   *Success signal: the root contains `project.yml`, `OSA.xcodeproj`, and `docs/`.*

2. Check for `AGENTS.md` and `DIRECTIVES.md` at the project root.
   *Success signal: both files exist, or the agent stops and asks the user to confirm whether to proceed without them.*

3. Inspect current source layout under `OSA/Domain`, `OSA/Persistence`, and `OSA/App`.
   *Success signal: the agent can name the concrete files and folders it will add or edit before implementation.*

4. Confirm the build configuration from `project.yml` and current Xcode project contents.
   *Success signal: the agent can state the app target name, iOS deployment target, and whether a test target already exists.*

## Phased Instructions

### Phase 1: Define The Minimal Foundation Slice

1. Derive the implementation scope from `docs/03-mvp-scope-roadmap.md`, `docs/05-technical-architecture.md`, and `docs/06-data-model-local-storage.md`, then freeze the first schema slice before writing code.
   *Success signal: the agent explicitly lists the entities included in Task 3 and the entities deferred to later milestones.*

2. Keep Task 3 focused on the foundation records needed for seed-content import and browsing readiness.
   *Success signal: the initial schema covers handbook content and adjacent foundational records first, while deferring unrelated online-import or AI-session entities unless a shared base abstraction genuinely requires them.*

3. Define stable identity and versioning rules for the included records.
   *Success signal: each included entity has a clear identifier strategy such as UUID plus stable slug or content hash where required by the docs.*

### Phase 2: Create Domain Models And Repository Contracts

1. Add domain-facing model types under `OSA/Domain/Models` for the first persistence slice.
   *Success signal: the domain layer exposes plain Swift types or value-oriented transfer models that do not import SwiftData.*

2. Add repository protocols under `OSA/Domain` or `OSA/Domain/Repositories` for the initial use cases.
   *Success signal: protocols exist for reading handbook chapters and sections, loading quick cards, and supporting the first seed import workflow without exposing persistence-framework types.*

3. Define repository method signatures around real near-term needs rather than speculative generic CRUD.
   *Success signal: method names support concrete workflows such as bootstrap import, list chapters, fetch chapter detail, fetch quick cards, and upsert seeded content.*

4. Add error and result types only where they materially clarify repository behavior.
   *Success signal: repository contracts express failure or empty-state behavior consistently without introducing a large custom error taxonomy.*

### Phase 3: Implement SwiftData Schemas And Mapping

1. Add SwiftData schema types under `OSA/Persistence` for the same entity slice.
   *Success signal: each persisted type is annotated appropriately, relationships are explicit, and fields align with the approved docs rather than ad hoc UI placeholders.*

2. Keep editorial content identity separate from mutable user-state concerns.
   *Success signal: seeded handbook and quick-card records do not mix mutable user-specific state into the same model types.*

3. Add mapping code between persistence models and domain models.
   *Success signal: the domain layer remains free of SwiftData imports, and feature code could consume repository outputs without knowing the storage framework.*

4. Add a minimal persistence bootstrap, such as a model container configuration and a repository implementation entry point, under `OSA/Persistence` and wire it into the app shell only as far as needed.
   *Success signal: the app compiles with a concrete container/bootstrap path, even if placeholder feature screens do not yet consume the repositories directly.*

### Phase 4: Seed-Import Readiness And App Integration

1. Implement the smallest repository implementation set needed for first-launch seed-content import readiness.
   *Success signal: repository implementations can insert or update seeded handbook and quick-card content deterministically using stable identity rules.*

2. Add a lightweight seed-manifest or seed-import interface only if required to make repository contracts coherent.
   *Success signal: the code supports future seed import without prematurely building the full import pipeline.*

3. Integrate the persistence bootstrap into `OSA/App/OSAApp.swift` or the nearest composition root using minimal scope.
   *Success signal: the app target has one clear place where the model container and repository implementations are created or prepared for injection.*

### Phase 5: Verification And Quality

1. Add or update a unit test target if one does not exist, then write focused tests for schema mapping or repository behavior.
   *Success signal: at least one test validates seeded-content insert/read behavior, stable ordering, or domain-model mapping for the new repository layer.*

2. Regenerate project files if the test target or source layout requires it.
   *Success signal: project generation succeeds and includes the new source and test files.*

3. Build and test the project with explicit commands.
   *Success signal: the selected build and test commands complete successfully, or failures are traced to specific files and fixed before stopping.*

4. Run the workspace security and quality checks that apply to generated code.
   *Success signal: any required scanner or build-level validation has been executed and new issues introduced by this task are addressed.*

## Guardrails

- Do not implement feature UI beyond the minimal app-bootstrap integration required to compile.
- Do not add networking, retrieval, AI-session, or imported-web-knowledge persistence unless the work is strictly required by the first schema slice.
- Do not expose SwiftData types, `ModelContext`, or `FetchDescriptor` to feature views.
- Prefer the smallest coherent entity set that satisfies Milestone 1 continuation.
- Keep naming aligned with the docs unless the codebase already forces a stronger convention.
- Avoid speculative abstractions such as generic repositories or service locators unless the current code actually needs them.
- Preserve a future migration path by isolating persistence-specific code under `OSA/Persistence`.

## Security/Quality Phase

Use the commands supported by this workspace and the applicable scanner policy:

1. If a new test target is added or `project.yml` changes, regenerate the project:

```sh
xcodegen generate
```

Expected signal: `OSA.xcodeproj` regenerates without errors.

1. Build the app target:

```sh
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected signal: `** BUILD SUCCEEDED **`.

1. If a unit test target exists after implementation, run tests:

```sh
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Expected signal: `** TEST SUCCEEDED **`.

1. Run Snyk code scan for newly generated first-party Swift code because the workspace security rules require scanning new code:

```sh
ROOT="$PWD"
```

Then run the available Snyk code scan against the repository root.

Expected signal: no new high-confidence issues are introduced by this task, or any findings tied to this task are fixed and rescanned.

1. If a Codacy local-analysis tool is available in the environment, analyze each edited file immediately after edits as required by workspace instructions.

Expected signal: no new Codacy issues remain in the edited files.

## Verification Checklist

- [ ] Root confirmation was performed before editing.
- [ ] Missing `AGENTS.md` and `DIRECTIVES.md` were handled explicitly.
- [ ] Domain models exist for the first persistence slice.
- [ ] Repository protocols exist and do not import SwiftData.
- [ ] SwiftData models exist for the same slice.
- [ ] Mapping between persistence and domain models is implemented.
- [ ] App bootstrap creates or prepares the persistence container.
- [ ] Seed-content repository behavior is covered by focused tests.
- [ ] The app target builds successfully.
- [ ] Tests pass if a test target exists.
- [ ] Required security analysis was run for new code.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| `AGENTS.md` or `DIRECTIVES.md` missing at root | Stop and ask the user to confirm the root or approve proceeding without them before code changes. |
| SwiftData relationship design becomes unclear | Reduce the initial schema slice and keep only entities required for seed content and immediate browse flows. |
| Repository protocol starts leaking SwiftData details | Move framework-specific APIs back into `OSA/Persistence` and replace them with domain-friendly method signatures. |
| No unit test target exists | Add the smallest viable unit test target and update project generation so repository behavior can be verified. |
| `xcodebuild` fails on simulator naming | List available simulators and rerun with an installed iPhone simulator name. |
| Snyk or Codacy tooling is unavailable | State the tool gap explicitly, run the build/test verification that is available, and report the missing tool in the completion summary. |

## Out Of Scope

- Full inventory, notes, checklist-run, imported-source, AI-session, or retrieval implementations.
- Search index or SQLite FTS5 implementation.
- Online import pipeline.
- Ask assistant orchestration.
- UI polish beyond any minimal composition-root wiring required for compilation.

## Report Format

When the implementation is complete, report back in this structure:

1. Files added and files changed.
2. Entity slice chosen and why.
3. Repository protocols added.
4. Persistence bootstrap and integration point.
5. Verification commands run and their outcomes.
6. Security-analysis status, including any unavailable tooling.
7. Remaining risks or intentionally deferred follow-up work.
