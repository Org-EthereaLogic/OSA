# Product Requirements Document

Status: Initial draft complete.  
Related docs: [Problem Brief](./01-problem-brief.md), [MVP Scope Roadmap](./03-mvp-scope-roadmap.md), [Information Architecture And UX Flows](./04-information-architecture-and-ux-flows.md), [Technical Architecture](./05-technical-architecture.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md)

## Confirmed Facts

- OSA is an offline-first preparedness handbook app for iPhone.
- Core features include handbook browsing, quick cards, checklists, inventory, notes, and a local Ask assistant.
- Online capabilities are optional and intended for trusted web search, knowledge refresh, and future remote updates or backup.
- Sensitive domains must be tightly bounded.

## Assumptions

- v1 aims for a usable single-device product with strong local functionality before any account or sync features.
- The initial content corpus will be curated and finite enough for deterministic retrieval methods.
- First release quality is more important than breadth of imported-source support.

## Recommendations

- Define feature completeness by offline usefulness first, then layer online enrichment.
- Treat Ask as a retrieval surface with synthesis, not a conversational platform.
- Release only after core content areas and quick cards are authored to a minimum quality bar.

## Open Questions

- What minimum content depth is required per chapter for MVP?
- ~~Are personal notes in Ask scope by default or opt-in?~~ **Resolved:** Opt-in, default false. Controlled by `AskScopeSettings` (`@AppStorage`-backed) and surfaced as a toggle in both AskScreen and SettingsScreen.
- Is future device backup or export important enough to influence v1 settings and disclosures?

## Product Summary

OSA is a local-first preparedness handbook and organizer. It combines curated offline content with household-specific data and a grounded Ask experience that cites local sources. When online, the app may search trusted web sources, import reviewed material, and persist it locally so future answers still work offline.

## User Personas

### Preparedness Planner

- Maintains supplies, family plan details, and checklists.
- Needs dependable offline access and structured organization.

### Household Helper

- Uses the app during a stressful moment to open quick cards, contacts, or simple checklists.
- Needs clarity, speed, and low cognitive load.

### Careful Reference User

- Wants reviewed, lawful reference notes, including narrow archery and longbow safety or maintenance content.
- Needs citations and scope boundaries, not broad speculative advice.

## Jobs To Be Done

- When I need preparedness guidance with no signal, help me find the right local information quickly.
- When I maintain supplies, help me track what I have, what is missing, and what expires.
- When I need step-by-step reminders, give me concise checklists and quick cards.
- When I need a simple field utility under stress, give me an offline local tool without extra permissions or connectivity.
- When I ask a question, answer only from trustworthy local material and show where the answer came from.
- When local information is insufficient and I am online, help me search trusted sources and save approved material for later offline use.

## Key User Stories

- As a user, I can browse handbook chapters and sections fully offline.
- As a user, I can search local handbook, notes, quick cards, inventory, and imported knowledge offline.
- As a user, I can ask a question against local data and receive a cited answer or a clear "not found locally" response.
- As a user, I can open emergency quick cards immediately from the app home screen.
- As a user, I can create, edit, and search inventory items offline.
- As a user, I can complete checklist runs offline and keep history locally.
- As a user, I can write personal notes and link them to topics or supplies.
- As a user, I can open offline survival tools for Morse, screen signaling, timing, conversion, radio notes, and approximate declination reference.
- As a user, when connected, I can search trusted sources and import selected knowledge for future offline use.

## Functional Requirements

### Handbook And Library

- Organize handbook content into chapters and sections with stable taxonomy.
- Support chapter browsing, section reading, and related quick-card links.
- Show review date and safety level on sensitive sections where relevant.

### Search

- Search local content across handbook, quick cards, notes, inventory, checklist templates, and imported knowledge.
- Support filters by content type, chapter, tags, and trust level.
- Return stable, citeable results offline.

### Ask

- Retrieve only from approved local sources and app data.
- Answer with citations or refuse when evidence is insufficient or out of scope.
- Offer optional trusted online search when connected and local evidence is insufficient.

### Inventory

