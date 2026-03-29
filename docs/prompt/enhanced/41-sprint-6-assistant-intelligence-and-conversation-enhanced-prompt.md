Developer: # Implement Sprint 6 Assistant Intelligence And Bounded Conversation

**Date:** 2026-03-29
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** Sprint 6 extends the grounded Ask surface across retrieval contracts, prompt shaping, Ask UI state, local recent-question persistence, notes-backed study guide generation, region-aware ranking, and proactive suggestions. It should stay within existing offline-first and privacy-bounded seams, but it will likely touch 12-18 files plus focused tests.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow Sprint 6: Assistant Intelligence & Conversation` | The target slice is a richer Ask experience with follow-up questions, recent question history, study guide generation, proactive suggestions, and region-based content filtering. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Keep the app offline-first, grounded, privacy-bounded, minimally scoped, and evidence-backed. Avoid speculative abstractions and report blocked verification as `unverified`. |
| `docs/sdlc/02-prd.md` | Ask is a retrieval surface with synthesis, not a general chatbot. Any Sprint 6 conversational behavior must preserve that bounded contract. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | The product already completed Milestones 1-6 and prior UX sprints. Sprint 6 should be a bounded post-M6 Ask enhancement rather than a new architecture track. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Ask already has a local-only scope card, a clear zero state, and a single-question answer flow. Home already has a contextual suggestions section keyed off region, hazards, and season. |
| `docs/sdlc/05-technical-architecture.md` | The architecture already separates `Features`, `Domain`, `Retrieval`, `Assistant`, `Persistence`, and `Shared`. `EvidenceRanker` is the right deterministic seam for ranking changes; `HomeScreen` already owns contextual suggestion loading. |
| `docs/sdlc/06-data-model-local-storage.md` | Conversation history is not currently persisted. Notes, tags, linked handbook sections, and linked inventory items already exist, which makes notes a viable storage target for study guides without adding a new persistence type. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | The assistant may answer only from approved local evidence, must refuse uncited or unsafe answers, and should prefer clarification or redirection over speculative chat behavior. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Ask prompts and history must stay local by default. Do not transmit note bodies, inventory contents, or Ask conversation history to remote services. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Retrieval, citation, refusal, offline behavior, and assistant-related UI wiring require focused unit tests and explicit build or test evidence. |
| `docs/reference/2026-03-28-feature-adoption-recommendations.md` | The repository already recommends session follow-up context, recent questions, study guides, and more contextual suggestions. These ideas should be adopted in a bounded way that respects OSA's current product contract. |
| `OSA/Features/Ask/AskScreen.swift` | Ask is currently single-turn, keeps only the current query or result in view state, and has no recent-question UI or study-guide action. |
| `OSA/Domain/Ask/Repositories/AskRepositories.swift` and `OSA/Domain/Ask/Models/RetrievalModels.swift` | The retrieval contract currently accepts only `query` and `scopes`; there is no retrieval-context model for follow-up context or user-profile preference tags. |
| `OSA/Retrieval/Querying/LocalRetrievalService.swift` | Retrieval is deterministic: normalize, classify, search, rank, cite, assemble. Sprint 6 should extend this path rather than create a second conversation service. |
| `OSA/Retrieval/Ranking/EvidenceRanker.swift` | There is already one deterministic re-ranking seam. Region-aware preference boosting belongs here, not in a parallel filter system. |
| `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift` and `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift` | Generative output already depends on prompt shaping fed by retrieved evidence. If follow-up context is introduced, it must be routed through these existing grounding seams. |
| `OSA/Domain/Notes/Models/NoteRecord.swift` and `OSA/Domain/Notes/Repositories/NoteRepositories.swift` | Notes already support `NoteType.localReference`, tags, and linked section IDs, which is enough to persist study guides without a new `NoteType`. |
| `OSA/Domain/Settings/UserProfileSettings.swift` and `OSA/Domain/Settings/PinnedContentSettings.swift` | Region preference already exists and there is an established `@AppStorage` helper pattern for bounded local history lists. |
| `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Home/HomeSectionViews.swift` | Home already surfaces contextual suggestions and recent notes; Sprint 6 should extend the current suggestion logic rather than inventing a new dashboard subsystem. |
| `docs/prompt/enhanced/36-m6p4-assistant-schema-onscreen-content-and-navigation-intents-enhanced-prompt.md` and `docs/prompt/enhanced/40-sprint-5-notifications-export-sharing-enhanced-prompt.md` | Recent prompt artifacts are phase-scoped, file-specific, and explicit about guardrails, tests, and out-of-scope work. Sprint 6 should follow the same pattern. |

## Classification Summary

- Core intent: evolve Ask from a single-turn Q and A surface into a bounded conversational assistant that supports session follow-ups, local recent-question history, notes-backed study guides, context-aware suggestions, and region-aware retrieval preferences without becoming a general chatbot.
- In scope: bounded retrieval-context modeling, Ask UI state and recent-history UI, notes-backed study guide creation, deterministic region-aware ranking, extension of existing Home suggestions, focused tests, and evidence-backed verification.
- Out of scope: open-ended multi-session chat logs, remote AI APIs, voice chat, synced conversation history, embeddings, full recommendation engines, weather-driven automation beyond existing local or already-available services, and any widening of sensitive-scope policy.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- Sprint 6 conversation support is session-bounded. It may use the immediately previous grounded answer as local context, but it must not introduce a generic chat transcript or model-prior memory.
- Recent question history should persist only recent question text locally, not full answer bodies or long-lived conversation transcripts.
- Study guides should be saved as `NoteRecord` entries using `NoteType.localReference` plus a stable `study-guide` tag rather than a new note type or SwiftData entity.
- Region-aware behavior should prefer matching `region:` tags and keep untagged universal content eligible, rather than hiding broadly applicable safety content.
- Siri and App Intent entry points should remain single-turn. They may reuse profile-based preference tags, but they must not gain access to recent Ask history or follow-up state from `AskScreen`.
- If build or test verification is blocked because full Xcode is unavailable, affected claims must be reported as `unverified` with the exact command and failure mode.

## Mission Statement

Implement Sprint 6 as a bounded Ask enhancement that adds session-scoped follow-up context, local recent-question history, notes-backed study guide generation, context-aware suggestions, and region-aware retrieval preferences while preserving OSA's grounded, offline-first, and non-chatbot assistant contract.

## Technical Context

Ask already has a strong foundation: `AskScreen` is wired to `RetrievalService`, `LocalRetrievalService` already performs deterministic local retrieval with citations, `GroundedPromptBuilder` already shapes grounded generation prompts, and `EvidenceRanker` already centralizes heuristic ranking. The right Sprint 6 implementation is therefore not a new assistant subsystem. It is a thin extension of the current retrieval path so follow-up context and region preferences can influence retrieval and prompt shaping without bypassing evidence requirements.

The current product contract creates an important design constraint. `docs/sdlc/02-prd.md` says Ask is a retrieval surface with synthesis, not a conversational platform. `ADR-0002` says the assistant is not a general chatbot. That means Sprint 6 cannot introduce open-ended memory or free-form conversation state. Instead, it should add a bounded retrieval context made of two pieces:

1. session-only follow-up context from the immediately previous grounded answer
2. deterministic user-profile preference tags, starting with the selected `PreparednessRegion`

This lets short follow-up questions like `What about boiling?` remain grounded in fresh retrieval results rather than prior model output alone.

Recent question history should also stay small and local. The repository already uses `RecentLibraryHistorySettings` for bounded recent items. Reusing that pattern for Ask questions avoids over-engineering and keeps history easy to reason about, test, and clear. Store only recent question strings. Do not store long-lived answer transcripts or multi-turn message objects in this sprint.

Study guides should similarly reuse existing structures. `NoteRecord` already supports local reference notes, tags, and linked section IDs. A `StudyGuideBuilder` can assemble note markdown from an `AnswerResult` and its citations, then save the output as a tagged local reference note. This keeps study guides local, citeable, searchable, and editable without adding a second persistence model.

Proactive suggestions should build on what already exists. `HomeScreen.loadContextualSuggestions()` already scores suggestions from hazards, region, and season. Sprint 6 should extend that logic with recent Ask topics and saved study-guide topics rather than inventing a new recommendation engine. Keep suggestions deterministic, local-only, and modest in scope.

The preferred implementation shape is:

- one retrieval-context model in `OSA/Domain/Ask/Models/`
- one bounded recent-question settings helper in `OSA/Domain/Settings/`
- one extension of the existing retrieval, ranking, and prompt-shaping path
- one small study-guide builder in `OSA/Assistant/Orchestration/`
- one Ask UI update that records history, presents recent questions, supports follow-up context, and saves study guides
- one extension of the existing Home suggestions logic

Do not introduce a generic message model, a conversation database, or a second retrieval pipeline.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Ask interaction model | `AskScreen` supports one submitted question at a time and forgets prior answer context after the next search. | Ask can answer bounded follow-up questions within the current session by reusing the immediately previous grounded answer as retrieval context. |
| Retrieval contract | `RetrievalService.retrieve(query:scopes:)` has no way to receive session context or user-profile preference tags. | Retrieval accepts one optional bounded context object for follow-up disambiguation and preference tags while still performing fresh local retrieval. |
| Region awareness | Region exists in `UserProfileSettings`, but Ask retrieval does not currently use it. | Region tags influence ranking and study-guide assembly in a deterministic, inspectable way without hiding untagged universal content. |
| Recent question history | There is no Ask-specific recent question history or tap-to-rerun UI. | Ask shows a bounded, local-only recent-question list and lets users rerun or resume recent topics quickly. |
| Study guide generation | Answers are visible only in the Ask screen and cannot be saved as a structured local briefing. | Users can save a grounded study guide as a local reference note built from citations and linked section IDs. |
| Contextual suggestions | Home suggestions already consider hazards, region, and season, but not Ask activity or study-guide topics. | Home suggestions can include recent Ask topics and saved study-guide topics using the current local suggestion section. |
| Privacy boundary | Ask has no persisted history today, so there is no explicit storage boundary for recent questions. | Recent questions stay on device, store question text only, and are never shared to Siri, remote services, or system surfaces. |
| Verification | Existing tests cover retrieval, prompt shaping, safety, and Ask execution, but not follow-up context, recent-question history, or study-guide generation. | Focused tests verify follow-up retrieval, recent-question storage, study-guide rendering, region-aware ranking, and visible Ask UI wiring. |

## Pre-Flight Checks

1. Verify the current Ask seams and helper patterns before implementation.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
test -f OSA/Features/Ask/AskScreen.swift \
  && test -f OSA/Domain/Ask/Repositories/AskRepositories.swift \
  && test -f OSA/Domain/Ask/Models/RetrievalModels.swift \
  && test -f OSA/Retrieval/Querying/LocalRetrievalService.swift \
  && test -f OSA/Retrieval/Ranking/EvidenceRanker.swift \
  && test -f OSA/Domain/Settings/PinnedContentSettings.swift \
  && test -f OSA/Domain/Settings/UserProfileSettings.swift \
  && test -f OSA/Domain/Notes/Models/NoteRecord.swift \
  && echo "sprint-6 seams present"
# Expected: sprint-6 seams present
```

