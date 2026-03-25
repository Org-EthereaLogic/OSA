# AI Assistant Retrieval And Guardrails

Status: Initial draft complete.  
Related docs: [PRD](./02-prd.md), [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [Security And Privacy](./10-security-privacy-and-safety.md), [ADR-0002](../adr/ADR-0002-grounded-assistant-only.md), [ADR-0003](../adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md)

## Confirmed Facts

- The assistant is not a general chatbot.
- The assistant may answer only from approved local sources and app data.
- When information is not found locally, the assistant must say so clearly.
- If the device is connected, the app may optionally offer online search and import; the assistant must not pretend unsupported information is known.

## Assumptions

- The assistant will have access to handbook content, quick cards, imported approved knowledge, notes, checklists, and inventory according to scope rules.
- Some supported devices will have Apple Foundation Models available; others will not.
- v1 can accept slightly less fluent responses in exchange for stronger grounding and lower implementation risk.

## Recommendations

- Make retrieval and policy enforcement deterministic and inspectable.
- Treat answer generation as a final formatting step over retrieved evidence, not as a source of truth.
- Prefer refusal, clarification, or quick-card redirection over speculative answers on sensitive topics.

## Open Questions

- Should user notes always be in Ask scope, or only when the user explicitly enables personal-data retrieval?
- How much answer history should be kept locally for privacy and storage reasons?
- Should the app expose a "search only" mode for unsupported devices instead of templated extractive answers?

## Assistant Scope

The assistant exists to help the user navigate and synthesize approved local content. Allowed knowledge inputs:

- handbook chapters and sections
- quick cards
- checklist templates and active checklist runs
- inventory items
- personal notes, if enabled in settings or explicit query context
- imported trusted source material already persisted locally

The assistant does not browse the live web directly and does not answer from model priors alone.

## Allowed Tasks

- answer factual questions that are covered by local approved content
- summarize sections across multiple local sources
- point the user to relevant quick cards and checklist items
- explain inventory gaps based on local inventory data and templates
- help find related notes, sections, or imported sources
- present concise, cited offline answers under stress

## Disallowed Tasks

- acting as a general-purpose chatbot
- inventing answers not supported by local evidence
- free-form tactical weapon guidance or hunting coaching
- high-risk medical diagnosis or treatment advice beyond reviewed static reference content
- edible-plant identification or foraging advice
- unsafe emergency improvisation such as unreviewed fire, chemical, or utility workarounds
- live web answers that bypass local import and persistence

## Retrieval Flow

1. Classify query intent and sensitivity.
2. Enforce scope and guardrails before retrieval.
3. Retrieve relevant local evidence from handbook, quick cards, imported knowledge, and allowed user data.
4. Score evidence for trust, freshness, urgency, and relevance.
5. If evidence is insufficient, return a grounded "not found locally" response.
6. If evidence is sufficient:
   - use Foundation Models for grounded synthesis when available
   - otherwise compose an extractive answer from snippets and headings
7. Attach local citations and confidence status.

## Answer Format

Recommended answer structure:

1. Direct answer or "not found locally" statement.
2. Short supporting bullets or steps.
3. Citations to local chapter, section, quick card, or imported source records.
4. Optional follow-up actions such as "Open Quick Card" or "Search trusted web sources" when connected.

Example response shape:

- `Answer`: short plain-language answer.
- `Why this answer`: one to three evidence-backed points.
- `Sources`: citeable local records.
- `Next action`: optional button suggestions.

## Citation Rules

- Every substantive answer must cite at least one local record.
- Citations must reference local chapter, section, quick card, or imported source records, not live URLs alone.
- If multiple sources disagree, the answer should surface the safer or more conservative guidance and note the discrepancy.
- Imported-source citations should include source title and publisher/domain in the UI.
- Answers without adequate evidence must refuse to answer rather than emit uncited prose.

## Confidence And Fallback Behavior

States:

- `grounded-high`: multiple relevant approved local sources agree.
- `grounded-medium`: one relevant approved source or moderate retrieval confidence.
- `insufficient-local-evidence`: not enough approved local material.
- `blocked-sensitive-scope`: request falls into disallowed or static-only area.

Fallback behavior:

- If insufficient local evidence: say so clearly and optionally offer online search when connected.
- If model unavailable: return extractive snippet assembly with citations or direct the user to search results.
- If request is outside scope: refuse and explain the product boundary.

## Prompt And Policy Design

System-level constraints should enforce:

- answer only from provided evidence
- never use unsupported prior knowledge
- state uncertainty plainly
- refuse disallowed categories
- prefer quick cards and static content for sensitive topics
- never claim live web access

Prompt inputs should include:

- allowed task type
- sensitivity classification
- retrieved evidence snippets with citation IDs
- answer style constraints for calm emergency UX

## Model Abstraction Layer

**Current implementation (M3P1 + M3P3):**

- `CapabilityDetector.detectAnswerMode() -> AnswerMode` — returns `.groundedGeneration`, `.extractiveOnly`, or `.searchResultsOnly` based on device capability.
- `DeviceCapabilityDetector` — real runtime detection using `#if canImport(FoundationModels)` and `SystemLanguageModel.default.availability`.
- `SensitivityClassifier.classify(query: String) -> SensitivityResult` — local heuristic classification of blocked and sensitive-static-only topics.
- `GroundedAnswerGenerator` protocol — async generation boundary for grounded synthesis from retrieved evidence.
- `FoundationModelAdapter: GroundedAnswerGenerator` — concrete Foundation Models adapter, compiled only when the SDK includes FoundationModels. Uses `LanguageModelSession` for on-device generation.
- `LocalRetrievalService` retrieves evidence, packages citations, and routes to the generation adapter on supported devices or extractive assembly on unsupported devices. Falls back to extractive automatically if generation fails.

**Current implementation (M3P5):**

- `GroundedPromptBuilder` — dedicated prompt-shaping layer producing model-ready prompts with grounding rules, citation requirements, scope limits, safety boundaries, style constraints, and override protection. Lives in `OSA/Assistant/PromptShaping/`.
- `FoundationModelAdapter` delegates all prompt construction to `GroundedPromptBuilder` instead of building prompts inline.
- `SensitivityPolicy` now detects prompt injection phrases (jailbreak, system-prompt extraction, scope overrides, safety bypass) and blocks them before retrieval or generation.
- Safety regression tests (`SafetyRegressionTests`) cover adversarial prompt variants, routing verification, deterministic refusal, and privacy-bounded refusal reasons.

This keeps UI and retrieval logic independent of the underlying model choice.

## Support Matrix For Device And Model Availability

| Device State | Retrieval | Generated Summary | UX Behavior |
| --- | --- | --- | --- |
| iOS 18+ with Foundation Models supported | Full | Yes | Normal grounded Ask with citations |
| iOS 18+ without usable model resources | Full | Limited | Extractive or templated answer with citations |
| Older OS if supported by product decision | Full | No | Search-first Ask, quick cards, and cited snippets only |
| Offline and no model availability | Full local retrieval | No or limited | Still answers from local records via extractive output |

Recommendation: do not block the entire app or Ask feature when generative capability is unavailable.

## Performance Constraints

- Ask should open immediately offline with no network dependency.
- Typical local retrieval should return candidate evidence within roughly 300 ms to 800 ms on supported devices.
- Generated or extractive answer assembly should target under 2 seconds for ordinary questions.
- Emergency quick-card redirection must be faster than full-answer generation.
- Large imported knowledge sets must not degrade first-launch or cold-start performance materially.

## Guardrails For Sensitive Areas

### High-Risk Medical Content

- Prefer static reviewed sections and quick cards.
- No diagnosis, dosage invention, or personalized treatment advice.
- Encourage seeking professional or emergency care where the reviewed content says to do so.

### Weapon And Tactical Content

- Restrict archery and longbow material to safety, maintenance, inspection, storage, inventory, lawful reference notes, range habits, and practice logs.
- Refuse tactical, hunting, combat, or harm-seeking guidance.

### Foraging And Plant Identification

- No edible-plant identification assistance.
- Redirect to the boundary and explain that the app does not provide this due to safety risk.

### Unsafe Emergency Improvisation

- Refuse or redirect when the request seeks dangerous improvisation around fire, power, gas, chemicals, or structural hazards without reviewed local guidance.

### Hallucination Prevention

- Never answer without retrieved evidence.
- Require citations for every answer.
- Use deterministic refusal when evidence quality is below threshold.
- Log blocked and uncited-answer attempts locally for evaluation during testing.

## Evaluation Criteria

- citation precision and coverage
- refusal quality on out-of-scope prompts
- hallucination rate under adversarial prompts
- usefulness and clarity under offline stress scenarios
- latency on supported and unsupported AI-capability devices
- safety compliance for medical, weapon, foraging, and unsafe improvisation prompts

## Done Means

- Assistant behavior is bounded tightly enough to prevent "general chatbot" drift.
- Retrieval, citation, refusal, and fallback paths are explicit.
- Sensitive-topic guardrails are concrete enough for implementation and regression testing.
- Device capability differences have a clear UX response instead of implicit failure.

## Next-Step Recommendations

1. ~~Convert the allowed and disallowed task lists into policy tests before coding the assistant UI.~~ **Done:** `SensitivityPolicy` implements blocked-category detection (hunting, foraging, medical dosage), sensitive-static-only classification (first aid, emergency hazards), and multi-word phrase matching for compound keywords such as `gas leak`, `power line`, and `identify plant`. `SensitivityPolicyTests` covers all branches.
2. Decide whether personal notes are in Ask scope by default or opt-in.
3. ~~Build the retrieval layer before evaluating answer-generation quality.~~ **Done:** `LocalRetrievalService` implements the full retrieval flow: normalize → classify sensitivity → search FTS5 → re-rank → check sufficiency → package citations → determine confidence → assemble extractive answer.
4. ~~Implement capability detection and generation adapter.~~ **Done (M3P3):** `DeviceCapabilityDetector` performs real runtime detection via `#if canImport(FoundationModels)` and `SystemLanguageModel.default.availability`. `GroundedAnswerGenerator` protocol defines the generation boundary. `FoundationModelAdapter` provides the concrete Foundation Models implementation. `LocalRetrievalService` routes to grounded generation on supported devices with automatic extractive fallback. `CapabilityDetectionTests` covers both paths, generation failure fallback, and citation integrity.
5. ~~Implement prompt shaping, policy enforcement, and safety regression coverage.~~ **Done (M3P5):** `GroundedPromptBuilder` replaces inline prompt construction with a dedicated shaping layer encoding grounding, citations, safety, style, and override-protection rules. `SensitivityPolicy` now detects prompt injection phrases and keywords. `SafetyRegressionTests` covers jailbreak phrasing, scope overrides, mixed-intent prompts, routing verification, deterministic refusal, and privacy-bounded refusal reasons. `GroundedPromptBuilderTests` verifies all prompt sections. `SensitivityPolicyTests` expanded with adversarial variants.