- Create, edit, archive, search, and categorize inventory items.
- Track quantity, location, tags, notes, and optional expiration data.

### Checklists

- Browse curated checklist templates.
- Start checklist runs, mark items complete, and resume later offline.
- Support ad hoc checklist items inside a run if needed.

### Quick Cards

- Surface high-priority actionable summaries in large-type layouts.
- Open from Home with minimal taps.
- Provide links to deeper handbook sections.

### Tools

- Provide bounded offline survival and communication utilities such as Morse encoding, screen-based SOS signaling, whistle playback, timer or stopwatch, unit conversion, static radio notes, and approximate declination reference.
- Keep tool behavior local-only, permission-stable, and honest about screen-aid or precision limits.
- Avoid persistence, account, or networking dependencies for transient utility behavior.

### Notes

- Create and edit notes offline.
- Tag and optionally link notes to handbook sections or inventory items.

### Settings

- Show offline status, model capability state, trusted source preferences, and data/privacy settings.
- Allow control over whether personal notes participate in Ask retrieval.

## Non-Functional Requirements

- Fast cold start and no mandatory network waits.
- Predictable behavior under degraded connectivity.
- Strong on-device privacy defaults.
- Explicit source provenance and local citations.
- Content and AI safety boundaries enforced consistently.
- Storage growth remains observable and manageable.

## Offline Requirements

Core offline features must include:

- browsing handbook content
- searching local content
- using the local Ask feature over local data
- viewing quick cards
- using offline survival tools
- viewing and editing inventory
- viewing and editing checklists
- personal notes

Offline acceptance baseline:

- a fully offline cold start still reaches all core screens
- no screen shows blocking network errors for local data
- Ask returns citations or a clear local-only limitation message

## Online And Web Requirements

Online-only or online-enhanced features may include:

- external web search
- source ingestion and knowledge refresh
- remote content updates
- future backup and sync

Online behavior requirements:

- network state is visible but non-intrusive
- user approval gates imported-source additions unless a trusted content-pack policy is later approved
- imported material is normalized, attributed, chunked, indexed, and stored locally before use by Ask

## AI Requirements

- Ask must never operate as a general chatbot.
- Ask must answer only from approved local sources and app data.
- Ask must cite local chapter, section, quick card, or imported source records.
- Ask must clearly state when an answer is not available locally.
- Ask must degrade gracefully when on-device generation support is unavailable.

## Content-Safety Requirements

- No free-form tactical weapon or hunting guidance.
- No high-risk medical advice beyond reviewed static content.
- No edible-plant identification.
- No unsafe emergency improvisation beyond reviewed static content.
- Archery and longbow coverage is limited to safety, inspection, care, storage, inventory, range habits, practice logs, and lawful curated reference notes.

## Data And Privacy Requirements

- Inventory, notes, prompts, AI sessions, and local knowledge remain on device by default.
- Online source discovery must minimize data sent off device.
- Imported web content must preserve attribution and trust metadata.
- No account is required for v1.
- Future backup or sync must be explicitly opt-in and separately designed.

## Out Of Scope

- Social sharing or community forums
- Cloud account system in v1
- Live remote chatbot behavior
- Wearables, iPad, or Mac-first optimizations in v1
- Tactical simulation, mapping engine, or advanced geospatial routing in v1
- Complex household collaboration and multi-user permissions in v1

## Release Goals

- Deliver a dependable offline handbook and organizer for a single user or household.
- Ship a bounded Ask experience with citations and fallback behavior.
- Support at least one trustworthy online knowledge-refresh flow that produces durable offline value.
- Keep the architecture simple enough to maintain as a solo developer.

## Done Means

- Requirements are explicit enough to determine MVP scope and architecture.
- Offline versus online responsibilities are clearly separated.
- Safety and privacy constraints are concrete enough to drive tests and UI copy.

## Next-Step Recommendations

1. Freeze the MVP chapter list and quick-card set before UI implementation.
2. Decide the minimum Ask capability on unsupported devices so the UX can be designed consistently.
3. Translate these requirements into milestone acceptance criteria in the roadmap and QA plan.