*Success signal: the current Ask, ranking, settings, and notes seams are present before editing starts.*

1. Confirm the current Ask path is still single-turn and context-free.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
rg -n "func retrieve\(query: String, scopes: Set<RetrievalScope>\?\)" OSA/Domain/Ask/Repositories/AskRepositories.swift OSA/Retrieval/Querying/LocalRetrievalService.swift
rg -n "@State private var askState|@State private var lastSubmittedQuery" OSA/Features/Ask/AskScreen.swift
# Expected: one retrieval signature without context and AskScreen state limited to current query or result submission
```

*Success signal: the current implementation clearly shows why bounded retrieval context is needed rather than assumed.*

1. Confirm the existing region and recent-history patterns to reuse.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
rg -n "PreparednessRegion|region:" OSA/Domain/Settings/UserProfileSettings.swift OSA/Features/Home/HomeScreen.swift OSA/Resources/SeedContent
rg -n "RecentLibraryHistorySettings|SettingsValueCoding.encode\(" OSA/Domain/Settings/PinnedContentSettings.swift OSA/Domain/Settings/UserProfileSettings.swift
# Expected: existing region tags and an established bounded-history helper pattern
```

*Success signal: Sprint 6 can reuse current region tags and local-settings encoding patterns instead of inventing new storage mechanisms.*

