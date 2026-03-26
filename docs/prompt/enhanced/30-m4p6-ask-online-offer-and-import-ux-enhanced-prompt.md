# M4P6 Enhanced Prompt: Ask Online Offer And Trusted Source Import UX

**Date:** 2026-03-26
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** This slice bridges the completed M4 backend into the first user-visible import workflow. It spans Ask UI state, connectivity-aware UX, SwiftUI dependency wiring, a new trusted-source import surface, preview/import progress handling, and focused tests across feature and integration seams. It must preserve offline-first behavior, user-visible networking, and the grounded-local-only assistant boundary while avoiding speculative search infrastructure.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt and board state | 25 of 27 tasks are done. The remaining critical-path item is M4P6: Ask online search offer and import UX. Branding polish is valuable but non-blocking. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Follow `Plan -> Act -> Verify -> Report`, keep the app offline-first and local-first, do not claim live-web answers, and keep all verification claims evidence-based. |
| `docs/sdlc/02-prd.md` | Ask must clearly state when local evidence is insufficient and may optionally offer trusted online search/import when connected. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M4P1 through M4P5 are complete. M4P6 is the final Milestone 4 gate before hardening and launch. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | When Ask lacks local evidence and the device is online, the UX should offer a trusted-source path without blocking local functionality. |
| `docs/sdlc/05-technical-architecture.md` | Reuse `OSA/Features/Ask/`, `OSA/App/Bootstrap/Dependencies/`, and the existing networking/import pipeline layers. Do not invent a second networking or import stack. |
| `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` | Online import must be user-initiated, resumable, visibly staged, and only assistant-usable after local normalization, attribution, commit, and indexing complete. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Retrieval remains local-only. The assistant must not answer from live web pages or model priors. Online behavior is an explicit fallback offer after insufficient local evidence. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Use HTTPS only, allowlist-only hosts, no hidden networking, and no transmission of notes, inventory, or prior Ask history. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Must test online/offline transitions, import interruption/error states, and the post-import path where new content becomes searchable and citeable offline. |
| `docs/prompt/enhanced/27-m4p3-trusted-source-allowlist-and-http-client-enhanced-prompt.md` | M4P3 already solved trusted host enforcement and fetch guards. M4P6 must reuse that client. |
| `docs/prompt/enhanced/28-m4p4-import-pipeline-normalization-chunking-local-commit-and-index-extension-enhanced-prompt.md` | M4P4 already solved normalization, chunking, local commit, and indexing. M4P6 must trigger that pipeline, not duplicate it. |
| `docs/prompt/enhanced/28-m4p5-refresh-and-retry-coordination-enhanced-prompt.md` | M4P5 already solved background stale-source refresh. M4P6 should focus on explicit user-triggered Ask fallback UX. |
| `OSA/Features/Ask/AskScreen.swift` | `searchOnline` is represented in the UI model, but the Ask screen currently returns `nil` for that path and shows no connectivity-aware online fallback on insufficient local evidence. |
| `OSA/Domain/Ask/Models/RetrievalModels.swift` | `SuggestedAction.searchOnline(query:)` exists, but retrieval outcomes remain local-only and should stay that way. |
| `OSA/Retrieval/Querying/LocalRetrievalService.swift` | Imported knowledge is already part of default retrieval scopes and can contribute citations and confidence after local indexing. |
| `OSA/Features/Library/SearchResultsView.swift` | Imported knowledge already appears in Library search as `Imported Sources`, so M4P6 does not need a new Library management surface to prove end-to-end success. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, `OSA/App/Bootstrap/OSAApp.swift`, `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift` | The app already constructs `trustedSourceHTTPClient`, `importPipeline`, and `refreshCoordinator`, but SwiftUI environment wiring exposes only repositories, retrieval, search, capability, and connectivity. The Ask feature cannot currently trigger fetch/import directly. |
| `OSA/Networking/Clients/TrustedSourceAllowlist.swift` | The allowlist is a static, searchable set of trusted publishers with trust tiers and default review status. It is suitable as the local browse/search source list for a bounded M4P6 UI. |
| `OSA/Shared/Support/Connectivity/ConnectivityState.swift`, `OSA/Domain/Networking/Repositories/ConnectivityRepositories.swift`, `OSA/Shared/Components/ConnectivityBadge.swift` | The repo already has a reactive connectivity model and UI badge that M4P6 should reuse instead of inventing a new network-status mechanism. |

