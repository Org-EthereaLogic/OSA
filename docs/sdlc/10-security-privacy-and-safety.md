# Security, Privacy, And Safety

Status: Initial draft complete.  
Related docs: [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md), [ADR-0002](../adr/ADR-0002-grounded-assistant-only.md)

## Confirmed Facts

- Private-by-default behavior is a core product principle.
- User inventory, notes, prompts, and local knowledge should remain on device unless a future feature explicitly adds sync or export.
- The app includes safety-sensitive domains that require product-level controls, not just model prompts.

## Assumptions

- v1 will not depend on third-party remote AI APIs.
- Any future online source search may involve remote requests, but imported content will still be stored locally with provenance.
- The app will be distributed through TestFlight or the App Store and must satisfy platform privacy expectations.

## Recommendations

- Minimize permissions and remote dependencies in v1.
- Use strong default data protection classes for on-device storage.
- Encode sensitive-topic boundaries in UI, content model, assistant policy, and QA, not just one layer.

## Open Questions

- Will future trusted web search require a server-side proxy or can it rely on public fetches alone?
- Does the app need an explicit local passcode or screen-lock feature beyond device security?
- Should AI session history be user-clearable from day one?

## Local Data Protection Strategy

Recommended baseline:

- Use Apple's file protection for app data, preferably `CompleteUntilFirstUserAuthentication` unless a stricter mode is proven compatible with background behavior.
- Keep all normalized user data and imported knowledge inside the app container.
- Store sensitive small secrets, if any are ever needed, in Keychain rather than in the database.
- Allow local store deletion and reset from Settings for privacy recovery.

## What Data Stays On Device

By default in v1:

- handbook seed content
- imported normalized knowledge
- source metadata
- inventory
- checklists and checklist history
- personal notes
- Ask prompts and responses
- AI session logs
- search index
- local diagnostics

## What Data May Ever Leave The Device In Online Modes

Potentially, and only when the user invokes online features:

- search terms or query fragments needed to discover trusted sources
- requested URLs or domain lookups for source retrieval
- lightweight refresh metadata checks for already approved sources

V1 recommendation:

- do not transmit full note bodies, inventory contents, or Ask conversation history for remote processing
- do not upload retrieved evidence or citations
- do not include hidden analytics SDKs

## Network Security Assumptions

- Use App Transport Security-compliant TLS connections only (HTTPS scheme required by `TrustedSourceHTTPClient`).
- Restrict network calls to trusted source domains via `TrustedSourceAllowlist` (exact host matching against 15 approved publishers, no wildcard rules).
- Validate HTTPS scheme, allowlist membership, HTTP status (2xx), Content-Type (text/html, text/plain, application/xhtml+xml), payload size (≤2 MB), and post-redirect host before accepting a fetch response.
- Treat all remote content as untrusted until normalized and approved locally; raw fetch responses (`TrustedSourceFetchResponse`) carry bytes and metadata only and do not claim approval or indexing.

## Secret Handling

- Avoid shipping third-party API secrets inside the app binary.
- If a future provider requires secrets, use a developer-controlled proxy or user-supplied credentials stored in Keychain.
- Keep trust policy, allowlists, and capability flags as app-configured data, not hard-coded secrets.

## Permission Model

V1 should avoid broad system permissions.

- Notifications: optional, only if checklist or inventory reminders are added.
- Location: not required for core MVP; do not request unless a future local-reference feature clearly needs it.
- Contacts: do not request; family plan data should be entered manually into notes in v1.
- Photos/files: only if a later attachment feature is approved.

## On-Device Privacy Posture

- The app works without account creation.
- Local knowledge and personal data remain device-local by default.
- Ask uses local retrieval and on-device generation or extractive fallback where available.
- Users should be able to understand when an online request is about to happen.
- Siri and Spotlight entity exposure (M6P2) follows privacy-bounded rules: inventory entities exclude archived items and never expose free-form `notes` in display representations or `CSSearchableItemAttributeSet` metadata. Checklist entities resolve templates only, not active runs. No notes or imported-knowledge entities are exposed to system surfaces.

## Future Sync And Privacy Implications

If backup or sync is added later:

- it must be opt-in
- it must specify what data classes sync
- it must document encryption, retention, and conflict behavior
- it requires a new privacy review and likely a new ADR

## Product Safety Boundaries

The app must block or tightly constrain:

- free-form tactical weapon guidance
- hunting coaching
- high-risk medical diagnosis or personalized treatment advice
- edible-plant identification
- unsafe fire, electrical, gas, chemical, or structural improvisation

Content categories requiring stricter controls or static-only handling:

- first aid, hygiene, and medications
- fire and lighting
- utilities and home systems
- archery and longbow
- any hazard guidance with bodily-injury risk

## Prompt Injection And Scope-Override Prevention

The assistant pipeline includes two layers of defense against prompt injection, jailbreak phrasing, and scope-override attempts:

1. **Pre-retrieval detection** (`SensitivityPolicy`): phrase-based and keyword-based pattern matching blocks known injection vectors (e.g., "ignore previous instructions", "reveal your system prompt", "jailbreak", "bypass restrictions", "do anything now") before retrieval or generation. Injection queries return `.blocked` and never reach the model adapter.
2. **In-prompt reinforcement** (`GroundedPromptBuilder`): the model-ready prompt includes an `OVERRIDE PROTECTION` instruction directing the model to ignore any embedded instructions within the user's question that attempt to change rules, reveal system instructions, or expand scope.

These defenses are tested by `SafetyRegressionTests` covering jailbreak phrasing, system prompt extraction, scope overrides, mixed-intent prompts, case insensitivity, deterministic refusal, and privacy-bounded refusal reasons.

## Abuse And Misuse Considerations

- Users may try to use Ask as a general chatbot; the UX must teach and enforce scope limits.
- Users may attempt prompt injection or jailbreak phrasing to override assistant policy; `SensitivityPolicy` and `GroundedPromptBuilder` enforce scope and safety boundaries at both pre-retrieval and prompt-shaping layers.
- Imported-source functionality could be abused to collect low-quality or unsafe information; trust allowlists and review states are required.
- Personal notes might contain sensitive household details; the app should avoid accidental sharing surfaces.

## How Imported Web Content Is Attributed

- Store source title, source URL, publisher/domain, fetched timestamp, last-reviewed timestamp, content hash, trust level, tags, and local chunk IDs.
- Display source title and publisher/domain in citations.
- Keep provenance visible in any imported-source detail view.

## User Disclosures

The app should disclose:

- that core data is stored locally on device
- that Ask is bounded to approved local content
- that online features may contact trusted web sources when the user chooses them
- that the app is informational and not a substitute for emergency services, medical care, or professional advice

## App Store Privacy Note Placeholders

Likely disclosures to verify at release time:

- Data not linked to user: possibly diagnostics, if any opt-in export exists later
- Data linked to user: likely none in v1 if no account system or remote analytics exist
- Sensitive data: notes and inventory remain on device; if not transmitted, they may not require collection disclosure

Final App Store disclosures must be validated against the actual shipped build.

## Done Means

- Device-local data boundaries are explicit.
- Online operations and their privacy implications are constrained and understandable.
- Safety controls are defined as product behavior, not just documentation language.

## Next-Step Recommendations

1. Make a firm decision on whether any third-party networking service is acceptable in v1.
2. Add a user-facing privacy summary screen or onboarding explanation early.
3. Treat any future remote AI dependency as a separate product-phase decision.