1. Identify the nearest verification anchors before editing.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
test -f OSATests/LocalRetrievalServiceTests.swift \
  && test -f OSATests/GroundedPromptBuilderTests.swift \
  && test -f OSATests/AskLanternIntentExecutorTests.swift \
  && test -f OSAUITests/OSAContentAndInputTests.swift \
  && echo "sprint-6 test anchors present"
# Expected: sprint-6 test anchors present
```

*Success signal: the sprint has focused unit and UI test anchors before implementation begins.*

## Phased Instructions

### Phase 1: Investigation And Shape Decisions

1. **Read the current Ask, retrieval, ranking, notes, and Home suggestion seams in full before editing.**

   Inspect these files before implementation:
   `OSA/Features/Ask/AskScreen.swift`
   `OSA/Domain/Ask/Repositories/AskRepositories.swift`
   `OSA/Domain/Ask/Models/RetrievalModels.swift`
   `OSA/Retrieval/Querying/LocalRetrievalService.swift`
   `OSA/Retrieval/Ranking/EvidenceRanker.swift`
   `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift`
   `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`
   `OSA/Assistant/Orchestration/AskLanternIntentExecutor.swift`
   `OSA/Domain/Notes/Models/NoteRecord.swift`
   `OSA/Domain/Notes/Repositories/NoteRepositories.swift`
   `OSA/Domain/Settings/UserProfileSettings.swift`
   `OSA/Domain/Settings/PinnedContentSettings.swift`
   `OSA/Features/Home/HomeScreen.swift`

   *Success signal: the implementation plan reuses existing retrieval, ranking, settings, note, and Home seams instead of creating parallel systems.*

2. **Lock the bounded storage and context strategy before coding.**

   Adopt these decisions up front:
   - session follow-up context is ephemeral and derived from the immediately previous grounded answer
   - recent-question history stores only recent question strings locally
   - study guides persist as `NoteType.localReference` notes with a `study-guide` tag
   - region-aware behavior starts with `PreparednessRegion.tag` and does not introduce hazard-weighting unless it remains small and deterministic

   *Success signal: the sprint has one clear data-shape decision for context, history, and study-guide persistence before implementation starts.*

### Phase 2: Retrieval Context And Region Preferences

1. **Add one bounded retrieval-context model in `OSA/Domain/Ask/Models/`.**

   Create `OSA/Domain/Ask/Models/ConversationModels.swift` with a minimal `RetrievalContext` model. It should contain:
   - optional follow-up context derived from the previous grounded answer, for example previous query text, previous answer summary, and previous citation labels or IDs
   - `preferredTags: Set<String>` for deterministic profile-driven ranking hints such as the current region tag

   Keep the model small and serializable if needed, but do not create a general message transcript type.

   *Success signal: Ask and retrieval can pass one optional bounded context object without introducing chat-session persistence.*

2. **Extend the current retrieval and generation contracts to accept the new bounded context.**

   Update:
   `OSA/Domain/Ask/Repositories/AskRepositories.swift`
   `OSA/Retrieval/Querying/LocalRetrievalService.swift`
   `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`
   `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift`

   Thread `RetrievalContext?` through the existing call graph. `AskLanternIntentExecutor` may pass a context that contains preference tags only, with no follow-up memory.

   **Rationale:** the root change is the retrieval contract, not a UI-only string rewrite. The model adapter and prompt builder must also understand bounded context so generative and extractive paths stay aligned.

   *Success signal: one grounded retrieval path supports follow-up context and preference tags end to end without creating a second assistant pipeline.*

3. **Use the bounded context only to disambiguate retrieval, never to bypass fresh evidence retrieval.**

   In `OSA/Retrieval/Querying/LocalRetrievalService.swift`:
   - continue to normalize and classify the new user query
   - when the new query is short or context-dependent, enrich only the search formulation using the previous query or citation labels from `RetrievalContext`
   - still require a fresh local search, fresh ranking, and fresh citations for the current answer
   - if the new query still lacks evidence, return `.insufficientEvidence` rather than paraphrasing the prior answer from memory

   *Success signal: follow-up questions remain grounded in newly retrieved evidence, and unsupported follow-ups still refuse correctly.*

4. **Add deterministic region-aware preference boosting to the existing ranker instead of creating a second filter path.**

   Update `OSA/Retrieval/Ranking/EvidenceRanker.swift` so it can receive `preferredTags` from `RetrievalContext`.

   The boosting rules should:
   - increase the score of items whose tags contain the selected `region:` tag
   - leave untagged items eligible
   - avoid hard-filtering out universal quick cards or handbook sections unless the user explicitly selected a region-only control in the UI

   Keep the rules inspectable and deterministic.

   *Success signal: region-relevant content ranks higher when available, but broad safety content remains reachable.*

### Phase 3: Ask UI, Recent Questions, And Study Guides

1. **Add a bounded recent-question settings helper under `OSA/Domain/Settings/`.**

   Create `OSA/Domain/Settings/RecentAskHistorySettings.swift` following the `RecentLibraryHistorySettings` pattern.

   Store only recent question strings, capped to a small list such as 8 unique entries. Provide helpers for encode, decode, record, and clear or prune behavior.

   *Success signal: Ask history has one small local storage helper and does not require a new persistence entity.*

2. **Update `OSA/Features/Ask/AskScreen.swift` to record recent questions and maintain bounded session follow-up state.**

   Add state for:
   - the most recent grounded answer context used for follow-ups
   - recent question history loaded through `RecentAskHistorySettings`
   - the current region tag derived from `UserProfileSettings.regionKey`

   On each successful submit:
   - record the submitted question in recent history
   - build the next follow-up context from the answered result only
   - pass `RetrievalContext` into `retrievalService.retrieve(...)`

   *Success signal: Ask can reuse the immediately previous grounded answer as context and retains a bounded recent-question list locally.*

3. **Expose recent questions as an explicit Ask UI affordance without making the screen look like a chat transcript.**

   In `OSA/Features/Ask/AskScreen.swift`:
   - render a `Recent Questions` section when there are recent entries
   - let taps on a recent question rerun that question directly
   - keep the current answer-card layout and local-only scope card intact
   - add copy that clarifies session context is used only to refine local retrieval, not to store a full chat memory

   Do not add alternating message bubbles, avatars, or a general-chat transcript UI.

   *Success signal: Ask feels more conversational in a bounded way while still reading like a grounded reference tool rather than a chatbot.*

4. **Add study-guide generation as a notes-backed output, not a new content type.**

   Create `OSA/Assistant/Orchestration/StudyGuideBuilder.swift`.

   The builder should accept the current `AnswerResult`, selected preference tags, and any supporting metadata needed to produce markdown that includes:
   - title based on the Ask topic
   - short overview grounded in the current answer
   - evidence-backed sections or bullets derived from cited sources
   - a `Sources` section listing citation labels
   - optional region label when a region preference influenced the result

   Save the guide through `NoteRepository.createNote(_:)` as a `NoteType.localReference` note with at least the `study-guide` tag. Link handbook sections referenced in citations via `linkedSectionIDs`. Do not add a new `NoteType` or separate study-guide store.

   *Success signal: users can save a grounded study guide as a local note that remains searchable and editable with current note infrastructure.*

5. **Add a bounded study-guide action to the Ask answer surface.**

   Update `OSA/Features/Ask/AskScreen.swift` and any small supporting views in the same file so that, after a successful answer, the user can trigger `Save Study Guide`.

   Keep the action explicit and local-only. A study guide should only be generated from an answered result that already has citations.

   *Success signal: the Ask screen offers a clear study-guide action only when grounded evidence exists.*

### Phase 4: Contextual Suggestions And Home Integration

1. **Extend the existing Home suggestions logic instead of inventing a new recommendation subsystem.**

   Update `OSA/Features/Home/HomeScreen.swift` directly, or extract only a small feature-local helper if testability requires it.

   Reuse the current `HomeSuggestionsSectionView` and blend these local signals:
   - existing hazard, region, and season matches
   - recent Ask question topics from `RecentAskHistorySettings`
   - saved study-guide notes tagged `study-guide`

   Keep the scoring deterministic and modest. Do not add background analytics, remote telemetry, or opaque recommendation logic.

   *Success signal: Home suggestions become more context-aware using only existing local profile and Ask activity signals.*

2. **Use the same region preference in Ask and Home so the app's behavior stays coherent.**

   Derive the region tag from `UserProfileSettings.regionKey` in both places. If region-aware ranking is applied in Ask, Home suggestions and study-guide metadata should use the same source of truth.

   *Success signal: Ask, Home suggestions, and saved study guides reflect one consistent region preference model.*

3. **Keep proactive suggestions bounded and user-comprehensible.**

   Every suggested item should remain explainable through existing `HomeSuggestion.reason` text such as region, season, or recent-topic phrasing. Do not add hidden personalization logic that the user cannot interpret.

   *Success signal: the user can understand why the app suggested the content without reading opaque ranking internals.*

### Phase 5: Verification And Quality

1. **Add focused tests for bounded retrieval context and region-aware ranking.**

   Extend `OSATests/LocalRetrievalServiceTests.swift` to cover at minimum:
   - a short follow-up query that resolves correctly when prior context is supplied
   - the same short query refusing or ranking differently when no context is supplied
   - preferred region tags boosting matching content ahead of otherwise similar results
   - nil context preserving current behavior for ordinary one-shot questions

   *Success signal: retrieval context and region-aware ranking are covered by focused deterministic tests.*

2. **Add focused tests for recent-question storage and study-guide generation.**

   Create:
   - `OSATests/RecentAskHistorySettingsTests.swift`
   - `OSATests/StudyGuideBuilderTests.swift`

   Verify bounded deduplication, ordering, encode and decode behavior, and markdown output that includes title, answer content, citations, and linked section IDs.

   *Success signal: the new storage helper and study-guide builder are both deterministic and independently testable.*

3. **Extend prompt-shaping and Siri-facing tests only where they directly exercise new context behavior.**

   Update:
   - `OSATests/GroundedPromptBuilderTests.swift` to verify bounded follow-up context is included in the prompt when present and omitted when absent
   - `OSATests/AskLanternIntentExecutorTests.swift` to verify the Siri path remains single-turn and does not receive session follow-up history

   *Success signal: generative prompting and App Intent entry points remain aligned with the new bounded-context rules.*

4. **Add visible UI coverage for recent questions and study-guide actions.**

   Extend `OSAUITests/OSAContentAndInputTests.swift` to cover at minimum:
   - recent-question UI visibility on Ask after at least one successful question
   - tapping a recent question to rerun it
   - the presence of the `Save Study Guide` action after an answered query

   Keep this UI coverage narrow. Do not expand into a broad chat transcript test suite.

   *Success signal: the new Ask affordances are visible and reachable through UI automation.*

5. **Run a focused simulator test pass for Sprint 6 behavior.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/LocalRetrievalServiceTests \
  -only-testing:OSATests/GroundedPromptBuilderTests \
  -only-testing:OSATests/AskLanternIntentExecutorTests \
  -only-testing:OSATests/RecentAskHistorySettingsTests \
  -only-testing:OSATests/StudyGuideBuilderTests \
  -only-testing:OSAUITests/OSAContentAndInputTests
# Expected: test action completes successfully, or the exact Xcode or simulator blocker is captured verbatim
```

   *Success signal: focused Sprint 6 unit and UI coverage passes or the exact environment blocker is documented.*