## Mission Statement

Implement M4P6 by adding a connectivity-aware Ask fallback that, after insufficient local evidence, lets the user browse approved trusted publishers, validate or enter an allowlisted HTTPS source URL, preview the fetched content, import it through the existing local commit pipeline, show staged progress and failure states, and then re-run the original Ask query so the new source becomes visible through local search and grounded citations.

<technical_context>

## Technical Context

The backend work for Milestone 4 is already in place. The app can monitor connectivity, fetch from allowlisted hosts, normalize and chunk imported knowledge, commit it to local persistence, index approved content into FTS5, and refresh stale approved sources in the background. The gap is purely user-facing: there is no way from Ask to move from “not found locally” into an explicit, controlled import flow.

The current codebase shows three important facts:

1. `AskScreen` is already prepared for a `searchOnline` concept, but the path is unfinished.
2. `LocalRetrievalService` already includes `.importedKnowledge` in default scopes and returns imported-source citations after local indexing.
3. `SearchResultsView` already displays imported knowledge under `Imported Sources`, which means end-to-end proof can stay narrow: import from Ask, then verify Ask and Library search both see the committed local content.

The implementation approach for this prompt is intentionally bounded:

- Keep retrieval local-only. Do **not** modify `LocalRetrievalService` so it fetches remote content or depends on connectivity.
- Put the online offer in the Ask UI layer after `.insufficientEvidence` and only when connectivity is `.onlineUsable`.
- Reuse `TrustedSourceAllowlist.allSources` as the browse/search dataset for publishers.
- Reuse `TrustedSourceHTTPClient` for fetch and `ImportedKnowledgeImportPipeline` for commit.
- Reuse the existing connectivity stream and badge treatment for state cues.

Because the repository does **not** contain a remote search provider, crawler, or third-party search API integration, M4P6 must **not** invent one. For this slice, “trusted-source browse/search UI” means:

- local filtering over the allowlist by publisher name, domain, and notes
- explicit user selection of an approved publisher
- manual entry or paste of a concrete HTTPS page URL constrained to allowlisted hosts

This is the smallest coherent implementation that matches current architecture and still creates real user value: Ask can now transition from insufficient local evidence into a visible, safe import flow that ends with durable offline availability.

Scope decision for launch-critical simplicity:

- Restrict the Ask-driven import flow to allowlist entries whose `defaultReviewStatus == .approved`.
- Do **not** build a Tier 3 review workflow in this slice.
- Do **not** create a new Library or Settings management screen for imported sources unless a tiny follow-on view is strictly required to support the Ask flow.

**Rationale:** This resolves the real product blocker without widening into general web search, editorial review tooling, or source-library management. It keeps M4P6 proportional and verifiable.

</technical_context>

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Ask insufficient-evidence UX | Ask stops at `Not Found Locally` with no trusted online continuation path. | When online, Ask presents an explicit trusted-source import offer after insufficient local evidence. |
| `searchOnline` path | `SuggestedAction.searchOnline` exists, but `AskScreen` returns `nil` and no route is implemented. | Ask owns a real route or sheet for the online fallback flow. |
| SwiftUI dependency access | `trustedSourceHTTPClient` and `importPipeline` are constructed in `AppDependencies` but not exposed to feature views. | The Ask feature can access the existing HTTP client and import pipeline through the same environment-driven dependency pattern used elsewhere. |
| Trusted source discovery | The allowlist exists only as a backend lookup. There is no user-facing browse/search UI. | Ask provides a local browse/filter view over approved allowlist entries with clear publisher and trust cues. |
| Import target selection | There is no user-visible way to specify a trusted page URL for import. | The user can paste or enter an HTTPS URL, which is validated against the allowlist before any network call. |
| Preview and progress | There is no preview, staged progress, or explicit import-status feedback. | The user sees preview metadata and staged states such as fetching, previewing, importing, and completion or failure. |
| Post-import behavior | Imported knowledge can be indexed, but there is no Ask-driven path to prove it. | After successful import, Ask re-runs the original query and can cite the newly imported local source. Library search can also show the new `Imported Sources` result. |
| Scope safety | A naive implementation could drift into live-web answers or arbitrary-domain import. | All networking stays user-initiated, allowlist-only, preview-first, and local-commit-first. |

