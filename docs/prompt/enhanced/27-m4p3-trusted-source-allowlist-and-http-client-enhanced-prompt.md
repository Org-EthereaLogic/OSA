# M4P3 Enhanced Prompt: Trusted-Source Allowlist And HTTP Client

**Date:** 2026-03-26
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Moderate
**Complexity Justification:** This task adds the first online-enrichment execution surface after M4P1 and M4P2. It spans a small set of new networking files plus focused tests, but it must encode trust policy correctly, preserve offline-first boundaries, and avoid leaking into M4P4 import-pipeline work.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow  M4P3 <- Trusted-source allowlist + HTTP client (knows WHO to fetch from)` | The requested slice is M4P3 only: define who OSA may fetch from and add the minimal HTTP client needed to fetch from those sources. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | OSA must remain offline-first, local-first, grounded, and explicit about verification. Networking work must not bypass local persistence, provenance, or safety boundaries. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | M4P1 and M4P2 are complete. M4P3 is explicitly `trusted-source allowlist and HTTP client`. |
| `docs/sdlc/05-technical-architecture.md` | `OSA/Networking/Clients/`, `DTOs/`, `ImportPipeline/`, and `Refresh/` are the correct boundaries. Background `URLSession` is for later refresh/download flows, not this first fetch client. |
| `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` | Launch policy requires a trusted-domain allowlist, clear trust tiers, user-visible online behavior, and rejection of unknown domains by default. |
| `docs/sdlc/08-ai-assistant-retrieval-and-guardrails.md` | Ask may offer online search later, but it must never answer from live remote pages. M4P3 must stop at trusted fetch capability. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Use ATS-compliant TLS only, restrict outbound calls to approved domains, validate content type and size, and keep remote content untrusted until later normalization and approval. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Networking and import-path changes require focused tests for offline/online transitions, interruption, and policy enforcement. |
| `docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md` | Live remote pages must not bypass the local import and persistence pipeline. |
| `docs/prompt/enhanced/15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md` | The initial 15-source trusted-source allowlist already exists as approved editorial guidance and should be reused rather than reinvented. |
| `docs/prompt/enhanced/23-app-bundle-seed-content-packaging-and-full-launch-validation-enhanced-prompt.md` | The preserved M4 dependency sequence is `M4P1`, `M4P2`, `M4P3`, `M4P4`, `M4P5`, `M4P6`. |
| `OSA/Networking/README.md`, `OSA/Networking/Clients/README.md`, `OSA/Networking/DTOs/README.md` | The networking layer is scaffolded and ready for concrete client and DTO files. |
| `OSA/Domain/Networking/Repositories/ConnectivityRepositories.swift`, `OSA/Networking/Clients/NWPathMonitorConnectivityService.swift` | Connectivity state already exists and is the explicit prerequisite for M4P3. |
| `OSA/Domain/ImportedKnowledge/Models/SourceRecord.swift`, `TrustLevel.swift`, `ReviewStatus.swift` | M4P2 already defines the imported-source metadata model and trust/review enums. M4P3 should map the allowlist onto these existing types rather than adding new tier enums. |

## Mission Statement

Implement M4P3 by codifying OSA's first trusted-source allowlist and adding a minimal `URLSession`-backed HTTP client that fetches only from approved HTTPS sources while enforcing connectivity, content-type, and size guards without yet performing normalization, chunking, persistence, or UI work.

## Technical Context

OSA is now at the point where the imported-knowledge persistence model exists but the app still lacks the first concrete networking surface that decides whether a remote URL is allowed at all. That is the purpose of M4P3.

This phase should remain deliberately narrow. The client must know who OSA may fetch from and must return raw fetched payloads for later pipeline stages, but it must not decide how content is normalized, chunked, indexed, reviewed, surfaced in Ask, or refreshed in the background. Those belong to M4P4 and later.

Use the current imported-knowledge model rather than inventing a second trust vocabulary. Map the editorial tier language already documented in prior prompt material onto the existing enums as follows:

| Editorial Tier | `TrustLevel` | `ReviewStatus` | Meaning In M4P3 |
| --- | --- | --- | --- |
| Tier 1 reviewed | `.curated` | `.approved` | Developer-vetted authoritative sources. |
| Tier 2 approved | `.community` | `.approved` | Reputable preparedness sources allowed at launch. |
| Tier 3 reference-only | `.unverified` | `.pending` | Allowed to fetch for later review, but not auto-approved. |

Reuse the 15 approved launch publishers already captured in the earlier prompt artifact:

- Tier 1: Ready.gov, Oregon Dept of Emergency Mgmt, Washington Emergency Mgmt, USGS, American Red Cross - Cascades, USDA Forest Service R6
- Tier 2: Pacific NW Seismic Network, OSU Extension - Cascadia, The Prepared, Surviving Cascadia, Cascadia Ready, Seattle Emergency Hubs
- Tier 3: Oregon Hazards Lab, Mountain House Blog, Survival Common Sense

Treat host canonicalization as a narrow implementation detail, not a product decision. If a publisher's exact canonical hostname is not already explicit in repository material, use the publisher's stable organizational root host, document that mapping in code, and record it in the completion report.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| `OSA/Networking/Clients/` only contains connectivity implementations. | The folder also contains a trusted-source allowlist and a concrete HTTP fetch client for approved sources. |
| There is no production type that answers whether a URL is fetchable under OSA policy. | There is one local allowlist surface that resolves a URL to an approved publisher entry or rejects it. |
| There is no HTTP client that uses connectivity state and trust policy together. | A minimal fetch client refuses offline or unapproved requests and returns raw payload metadata for later pipeline stages. |
| Imported-knowledge models exist, but there is no M4P3 bridge from publisher policy to later `SourceRecord` creation. | The allowlist maps cleanly onto existing `TrustLevel` and `ReviewStatus` values without changing M4P2 schema. |
| M4P4 import-pipeline work could start from an underspecified network boundary. | M4P4 receives a clear, tested upstream contract: who may be fetched and what a valid fetched payload looks like. |

## Pre-Flight Checks

1. Confirm the networking scaffolding is still mostly empty before adding new M4P3 files.

   ```bash
   ls OSA/Networking/Clients
   ls OSA/Networking/DTOs
   ```

   Expected starting point:

   - `OSA/Networking/Clients` contains `NWPathMonitorConnectivityService.swift`, `PreviewConnectivityService.swift`, and `README.md`
   - `OSA/Networking/DTOs` contains `README.md`

   *Success signal: M4P3 is adding the first trusted-source fetch surfaces, not duplicating existing ones.*

2. Confirm the current imported-knowledge enums and source model that M4P3 must align with.

   ```bash
   rg -n "enum TrustLevel|enum ReviewStatus|struct SourceRecord" OSA/Domain/ImportedKnowledge
   ```

   *Success signal: the implementation can map allowlist entries onto existing trust and review types without schema churn.*

3. Confirm no production HTTP client already exists under OSA source.

   ```bash
   rg -n "URLSession|HTTPClient|TrustedSourceHTTPClient" OSA/Networking OSA/Domain OSATests
   ```

   *Success signal: the task is still net-new M4P3 code rather than a refactor of an existing fetch client.*

4. Freeze the milestone boundary before editing.

   *Success signal: the executor can state plainly that M4P3 stops at allowlist plus trusted fetch and does not implement normalization, chunking, persistence, refresh coordination, or Ask UX.*

5. Decide the first supported remote payload class.

   *Success signal: M4P3 supports text-oriented HTTP responses only, such as `text/html`, `text/plain`, or `application/xhtml+xml`, and explicitly defers PDFs, binaries, and rich-media parsing to later phases.*

## Phased Instructions

### Phase 1: Investigation And Setup

1. Read the existing connectivity contract and live connectivity implementation before adding fetch behavior.
   *Success signal: the HTTP client is designed around `ConnectivityService` rather than inventing a second reachability mechanism.*

2. Reuse the approved 15-source launch list as the only fetch allowlist for this phase.
   *Success signal: the implementation does not invent new publishers, wildcard domains, or user-editable trust policy in M4P3.*

3. Choose the smallest coherent file set for the phase.
   *Success signal: the implementation adds only the allowlist, the fetch client contract and implementation, one raw response DTO, and focused tests.*

### Phase 2: Implement The Trusted-Source Allowlist

1. Create `OSA/Networking/Clients/TrustedSourceAllowlist.swift`.
   *Success signal: one source of truth exists for launch-approved publishers and their trust mappings.*

2. In that file, define a small value type such as `TrustedSourceDefinition` that stores at least:

   - display or publisher name
   - canonical host
   - trust level
   - default review status
   - optional notes or rationale string

   *Success signal: each allowlist entry carries enough information to support later `SourceRecord` creation without coupling this phase to persistence.*

3. Populate the allowlist with the 15 approved publishers from the earlier prompt artifact and map them onto the current enums using the table above.
   *Success signal: Tier 1 maps to `.curated + .approved`, Tier 2 maps to `.community + .approved`, and Tier 3 maps to `.unverified + .pending`.*

4. Add narrow lookup helpers such as:

   - `entry(for url: URL) -> TrustedSourceDefinition?`
   - `isAllowed(_ url: URL) -> Bool`
   - `definition(forHost host: String) -> TrustedSourceDefinition?`

   *Success signal: later pipeline code can ask one local policy surface whether a URL is approved and what trust metadata it implies.*

5. Keep allowlist matching conservative.
   *Success signal: only explicit HTTPS hosts in the approved list resolve successfully, and unknown or malformed hosts are rejected by default.*

### Phase 3: Implement The Trusted Fetch Client

1. Create `OSA/Networking/DTOs/TrustedSourceFetchResponse.swift` to represent the raw fetched payload.

   Include at least:

   - requested URL
   - final response URL
   - HTTP status code
   - MIME type or content type string
   - response body as `Data`
   - `fetchedAt`

   *Success signal: M4P4 can consume a concrete raw-fetch result without reaching back into `URLSession` types.*

2. Create `OSA/Networking/Clients/TrustedSourceHTTPClient.swift` and define the fetch contract plus explicit fetch errors.

   Expected contract shape:

   ```swift
   protocol TrustedSourceHTTPClient {
       func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse
   }
   ```

   Errors should cover at least offline state, invalid scheme, disallowed host, bad status code, unsupported content type, oversized payload, and unexpected response type.

   *Success signal: the client boundary is inspectable and failure cases are deterministic rather than hidden inside generic networking errors.*

3. Create `OSA/Networking/Clients/URLSessionTrustedSourceHTTPClient.swift` as the live implementation.

   The implementation must:

   - depend on `ConnectivityService`
   - depend on `URLSession`
   - depend on `TrustedSourceAllowlist`
   - reject `.offline` before issuing the request
   - require `https`
   - reject non-allowlisted hosts before the request
   - verify the final response URL is still allowlisted after redirects
   - accept only text-oriented content types for this phase
   - enforce a bounded payload size suitable for the first text-source prototype

   *Success signal: the live client knows who it may fetch from and returns raw payloads only when both connectivity and trust policy permit it.*

4. Use ordinary foreground `URLSession` behavior in M4P3.
   *Success signal: the implementation does not introduce background download sessions, refresh scheduling, or retry orchestration that belongs to M4P5.*

5. If wiring the client into composition root improves the next phase without leaking it into views, add it to `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` only.
   *Success signal: the client is available to later import-pipeline code without prematurely exposing it as a SwiftUI environment dependency.*

### Phase 4: Add Focused Tests

1. Create `OSATests/TrustedSourceAllowlistTests.swift`.

   Cover at least:

   - approved host resolution for representative Tier 1, Tier 2, and Tier 3 entries
   - rejection of unknown domains
   - rejection of malformed URLs or missing hosts
   - correct mapping to `TrustLevel` and `ReviewStatus`

   *Success signal: the policy surface is deterministic and the launch allowlist is encoded as executable tests.*

2. Create `OSATests/TrustedSourceHTTPClientTests.swift` using a stubbed or custom `URLProtocol`-backed `URLSession` rather than live network access.

   Cover at least:

   - fetch succeeds for an approved HTTPS host and supported content type
   - offline state fails before network execution
   - non-HTTPS URL fails before network execution
   - unknown host fails before network execution
   - non-2xx response fails with the correct error
   - unsupported content type fails
   - oversized payload fails
   - redirected final URL to an unapproved host fails

   *Success signal: the fetch client behavior is fully testable without depending on live internet connectivity.*

3. Keep tests policy-focused rather than parser-focused.
   *Success signal: M4P3 tests validate allowlist and fetch-contract behavior only, leaving normalization and chunking tests for M4P4.*

### Phase 5: Verification

1. Build or test the touched code with the project scheme.

   ```bash
   xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```

   *Success signal: the suite passes, or the exact environment blocker is reported and the affected claim is marked unverified.*

2. Run a focused security scan because this phase adds first-party networking code.

   ```bash
   snyk code test --path="$PWD"
   ```

   *Success signal: no new high-signal security findings are introduced, or exact findings are reported with scope and severity.*

3. Manually confirm that the implementation boundary still ends before persistence and import-pipeline work.
   *Success signal: there are no changes in `OSA/Networking/ImportPipeline/`, `OSA/Networking/Refresh/`, Ask UI, or imported-knowledge persistence repositories beyond optional dependency exposure in composition root.*

### Phase 6: Security And Quality Review

1. Verify that only ATS-compatible HTTPS endpoints are allowed.
   *Success signal: the client rejects `http` and other non-HTTPS schemes before the request is sent.*

2. Verify that unknown publishers remain denied by default.
   *Success signal: the allowlist does not contain wildcard hosts, broad suffix rules, or an implicit fallback-allow path.*

3. Verify that remote content is still treated as untrusted raw input after fetch.
   *Success signal: the returned DTO contains bytes and metadata only; it does not claim approval, indexing, or assistant usability.*

4. Verify that no user-authored local data is transmitted as part of the fetch layer.
   *Success signal: the client sends only the request URL and ordinary HTTP metadata, with no notes, inventory, prompts, or assistant history attached.*

## Guardrails

<guardrails>
- Do not implement normalization, chunking, persistence, deduplication, indexing, review workflows, or Ask online-offer UI in this task.
- Do not broaden the allowlist beyond the 15 approved launch publishers already captured in repository prompt material.
- Do not introduce wildcard domain matching, user-editable trust policy, or remote-config driven allowlists.
- Do not add a second trust-tier enum; map onto existing `TrustLevel` and `ReviewStatus`.
- Do not fetch non-HTTPS URLs.
- Do not accept PDF, binary, image, or media-heavy source formats in M4P3.
- Do not use background `URLSession`, refresh scheduling, or retry queues here.
- Do not expose the new client directly to feature views unless a current screen already needs it, which M4P3 does not.
- Keep the implementation small and direct. Target roughly 4 to 6 production files plus 2 focused test files.
</guardrails>

## Verification Checklist

- [ ] A dedicated trusted-source allowlist exists under `OSA/Networking/Clients/`.
- [ ] The allowlist encodes the approved 15 launch publishers.
- [ ] Tier mappings align with existing `TrustLevel` and `ReviewStatus` enums.
- [ ] A dedicated fetch DTO exists under `OSA/Networking/DTOs/`.
- [ ] A `TrustedSourceHTTPClient` contract exists.
- [ ] A `URLSession`-backed implementation rejects offline, non-HTTPS, and non-allowlisted requests.
- [ ] The client validates response status, content type, and payload size.
- [ ] Redirects to unapproved hosts are rejected.
- [ ] Focused allowlist and HTTP client tests exist and avoid live network dependence.
- [ ] `xcodebuild ... test` was run, or the exact blocker was reported.
- [ ] `snyk code test --path="$PWD"` was run if available, or the exact blocker was reported.
- [ ] No M4P4+ implementation work leaked into this phase.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| A publisher name is approved in prompt material but its exact canonical host is not explicit in repo docs | Use the publisher's stable organizational root host, document the assumption in code and the completion report, and keep the mapping narrow. |
| The live client needs to check connectivity from a main-actor-only service | Read connectivity through the existing `ConnectivityService` contract in a main-actor-safe way instead of adding a second reachability API. |
| `URLSession` redirects to a different host | Validate the final response URL against the allowlist and fail if the redirected host is not approved. |
| A trusted host returns an unsupported content type such as PDF or image data | Reject the response in M4P3 and defer broader format handling to later import phases. |
| Test implementation starts depending on the real network | Replace the live session with a stubbed `URLProtocol` or equivalent mocked session configuration. |
| `xcodebuild` or `snyk` is unavailable in the environment | Report the exact command failure and keep the affected verification claim unverified. |
| Scope starts creeping into import pipeline or Ask UI work | Stop and cut the task back to allowlist plus fetch boundary only. |

## Out Of Scope

- Normalization, chunking, deduplication, or local commit of fetched content
- `PendingOperation` orchestration, retry logic, or refresh scheduling
- Background stale checks and subscribed-source refresh
- Ask UI changes, online-search offer UX, or assistant responses from remote content
- User-editable source approval management
- PDF, binary, image, or map-tile ingestion
- Any change that makes live remote content directly answerable before local persistence and attribution

## Alternative Solutions

1. **Recommended primary approach:** keep the allowlist as static Swift data in `TrustedSourceAllowlist.swift` and keep the first fetch client `URLSession`-backed. Pros: simplest reviewable policy surface, easy tests, no resource-loading complexity. Cons: publisher list updates require code edits.
2. **Fallback if the allowlist becomes unwieldy during implementation:** move the allowlist entries into a bundled local JSON resource while preserving the same lookup API. Pros: easier editorial maintenance. Cons: adds resource-loading behavior and one more failure mode. Do not take this fallback unless the static Swift representation becomes clearly harder to maintain within this phase.
3. **Fallback on host matching strictness:** if host-plus-path rules add avoidable complexity, start with exact-host matching only. Pros: smallest coherent implementation. Cons: some publisher subpaths or subdomains may need explicit later additions.

## Report Format

When this prompt is executed, report back in this structure:

1. Files added and files changed.
2. The final allowlist summary: publisher names, canonical hosts, and mapped `TrustLevel` / `ReviewStatus` values.
3. The fetch-client contract and the concrete guards it enforces.
4. Any hostname or publisher-mapping assumptions that were necessary.
5. Test files added and the behaviors they cover.
6. Verification commands run and their outcomes.
7. Security scan result or exact blocker.
8. Any deferred work or explicitly unverified claims.