1. **Run a simulator build for the application target.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED
```

   *Success signal: the app target builds cleanly with retrieval-context, Ask UI, study-guide, and Home suggestion changes.*

### Phase 6: Security And Manual Validation

1. **Run the first-party security scan required for new code.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
snyk code test --path="$PWD"
# Expected: Snyk Code completes successfully, or the exact blocker is reported
```

   *Success signal: security scanning was run or reported explicitly as blocked.*

1. **Perform bounded manual validation for the new Ask flow if the environment allows it.**

   Validate these manually if a runnable simulator build is available:
   - ask a first question with grounded citations
   - ask a short follow-up such as `What about boiling?` and confirm the answer still cites fresh local evidence
   - tap a recent question and confirm it reruns
   - save a study guide and confirm it appears in Notes as a local reference note
   - change the selected region in Settings and confirm region-tagged content becomes more prominent in Ask or Home suggestions when appropriate

   *Success signal: the new Ask and Home behaviors are observable in the running app without drifting into transcript-style chat UX.*

## Guardrails

- Do not turn Ask into a general chatbot, transcript interface, or open-ended message history surface.
- Do not add remote AI APIs, remote prompt storage, cloud sync, or any outbound transmission of Ask history.
- Do not add a new SwiftData entity or a new `NoteType` for study guides in this sprint.
- Do not answer follow-up questions from prior model output alone; every answer still requires fresh local retrieval and citations.
- Do not hard-filter out untagged universal safety content when applying region preferences.
- Do not expose recent Ask history to Siri, Spotlight, widgets, or any system surface.
- Do not widen blocked or sensitive topic behavior. Existing refusal and safety policy must remain intact.
- Do not add embeddings, semantic-memory systems, recommendation infrastructure, or analytics pipelines.
- Keep Home suggestion changes inside the current local-only, explainable suggestion model.