<pre_flight_checks>

## Pre-Flight Checks

1. Confirm the current Ask gap and the unfinished `searchOnline` seam.

```bash
rg -n "searchOnline|insufficientEvidence|AskViewState|destination\(for action" OSA/Features/Ask OSA/Domain/Ask
```

*Success signal: you can point to the exact Ask code path where the fallback UX is missing today.*

1. Confirm imported knowledge is already searchable and retrieval-ready after local indexing.

```bash
rg -n "importedKnowledge|indexImportedChunk|Imported Sources" OSA/Retrieval OSA/Features/Library OSA/Domain/Common
```

*Success signal: you can prove M4P6 should trigger existing search/retrieval layers, not replace them.*

1. Confirm the environment-wiring gap for the HTTP client and import pipeline.

```bash
rg -n "trustedSourceHTTPClient|importPipeline|EnvironmentValues|EnvironmentKey" OSA/App/Bootstrap/Dependencies OSA/App/Bootstrap
```

*Success signal: you can name the exact environment file and `OSAApp` injection points that must change.*

1. Confirm the allowlist is the only approved source catalog in the repo.

```bash
rg -n "TrustedSourceAllowlist|allSources|defaultReviewStatus|canonicalHost" OSA/Networking/Clients
```

*Success signal: you can rely on `TrustedSourceAllowlist.allSources` for the browse/filter UI without inventing another data source.*

1. Confirm full-Xcode verification availability before editing.

```bash
xcode-select -p
# Expected: a path under /Applications/Xcode.app/... and not /Library/Developer/CommandLineTools
```

*Success signal: build and test verification is possible, or the blocker is documented before implementation begins.*

1. Freeze scope before implementation.

*Success signal: the planned work is Ask fallback UX plus trusted-source import only. It excludes live web answers, arbitrary web search providers, Tier 3 review UI, and large new Library management surfaces.*

</pre_flight_checks>

## Numbered Phased Instructions

### Phase 1: Investigation And Scope Lock

