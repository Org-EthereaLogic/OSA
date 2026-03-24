# Milestone 3 Phase 3 Enhanced Prompt: Capability Detection And Model Adapter

**Date:** 2026-03-24
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task crosses runtime platform capability detection, assistant service composition, model-adapter protocol design, and fallback routing. It must preserve the grounded retrieval pipeline, keep extractive behavior working on unsupported hardware, and create a clean boundary for later prompt shaping in M3P5.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow` with the note: `Recommended next step: M3P3 (Capability detection and model adapter).`
- User rationale: M3P3 is the critical-path blocker for prompt shaping, completes the Ask vertical, and unlocks meaningful safety testing by adding real Foundation Models detection and a generation adapter protocol.
- Project governance: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Product and architecture docs: `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Architecture decisions: `docs/adr/ADR-0002-grounded-assistant-only.md`, `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`
- Current assistant code surfaces: `OSA/Assistant/ModelAdapters/DeviceCapabilityDetector.swift`, `OSA/Assistant/Policy/SensitivityPolicy.swift`, `OSA/Assistant/README.md`
- Current ask and retrieval code surfaces: `OSA/Domain/Ask/Models/RetrievalModels.swift`, `OSA/Domain/Ask/Repositories/AskRepositories.swift`, `OSA/Retrieval/Querying/LocalRetrievalService.swift`
- App wiring surface: `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`

## Assumptions

- The repository root contains `project.yml`, `OSA.xcodeproj`, `README.md`, and `docs/`.
- Milestone 3 Phase 1 retrieval, citation packaging, sensitivity policy, and Ask UI routing already exist and should not be reworked as part of this task.
- `DeviceCapabilityDetector` currently hardcodes the extractive path and needs to become a real runtime capability check.
- The new generation adapter should stay behind a protocol so Foundation Models details do not leak into feature views or retrieval orchestration.
- Prompt shaping belongs to M3P5; this task should create the generation boundary, not a fully polished prompt-template layer.
- Seed content expansion can continue in parallel because it does not depend on model-capability detection.

## Mission Statement

Implement the model-capability boundary for Ask so the app can choose grounded generation on supported devices and extractive fallback everywhere else, while keeping retrieval deterministic, local, and testable.

## Technical Context

Milestone 3 already has the grounded retrieval substrate in place. `LocalRetrievalService` normalizes queries, applies sensitivity policy, searches the local FTS5 index, re-ranks evidence, packages citations, and assembles extractive answers. `AppDependencies.live` wires `DeviceCapabilityDetector` into that service, but the detector currently behaves like a stub and the generation path is still folded into extractive answer assembly.

M3P3 should close that gap by introducing a real runtime capability check for Apple Foundation Models and a small generation-adapter abstraction. The adapter should be the only layer that knows how to synthesize grounded prose on capable devices. Retrieval should continue to supply evidence, citations, and fallback-safe answer metadata without becoming model-specific.

The implementation should respect the current answer-path vocabulary already used by the codebase:

- `groundedGeneration` when supported generation is available.
- `extractiveOnly` when the device cannot support grounded synthesis.
- `searchResultsOnly` only if the orchestration path truly needs a no-prose mode.

If the current `AnswerMode` contract remains sufficient, reuse it. If a separate capability type is needed to represent supported versus unsupported model availability, introduce the smallest additional value type necessary and keep it local to the assistant boundary.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `DeviceCapabilityDetector` is a placeholder that defaults to extractive-only behavior. | Runtime capability detection distinguishes grounded-generation support from extractive fallback. |
| `LocalRetrievalService` still assembles answer text directly. | A generation adapter handles grounded synthesis on supported devices, while retrieval continues to package evidence and citations. |
| `OSA/Assistant/ModelAdapters/` contains only the capability detector. | A model-adapter protocol and concrete Foundation Models implementation exist behind the assistant boundary. |
| `AppDependencies.live` wires retrieval without a generation adapter. | The composition root injects both capability detection and the generation adapter where needed. |
| Safety and retrieval tests cover local evidence flow, but not AI-capability branching. | Tests cover supported and unsupported device paths, adapter routing, and extractive fallback behavior. |

## Pre-Flight Checks

1. Confirm the current Ask, Retrieval, Assistant, and App bootstrap code before editing.
   *Success signal: the agent can name the exact files it will add or edit and explain how each participates in the capability path.*

2. Confirm which device-capability states the implementation must support.
   *Success signal: the agent can state how grounded-generation support, extractive-only fallback, and any no-prose state are represented.*

3. Confirm the boundary between M3P3 and M3P5.
   *Success signal: the agent can describe what belongs in capability detection and adapter wiring now versus prompt shaping later.*

4. Confirm the test strategy for supported and unsupported model availability.
   *Success signal: the agent can explain how to force both branches without depending on a specific device in unit tests.*

## Phased Instructions

### Phase 1: Freeze The Capability Scope

1. Keep the task focused on runtime model-capability detection and adapter routing.
   *Success signal: there is a clear answer to whether the device can use grounded generation, and the answer is not hardcoded.*

2. Preserve the retrieval pipeline contract from M3P1.
   *Success signal: the search, ranking, citation packaging, and refusal logic remain intact and are not reimplemented here.*

3. Keep prompt shaping and safety-template refinement out of scope.
   *Success signal: the generation boundary exists, but M3P5 still has room to define the actual prompt-shaping layer.*

4. Treat seed-content expansion and editorial work as parallel and independent.
   *Success signal: no code dependency is introduced on content-authoring tasks.*

### Phase 2: Define The Model-Adapter Boundary

1. Add a small protocol for grounded answer generation behind the assistant boundary.
   *Success signal: callers can request grounded synthesis without knowing the Foundation Models API surface directly.*