## Verification Checklist

- [ ] Ask supports bounded follow-up questions using fresh local retrieval rather than transcript replay.
- [ ] `RetrievalService` and the grounded generation path accept one optional bounded context model.
- [ ] Region-aware preference tags influence ranking deterministically and keep untagged universal content eligible.
- [ ] Recent Ask history is stored locally as recent question strings only.
- [ ] Ask exposes a recent-question UI that reruns prior questions without introducing chat bubbles.
- [ ] Study guides can be saved as `NoteType.localReference` notes with a `study-guide` tag.
- [ ] Saved study guides preserve citation labels and linked handbook section IDs where available.
- [ ] Home suggestions reuse existing local suggestion surfaces and become more context-aware without a new recommendation engine.
- [ ] Siri or App Intent paths remain single-turn and do not gain session-memory behavior.
- [ ] Focused build, test, and security commands were run, or blockers were reported explicitly.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Follow-up context causes unrelated new questions to rank poorly | Apply the previous-answer context only as a bounded disambiguation hint for short or context-dependent queries. Preserve nil-context behavior for ordinary standalone questions. |
| Region preferences hide broadly applicable content | Treat region as a ranking boost, not a mandatory filter, unless the user explicitly selected a region-only control in the UI. |
| Recent-question persistence starts to require timestamps or large metadata | Keep the first pass as a simple bounded list of unique question strings stored through `@AppStorage` helpers. |
| Study-guide saving starts to demand a new schema | Stop at `NoteType.localReference` plus the `study-guide` tag and linked section IDs. Defer richer guide metadata to a separate prompt. |
| Siri or App Intent execution starts inheriting screen-session follow-up history | Keep App Intent execution single-turn. Pass only preference tags if needed and explicitly omit Ask-screen session context. |
| UI begins to resemble a transcript chat app | Remove transcript affordances and keep the layout centered on the current answer plus recent-question shortcuts. |
| Focused tests fail because the retrieval-signature change ripples too broadly | Repair the shared contract and all direct call sites first, then rerun the same focused tests before widening scope. |
| Full Xcode or simulator services are unavailable | Report the exact failing command and environment blocker, and mark build or test verification as `unverified`. |

