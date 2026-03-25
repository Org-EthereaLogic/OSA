# Milestone 3 Phase 5 Enhanced Prompt: Assistant Policy, Prompt Shaping, And Safety Guardrails

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task closes the last Milestone 3 gap by connecting assistant policy, prompt shaping, and adversarial safety coverage. It must preserve the grounded retrieval and generation boundaries already in place, keep unsafe prompts from reaching model synthesis, and add regression tests for jailbreak-style and sensitive-topic requests without widening scope into Milestone 4 or content-authoring work.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow` with the note: `Completed: M3P1, M3P2, M3P3, M3P4 (all Milestone 3 phases except one). Not Started: M3P5, seed content expansion. Next logical step: M3P5 — Assistant policy, prompt shaping, and safety guardrails.`
- User rationale: M3P5 is the critical-path blocker because it is the only remaining Milestone 3 phase, prompt shaping was intentionally deferred from M3P3, and safety regression tests do not exist yet.
- Project governance: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Product and architecture docs: `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`
- Supporting decisions: `docs/adr/ADR-0002-grounded-assistant-only.md`, `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`, `docs/adr/ADR-0004-ios18-minimum-target-with-foundation-models.md`
- Current assistant code surfaces: `OSA/Assistant/Policy/SensitivityPolicy.swift`, `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`, `OSA/Assistant/README.md`, `OSA/Assistant/Orchestration/README.md`, `OSA/Assistant/Formatting/README.md`
- Existing test surfaces: `OSATests/SensitivityPolicyTests.swift`, `OSATests/CapabilityDetectionTests.swift`, `OSATests/LocalRetrievalServiceTests.swift`

## Assumptions

- Milestone 3 Phases 1 through 4 are complete and should not be reworked.
- Prompt shaping belongs behind the assistant boundary and should not leak into feature views or retrieval ranking.
- The current `FoundationModelAdapter.buildPrompt()` is intentionally minimal and should be replaced or wrapped by a dedicated prompt-shaping layer.
- Safety regression coverage should be deterministic and local; it should not depend on remote policy services or network access.
- Seed content expansion can continue in parallel because it has no code dependency on M3P5.

## Mission Statement

Implement the assistant policy and prompt-shaping layer that turns retrieved evidence into safe grounded model input, blocks or reroutes unsupported or unsafe requests deterministically, and adds regression tests proving the app does not drift into uncited prose, jailbreak compliance, or sensitive-scope expansion.

## Technical Context

Milestone 3 already has the grounded Ask retrieval pipeline, sensitivity policy, citation packaging, capability detection, model-adapter routing, and bounded Ask UI. The remaining gap is not retrieval. The remaining gap is how the assistant shapes the prompt sent to the generation adapter and how the app enforces safety before synthesis.

`SensitivityPolicy` already classifies obvious blocked and sensitive-static-only requests. `FoundationModelAdapter` currently builds a minimal grounded prompt and leaves style, refusal framing, and structured safety instructions for M3P5. This phase should create a bounded prompt-shaping contract that consumes the retrieval bundle, sensitivity result, and capability mode, then emits model-ready instructions that are conservative, citation-first, and calm under stress.

The implementation should treat policy as a first-class boundary:

- blocked prompts never enter generation
- sensitive-static-only prompts are rerouted to reviewed content or an explicit refusal
- evidence-based prompts remain grounded and cited
- jailbreak attempts, prompt injection, and “ignore previous instructions” style inputs are neutralized before synthesis

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `FoundationModelAdapter.buildPrompt()` is a small inline helper. | A dedicated prompt-shaping layer produces grounded, policy-aware prompts with explicit safety instructions. |
| `SensitivityPolicy` classifies obvious blocked and sensitive-static-only requests. | Policy results are enforced at the assistant boundary and verified against adversarial prompts. |
| Safety coverage exists for basic keyword categories. | Regression tests cover jailbreak phrasing, mixed-intent prompts, scope-override attempts, and sensitive-topic reroutes. |
| Prompt shaping is mentioned as future work in M3P3. | Prompt shaping becomes the active implementation focus and the M3P3 boundary stays stable. |
| Logging boundaries for blocked or sensitive prompts are not regression-tested. | Logging and privacy behavior for rejected prompts is explicitly bounded and tested. |

## Pre-Flight Checks

1. Confirm the current assistant policy, model-adapter, and Ask orchestration code paths before editing.
   *Success signal: the agent can name the files that will change and explain where the prompt-shaping boundary belongs.*

2. Confirm how blocked, sensitive-static-only, and allowed requests should flow through the assistant boundary.
   *Success signal: the agent can describe what gets refused, what gets rerouted to static content, and what is allowed to reach generation.*

3. Confirm the safety regression matrix before implementing tests.
   *Success signal: the agent can list the adversarial prompt classes that must be covered and what each test must prove.*

4. Confirm the logging and privacy expectations for rejected prompts.
   *Success signal: the agent can state whether blocked prompts are logged locally, redacted, or omitted entirely, and why.*

## Phased Instructions

### Phase 1: Freeze The M3P5 Scope

1. Keep the task focused on prompt shaping, policy enforcement, and safety regression coverage.
   *Success signal: no retrieval ranking, citation packaging, capability detection, or online refresh work is introduced.*

2. Preserve the M3P1-M3P4 retrieval and generation contract.
   *Success signal: the assistant still consumes retrieved evidence and citations, and the new layer only changes how that evidence is framed for synthesis.*

3. Keep seed content expansion parallel and independent.
   *Success signal: no feature dependency is added on content-authoring work.*

4. Decide whether the prompt-shaping layer needs a separate reusable type.
   *Success signal: the implementation chooses the smallest useful abstraction, such as a prompt builder or template object, instead of embedding more logic into `FoundationModelAdapter`.*

### Phase 2: Define The Prompt-Shaping Contract

1. Add a bounded prompt-shaping boundary under the assistant layer.
   *Success signal: callers can request grounded synthesis without knowing prompt template details or Foundation Models specifics.*

2. Keep the inputs explicit and narrow.
   *Success signal: the builder receives the query, sensitivity classification, capability mode, evidence bundle, citation bundle, and minimal style/policy metadata only.*

3. Keep the outputs model-ready and inspectable.
   *Success signal: the builder returns a prompt or structured payload that clearly separates system instructions, evidence, refusal instructions, and citation expectations.*

4. Preserve the ability to evolve style later.
   *Success signal: the structure leaves room for later tuning without forcing another retrieval rewrite.*

### Phase 3: Implement Prompt Shaping And Guardrail Enforcement

1. Replace the inline minimal prompt with a dedicated prompt-shaping layer.
   *Success signal: `FoundationModelAdapter` delegates prompt construction instead of assembling the prompt inline.*

2. Encode grounding rules directly in the prompt.
   *Success signal: the prompt tells the model to use only retrieved evidence, refuse unsupported claims, and cite the supplied evidence identifiers.*

3. Add conservative style constraints.
   *Success signal: the answer style remains calm, concise, evidence-first, and suitable for stress-state reading.*

4. Block prompt injection and scope-override attempts before synthesis.
   *Success signal: inputs that attempt to override policy, reveal hidden instructions, or expand into unsupported advice are refused or rerouted instead of reaching the model unchanged.*

5. Route sensitive-static-only topics to reviewed static content.
   *Success signal: first-aid or hazard queries do not become free-form generation tasks when static guidance is the safer path.*

6. Keep blocked categories out of generation entirely.
   *Success signal: tactical, hunting, foraging, medical dosage, and unsafe improvisation prompts do not reach the generation adapter as answer candidates.*

### Phase 4: Add Safety Regression Tests

1. Expand sensitivity coverage with adversarial prompt variants.
   *Success signal: the tests prove that jailbreak phrasing, mixed safe/unsafe prompts, and scope-override language are classified correctly.*

2. Add prompt-shaping tests that inspect the generated instruction payload.
   *Success signal: the tests prove grounding instructions, refusal rules, citation requirements, and style constraints are present where expected.*

3. Add routing tests for blocked and sensitive-static-only cases.
   *Success signal: blocked prompts never reach generation and sensitive-static-only prompts are handled by the safer bounded path.*

4. Add regression tests for citation integrity and uncited-prose prevention.
   *Success signal: the answer path cannot emit uncited content when the evidence bundle is insufficient or the request is out of scope.*

5. Add a privacy-bounded logging test if the codebase logs rejected prompts.
   *Success signal: blocked prompt logging, if present, is local, minimal, and redacted enough to avoid exposing sensitive content unnecessarily.*

### Phase 5: Verify The Assistant Boundary

1. Verify that the adapter still receives only grounded local evidence.
   *Success signal: prompt shaping does not sneak retrieval or policy concerns back into the model adapter as raw app state.*

2. Verify that rejection behavior stays deterministic.
   *Success signal: the same unsafe input yields the same refusal or reroute behavior across runs.*

3. Verify that M3P5 does not widen the assistant scope.
   *Success signal: the assistant remains bounded to approved local content and app data only.*

4. Verify the codepath stays offline-first and local-first.
   *Success signal: prompt shaping and safety enforcement do not add network dependence or remote policy checks.*

### Phase 6: Run Relevant Checks

1. Run the focused test suite for policy and assistant boundary changes.
   *Success signal: the new and existing guardrail tests pass, or the blocker is recorded precisely.*

2. Run the available app build or targeted test checks for the touched code.
   *Success signal: the implementation is verified against the local environment, or unavailable tooling is called out clearly.*

3. Confirm the M3 milestone is still closed only by local evidence and citations.
   *Success signal: the final state still satisfies grounded Ask behavior without turning into a general chatbot.*

## Guardrails

- Do not change retrieval ranking or citation packaging unless a tiny prompt input requires it.
- Do not implement online search, source import, or refresh behavior in this phase.
- Do not let blocked or sensitive prompts reach generation unchanged.
- Do not return uncited prose when the evidence is weak or the request is out of scope.
- Do not expose Foundation Models details directly to feature views.
- Do not log raw prompts or personal notes in a way that violates the app’s privacy posture.
- Do not widen the assistant into a general-purpose chatbot.

## Verification Checklist

- [ ] The current minimal prompt construction was replaced or wrapped by a dedicated prompt-shaping layer.
- [ ] Blocked prompts are refused before generation.
- [ ] Sensitive-static-only prompts are rerouted to safer reviewed content or explicit refusal behavior.
- [ ] Adversarial prompt variants are covered by regression tests.
- [ ] Prompt-shaping output includes grounding and citation instructions.
- [ ] Logging behavior for rejected prompts is bounded and privacy-aware.
- [ ] Build or test verification was run, or any blocker was reported explicitly.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| A prompt attempts to override assistant policy | Refuse or neutralize the request before generation and keep the assistant bounded to approved local content. |
| A prompt is clearly blocked by policy | Return a refusal path and do not synthesize an answer. |
| A prompt is sensitive but static-only | Reroute to reviewed static content or a constrained answer path that preserves safety. |
| The prompt-shaping layer produces uncited or overly fluent output | Tighten the template so evidence and citation instructions are explicit and mandatory. |
| Logging rejected prompts would expose sensitive user content | Redact or omit the content and preserve only the minimum local diagnostic signal needed. |
| Verification tooling is unavailable | Report the exact blocker and keep the corresponding claims unverified. |

## Out Of Scope

- Retrieval ranking changes.
- Citation packaging redesign.
- Capability detection changes.
- Online search, import, refresh, or cloud-backed policy services.
- General chat behavior or open-ended prompt experimentation.
- Seed-content expansion work that does not depend on assistant policy changes.

## Report Format

When implementation is complete, report back in this structure:

1. Files added and files changed.
2. Prompt-shaping boundary added and where it lives.
3. Policy enforcement changes and routing behavior for blocked and sensitive-static-only prompts.
4. Regression tests added and what each one proves.
5. Verification commands run and their outcomes.
6. Remaining risks, deferred work, or explicitly unverified claims.