2. Keep protocol inputs explicit and bounded.
   *Success signal: the adapter receives retrieved evidence, citation context, and any narrow style or policy inputs it genuinely needs, but not an open-ended chat history API.*

3. Keep protocol outputs useful to the Ask flow.
   *Success signal: the adapter returns grounded answer text or a structured answer result that the UI can render with citations and suggested actions.*

4. Place the concrete Foundation Models implementation under `OSA/Assistant/ModelAdapters/`.
   *Success signal: Foundation Models imports and platform-specific code stay behind the adapter implementation, not in feature views or retrieval services.*

### Phase 3: Implement Real Capability Detection

1. Replace the hardcoded extractive-only detector with a real runtime capability check.
   *Success signal: the detector can distinguish supported grounded-generation devices from unsupported ones at runtime.*

2. Make capability detection testable.
   *Success signal: unit tests can force supported and unsupported states without relying on the host machine’s actual model availability.*

3. Keep detection deterministic and local.
   *Success signal: the app does not depend on network access or remote feature flags to decide whether grounded generation is available.*

4. Avoid overfitting detection to one OS release if a broader supported runtime already exists in the codebase.
   *Success signal: the implementation follows the platform API and the app’s iOS 18 minimum target, rather than baking in arbitrary version constants.*

### Phase 4: Route Ask Through The Adapter

1. Update the Ask orchestration path to select grounded generation when supported.
   *Success signal: supported devices reach the generation adapter and unsupported devices continue to use extractive fallback.*

2. Keep extractive fallback working exactly as it does today.
   *Success signal: unsupported devices still return grounded local evidence via extractive answer assembly and citations.*

3. Preserve citation integrity across both paths.
   *Success signal: generated answers still point back to the same local evidence references the retrieval pipeline already assembled.*

4. Keep the adapter boundary small enough that M3P5 can refine prompt shaping later without changing the routing contract.
   *Success signal: the adapter can accept a better prompt payload later without forcing another retrieval rewrite.*

### Phase 5: Wire The Composition Root

1. Update `AppDependencies.live` so the new adapter is created or injected alongside the existing retrieval services.
   *Success signal: the app has one obvious place where capability detection and generation wiring are composed.*

2. Keep feature views free of Foundation Models dependencies.
   *Success signal: SwiftUI screens still depend on app-level services or repository abstractions, not on platform model APIs.*

3. Maintain the current offline-first startup behavior.
   *Success signal: Ask still opens immediately, and capability detection does not add blocking startup work.*

4. Preserve the current extraction path in the default app configuration.
   *Success signal: any device without supported generation continues to behave safely and predictably.*

### Phase 6: Add Focused Tests And Verification

1. Add tests for capability detection.
   *Success signal: the tests prove the detector returns the expected capability tier for supported and unsupported conditions.*

2. Add tests for adapter routing.
   *Success signal: grounded-generation devices call the adapter path and unsupported devices fall back to extractive assembly.*

3. Add tests for citation-preserving answer assembly.
   *Success signal: both paths still surface the local evidence the retrieval pipeline produced.*

4. Run the relevant build and test checks for the touched code.
   *Success signal: the implementation is verified, or any blocker is reported precisely as unverified.*

## Guardrails

- Do not change the retrieval ranking or citation packaging logic unless a small adapter input requires it.
- Do not implement M3P5 prompt shaping, prompt templates, or assistant-style tuning in this task.
- Do not block Ask on unsupported hardware or unsupported model availability.
- Do not add a third-party bundled model or network dependency.
- Do not expose Foundation Models details directly to feature views.
- Do not let generated prose escape without the retrieval pipeline’s evidence and citation contract.
- Do not widen scope to online knowledge refresh, import, or seed-content authoring.

## Verification Checklist

- [ ] The current hardcoded capability stub was replaced or wrapped with real runtime detection.
- [ ] A generation-adapter protocol exists behind the assistant boundary.
- [ ] The concrete Foundation Models implementation lives outside feature views.
- [ ] Ask routes to grounded generation on supported devices.
- [ ] Ask still falls back to extractive answers on unsupported devices.
- [ ] Citations and evidence references remain intact in both paths.
- [ ] Capability routing is unit-tested with supported and unsupported scenarios.
- [ ] Build or test verification was run, or blockers were reported explicitly.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| Foundation Models are unavailable at runtime | Use extractive fallback and preserve the existing grounded retrieval result shape. |
| Capability detection is not testable | Introduce a tiny injected availability-check abstraction and test both branches deterministically. |
| The adapter starts leaking Foundation Models details into feature code | Move the platform-specific logic back behind `OSA/Assistant/ModelAdapters/` and keep callers on the protocol. |
| Generated output loses citations or grounded evidence | Return to the retrieval contract and require the adapter to consume the packaged evidence bundle. |
| Prompt shaping starts creeping into this phase | Defer it to M3P5 and keep this task limited to capability detection and adapter routing. |
| Verification tooling is unavailable | Report the exact blocker and keep build or test claims unverified. |

## Out Of Scope

- Prompt shaping, system-prompt editing, or safety-guardrail tuning beyond the adapter boundary.
- Online knowledge refresh, import, or network-backed answer generation.
- Re-ranking, retrieval-policy redesign, or citation-packaging changes that are unrelated to model-capability routing.
- A bundled third-party local model.
- Seed-content authoring or other parallel content tasks.

## Report Format

When the implementation is complete, report back in this structure:

1. Files added and files changed.
2. Capability states supported and how they are detected.
3. Model-adapter protocol and concrete implementation added.
4. Ask and composition-root wiring changes.
5. Tests added and what each one proves.
6. Verification commands run and their outcomes.
7. Remaining risks, deferred work, or explicitly unverified claims.