## Out Of Scope

- Multi-session conversation logs or durable message transcripts
- Cloud backup or sync of Ask questions, answers, or study guides
- Voice conversations, streaming responses, or speech interfaces
- Embedding-based semantic memory or recommendation systems
- Weather-triggered background suggestions or notification automation beyond already-implemented local features
- New note schemas, imported-knowledge readers, or Ask redesigns unrelated to Sprint 6 goals
- Any broadening of medical, tactical, foraging, or hazardous improvisation content boundaries

## Alternative Solutions

1. **If widening the retrieval contract causes too much churn:** keep the primary data model change, but as a fallback rewrite short follow-up queries inside `AskScreen` before calling `RetrievalService`. Use this only if the broader contract change proves unreasonably disruptive, and document the compromise clearly.
2. **If study-guide persistence proves too wide in the first pass:** ship `StudyGuideBuilder` and a preview or share action first, then add note persistence in a narrowly scoped follow-up prompt. Do not create a new persistence model just to save Sprint 6.
3. **If Home suggestion changes become noisy:** keep proactive suggestion work scoped to Ask recent-question shortcuts plus region-aware ranking, and defer broader Home suggestion expansion to a dedicated UX prompt.

## Report Format

1. **Scope completed:** which Sprint 6 capabilities were implemented versus explicitly deferred.
2. **Files changed:** grouped by domain models, retrieval and ranking, assistant orchestration and prompt shaping, Ask UI, Home suggestions, and tests.
3. **Conversation behavior:** how follow-up context is bounded, how recent questions are stored, and what the assistant still refuses to do.
4. **Study guide behavior:** how guides are generated, tagged, linked, and stored locally.
5. **Region-aware behavior:** where preference tags are applied and how universal content remains eligible.
6. **Verification evidence:** exact build, test, and security commands run with pass, fail, or `unverified` status.
7. **Blockers or follow-up:** concrete remaining constraints, separated from implemented facts.