1. Read the current Ask, connectivity, dependency, and import files before editing.

   Required files:

   - `OSA/Features/Ask/AskScreen.swift`
   - `OSA/Domain/Ask/Models/RetrievalModels.swift`
   - `OSA/Retrieval/Querying/LocalRetrievalService.swift`
   - `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   - `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`
   - `OSA/App/Bootstrap/OSAApp.swift`
   - `OSA/Networking/Clients/TrustedSourceAllowlist.swift`
   - `OSA/Networking/Clients/TrustedSourceHTTPClient.swift`
   - `OSA/Networking/ImportPipeline/ImportedKnowledgeImportPipeline.swift`
   - `OSA/Networking/ImportPipeline/ImportedKnowledgeNormalizer.swift`
   - `OSA/Shared/Support/Connectivity/ConnectivityState.swift`
   - `OSA/Domain/Networking/Repositories/ConnectivityRepositories.swift`

   *Success signal: the implementation plan names the real current seams and avoids guesses.*

2. Lock the implementation approach before coding.

   Required approach:

   - Online offer belongs in Ask UI, not retrieval service.
   - Browse/search uses `TrustedSourceAllowlist.allSources` filtered to `.approved` entries.
   - The user provides a concrete allowlisted HTTPS page URL.
   - Preview uses fetched content plus existing normalization logic.
   - Import uses `ImportedKnowledgeImportPipeline` unchanged or with only minimal supporting adjustments.
   - Success path re-runs the original Ask query against local retrieval.

   *Success signal: there is one explicit implementation path and it does not branch into “maybe add a real web search backend.”*

3. Lock the launch-scope simplifications explicitly.

   Required simplifications:

   - approved allowlist entries only for the Ask-driven flow
   - no Tier 3 review workflow
   - no arbitrary user-added hosts
   - no retrieval-time network calls
   - no new persistence layer or second import pipeline

   *Success signal: the work stays narrow enough to complete and verify in one slice.*

### Phase 2: Dependency Wiring And Feature State

1. Expose the existing networking/import dependencies to SwiftUI.

   Update `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift` to add environment keys and `EnvironmentValues` accessors for:

   - `trustedSourceHTTPClient: (any TrustedSourceHTTPClient)?`
   - `importPipeline: ImportedKnowledgeImportPipeline?`

   Then update `OSA/App/Bootstrap/OSAApp.swift` to inject `dependencies.trustedSourceHTTPClient` and `dependencies.importPipeline` into the environment.

   *Success signal: `AskScreen` can access the existing HTTP client and import pipeline through the same dependency pattern used elsewhere in the app.*

2. Keep the new UI logic feature-local.

   Create a small Ask-owned flow type rather than a cross-feature abstraction. Acceptable shapes include:

   - `OSA/Features/Ask/TrustedSourceImportSheet.swift`
   - `OSA/Features/Ask/TrustedSourceImportViewModel.swift`

   Do **not** add a new generic service layer unless the feature becomes unmanageable without it.

   *Success signal: M4P6 code stays concentrated in `OSA/Features/Ask/` plus minimal dependency wiring.*

3. Track the original Ask query and the online-import presentation state in `AskScreen`.

   Required state includes:

   - last submitted query or current retry query
   - current connectivity state
   - sheet or navigation state for the import flow
   - import status state for idle, previewing, importing, success, and failure

   *Success signal: Ask can cleanly resume from an insufficient-local-evidence result into import and back into local retrieval.*

### Phase 3: Ask Online Offer UX

1. Update the Ask refusal path so insufficient local evidence can present a trusted online offer.

   Required behavior:

   - If `askState == .refused(.insufficientEvidence)` and connectivity is `.onlineUsable`, show a clearly labeled action such as `Search trusted sources` or `Import from trusted source`.
   - If connectivity is `.offline` or `.onlineConstrained`, do **not** present the import CTA as ready-to-run. Show explanatory copy instead.
   - Preserve the local-only explanation. Do not imply the assistant has direct web access.

   *Success signal: Ask clearly distinguishes “not found locally” from “you may choose to import an approved online source.”*

2. Reuse the existing connectivity system instead of inventing another one.

   Required behavior:

   - Observe `connectivityService.currentState` on appear.
   - Subscribe to `stateStream()` for updates while the screen is active.
   - Reuse `ConnectivityBadge` or the same visual language for connectivity cues.

   *Success signal: the Ask fallback offer appears and disappears in sync with the existing connectivity model.*

3. Do not force the online offer through `LocalRetrievalService`.

   The local retrieval layer should continue returning `.refused(.insufficientEvidence)` for insufficient local evidence. Surface the online continuation at the UI layer.

   *Success signal: retrieval remains deterministic, local-only, and easy to test.*

### Phase 4: Trusted Source Browse/Search And URL Validation

1. Build an Ask-owned trusted-source picker from the allowlist.

   Required behavior:

   - Start from `TrustedSourceAllowlist.allSources`.
   - Filter to entries where `defaultReviewStatus == .approved` for the Ask-driven import path.
   - Support local search by publisher name, domain, and notes.
   - Show publisher name, host, trust label, and short notes where available.

   *Success signal: the user can browse or search approved publishers without any remote discovery API.*

2. Require a concrete HTTPS page URL before preview/import.

   Required validation rules:

   - non-empty URL string
   - valid `URL`
   - `https` scheme only
   - host must exactly match an allowlisted approved publisher

   Use the existing allowlist lookup for host validation. Block invalid URLs before any fetch attempt.

   *Success signal: the feature rejects unsupported or non-allowlisted URLs locally and predictably.*

3. Keep the search/browse scope honest.

   Do **not** scrape publisher search pages, call a third-party search engine, or attempt to infer article URLs from the Ask query. If you need a user-facing label, call this flow `trusted source import` rather than implying a live web answer engine.

   *Success signal: the implementation matches the actual capabilities of the current codebase.*

### Phase 5: Preview, Import, And Ask Re-Query

1. Fetch a preview using the existing HTTP client.

   Required behavior:

   - Call `trustedSourceHTTPClient.fetch(url:)` only after local validation passes.
   - Reuse the current fetch guards and error surface from M4P3.
   - Treat preview as user-visible networking. Show progress while fetching.

   *Success signal: preview fetches only from approved HTTPS URLs and reports failures explicitly.*

2. Build the preview from existing normalization logic.

   Use `ImportedKnowledgeNormalizer` to derive preview-safe metadata such as title, publisher/domain, and a short plain-text excerpt. Do **not** persist anything during preview.

   *Success signal: the user sees meaningful preview information before deciding to import, and preview does not mutate local storage.*

3. Trigger the real import through the existing pipeline.

   Required behavior:

   - On confirmation, call `importPipeline.importFetchedContent(response)` with the already fetched response.
   - Show staged status text such as `Fetching`, `Preparing preview`, `Saving locally`, `Indexing`, `Ready offline`.
   - Keep all network and import work user-initiated and visible.

   *Success signal: import uses the existing M4P4 pipeline and produces durable local records instead of ad hoc feature-local persistence.*

4. Re-run the original Ask query after a successful import.

   Required behavior:

   - Dismiss the sheet or return to Ask.
   - Re-run `submitQuery()` or an equivalent query path with the same user query.
   - If the new imported source is approved and indexed, allow the updated answer to cite it locally.

   *Success signal: the user can see the newly imported local knowledge reflected in Ask without manually retyping the question.*

5. Handle import failure and no-op cases explicitly.

   Required behavior:

   - If preview or import fails, show the error and keep the user in control.
   - If the imported page normalizes to empty content or unsupported content, say so plainly.
   - Do not leave Ask stuck in `.loading` or pretend the import succeeded.

   *Success signal: failed imports are visible, recoverable, and do not corrupt the local Ask experience.*

### Phase 6: Verification And Tests

1. Add focused tests for the Ask-driven import flow.

   Create or extend tests so they cover:

   - online-offer gating by connectivity and refusal reason
   - allowlist-backed publisher filtering
   - URL validation for scheme and exact host matching
   - preview-success and preview-failure state transitions
   - successful import leading to a re-query path

   Recommended file: `OSATests/AskTrustedSourceImportFlowTests.swift`

   *Success signal: the feature’s highest-risk behavior is covered without depending on brittle UI-only assertions.*

2. Extend existing tests only where the new flow genuinely touches shared behavior.

   Possible touchpoints:

   - `OSATests/TrustedSourceAllowlistTests.swift` if you add approved-entry filtering helpers
   - `OSATests/ImportedKnowledgeImportPipelineTests.swift` only if M4P6 requires a small API or preview-support adjustment
   - `OSATests/LocalRetrievalServiceTests.swift` only if you change post-import re-query helpers or retrieval-scope behavior

   *Success signal: new test coverage stays proportional and does not churn unrelated suites.*

3. Run targeted verification first.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/ImportedKnowledgeImportPipelineTests \
  -only-testing:OSATests/LocalRetrievalServiceTests \
  -only-testing:OSATests/TrustedSourceAllowlistTests
```

*Success signal: the import and retrieval seams still behave correctly after the M4P6 UI wiring.*

1. Run a full build after code changes.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: BUILD SUCCEEDED
```

*Success signal: the full app compiles with the new Ask flow and dependency wiring.*

1. Run the full test suite if the environment supports it.

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
# Expected: TEST SUCCEEDED
```

*Success signal: existing Milestones 1 through 4 behavior remains intact.*

1. Run Snyk Code if available.

```bash
command -v snyk >/dev/null && snyk code test --path="$PWD"
```

*Success signal: any first-party code added for the Ask import flow is scanned, or the absence of `snyk` is reported as `unverified`.*

1. Perform a manual end-to-end verification.

   Required manual scenario:

   - Ask an unsupported local question while online.
   - Confirm Ask shows `Not Found Locally` plus a trusted import offer.
   - Open the trusted-source flow.
   - Search publishers, provide an approved HTTPS page URL, and preview it.
   - Import it.
   - Confirm Ask re-runs the query and can cite the imported source.
   - Confirm Library search shows the imported page under `Imported Sources`.
   - Repeat with offline connectivity and confirm the offer is hidden or disabled with accurate messaging.

   *Success signal: M4P6 is proven as a full user-visible path from Ask fallback to durable offline availability.*

<guardrails>

## Guardrails

- **Forbidden:** Adding live web answer behavior to `LocalRetrievalService` or any model adapter.
- **Forbidden:** Introducing a third-party search API, crawler, or general web-search backend.
- **Forbidden:** Allowing arbitrary or user-added hosts outside `TrustedSourceAllowlist`.
- **Forbidden:** Auto-approving Tier 3 or pending sources in the Ask-driven flow.
- **Forbidden:** Building a broad imported-source management feature in Library or Settings as part of this slice.
- **Forbidden:** Adding new dependencies unless strictly required and explicitly justified.
- **Required:** All network activity in this feature is user-initiated and visibly staged.
- **Required:** Imported content becomes Ask-usable only after successful local commit and indexing.
- **Required:** Offline local Ask behavior remains fully usable when the online flow is unavailable.
- **Required:** Keep persistence framework details out of `OSA/Features`.
- **Required:** Prefer a small Ask-owned view model or flow type over a new cross-feature architecture.

</guardrails>

<verification>

## Verification Checklist

- [ ] Ask shows a trusted online import offer only after `.insufficientEvidence` and only when connectivity is `.onlineUsable`
- [ ] Ask does not imply live web access or general-chat behavior
- [ ] Approved allowlist publishers are browseable and locally searchable in the import UI
- [ ] Invalid, non-HTTPS, or non-allowlisted URLs are rejected before fetch
- [ ] Preview shows normalized source metadata without persisting content
- [ ] Import uses the existing M4P4 pipeline rather than duplicate persistence logic
- [ ] Import status is visible to the user through staged progress or clear failure messaging
- [ ] Successful import re-runs the original Ask query
- [ ] The resulting Ask answer can cite imported knowledge from local records
- [ ] Library search can show the imported page under `Imported Sources`
- [ ] Build succeeds
- [ ] Focused tests pass
- [ ] Full test suite passes, or blockers are explicitly reported as `unverified`
- [ ] `snyk code test --path="$PWD"` is run when available, or the blocker is reported as `unverified`

</verification>

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Device is offline or connectivity is constrained | Do not present the import CTA as runnable. Show that Ask remains local-only until connectivity is usable. |
| User enters a malformed URL | Show inline validation and block preview/import. |
| URL uses `http` or a non-allowlisted host | Reject locally before any fetch attempt and explain that only approved HTTPS hosts are supported. |
| Fetch fails due to status code, unsupported content type, redirect rejection, or size limit | Surface the HTTP client error directly in the import UI and preserve the prior Ask state. |
| Preview normalization fails or yields empty content | Show a clear `Unable to preview this page` or `No importable content found` state and do not persist anything. |
| Import pipeline throws after preview succeeds | Show an import-failed state, keep Ask usable, and do not assume the content is available locally. |
| Approved source imports successfully but the follow-up query still lacks evidence | Re-run Ask anyway, then keep the local-only refusal if the imported page genuinely does not answer the question. Do not fabricate success. |
| Full Xcode or Snyk is unavailable | Report the exact command blocker and mark the affected verification step `unverified`. |

<out_of_scope>

## Out Of Scope

- Third-party or remote web search integration
- Arbitrary URL import outside the allowlist
- Tier 3 review queues or approval management UI
- Broad imported-source browse or management screens in Library or Settings
- Background-triggered user-search flows
- Sync, export, or cross-device source sharing
- Changes to the retrieval ranking model unrelated to consuming already indexed imported knowledge

</out_of_scope>

## Alternative Solutions

1. **Primary:** Ask-owned sheet with approved-publisher filtering plus validated URL entry, preview, import, and automatic Ask re-query. Pros: smallest coherent implementation, uses current architecture, easy to reason about. Cons: requires the user to supply a concrete page URL.
2. **Fallback A:** Replace the sheet with a dedicated full-screen `TrustedSourceImportView` in `OSA/Features/Ask/` if modal state becomes too complex. Pros: simpler state management for a multi-step flow. Cons: slightly larger navigation surface.
3. **Fallback B:** If preview reuse through `ImportedKnowledgeNormalizer` proves too costly, import immediately after validation and show post-import metadata instead of pre-import preview. Pros: smaller implementation. Cons: weaker user control and a worse UX than the preferred preview-first flow.

<report_format>

## Report Format

When the implementation is complete, report in this order:

1. **Outcome:** whether M4P6 now provides a real Ask-driven trusted-source import flow.
2. **Files changed:** the exact Swift and test files added or modified.
3. **Key decisions:** the chosen Ask-flow shape, how approved sources were filtered, and how preview/import were implemented.
4. **Verification evidence:** exact commands run and whether they passed or are `unverified`.
5. **User-visible behavior:** how the offer appears, how import status is shown, and what happens after success.
6. **Safety and scope notes:** confirmation that Ask still answers only from local committed evidence and does not use live web answers.
7. **Deferred work:** any intentionally deferred items such as Tier 3 review UI or richer source management.

</report_format>
