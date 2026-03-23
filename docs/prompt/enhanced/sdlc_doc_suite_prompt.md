# SDLC document suite prompt for coding agent

You are working inside the repository for a new iPhone app. Your job is to create the initial SDLC document suite only. Do **not** begin feature implementation unless you need to inspect the current repo structure to anchor the docs.

## Project context

This project is an **offline-first iPhone preparedness handbook app** with optional online capabilities.

Core product idea:
- A curated offline preparedness handbook with chapters, quick cards, checklists, inventory, personal notes, and a local “Ask” assistant.
- The assistant is **not** a general chatbot. It must answer only from approved local content and app data.
- The app should work **fully offline for core functionality**.
- When online, the app may search trusted web sources, import or refresh knowledge, and store normalized, attributed copies of that knowledge **locally on the device** for future offline use.
- Most, ideally all, major user-facing features should continue to work when the phone is offline.

Initial content domains:
- Preparedness foundations
- Family plan and emergency contacts
- Water storage and purification
- Food rations and pantry planning
- Power outages and cooking without power
- Warmth, shelter, and seasonal weather
- First aid, hygiene, and medications
- Go-bags and grab-and-go kits
- Home supplies, utilities, and tools
- Local notes, maps, and forest reference
- Fire and lighting basics
- Archery / longbow reference

Important content-safety boundaries:
- The app may include **archery content**, but only for safety, inspection, care, storage, inventory, range habits, practice logs, and curated lawful reference notes.
- Do **not** design the assistant to provide free-form tactical weapon guidance, hunting coaching, high-risk medical advice, unsafe fire-making improvisation, or edible-plant identification.
- For sensitive topics, prefer reviewed static reference content, checklists, and quick cards over model improvisation.

## Product expectations

Design the docs around these product principles:
1. **Offline-first / local-first**: all critical user data and knowledge needed for core flows must exist locally.
2. **Grounded AI**: the assistant answers only from curated handbook content, quick cards, inventory, checklists, and user notes.
3. **Optional online enrichment**: when connected, the app can retrieve trusted external knowledge and persist approved content locally with provenance.
4. **Private by default**: user inventory, notes, prompts, and local knowledge remain on device unless a future feature explicitly adds sync/export.
5. **Calm emergency UX**: the app should be usable under stress, with fast access to quick cards, citations, and offline status.
6. **Single-developer practicality**: documentation should be thorough but lean enough for one developer or a very small team.

## Assumed technical direction

Unless the repo already establishes something else, assume:
- Native iOS app
- SwiftUI UI layer
- Local persistence via SwiftData or Core Data (recommend one and justify it)
- Local search/indexing over handbook content and app data
- Prefer Apple Foundation Models on supported devices; document fallback strategy if unsupported or unavailable
- Network awareness and sync/refresh behavior designed explicitly for intermittent connectivity
- Background-safe download/update approach for knowledge refreshes

Where you are uncertain, document options, recommendation, tradeoffs, and open questions.

## Deliverables

Create the following markdown documents under `/docs`.

### Required file structure
- `/docs/00-doc-suite-index.md`
- `/docs/01-problem-brief.md`
- `/docs/02-prd.md`
- `/docs/03-mvp-scope-roadmap.md`
- `/docs/04-information-architecture-and-ux-flows.md`
- `/docs/05-technical-architecture.md`
- `/docs/06-data-model-local-storage.md`
- `/docs/07-sync-connectivity-and-web-knowledge-refresh.md`
- `/docs/08-ai-assistant-retrieval-and-guardrails.md`
- `/docs/09-content-model-editorial-guidelines.md`
- `/docs/10-security-privacy-and-safety.md`
- `/docs/11-quality-strategy-test-plan-and-acceptance.md`
- `/docs/12-release-readiness-and-app-store-plan.md`
- `/docs/adr/ADR-0001-offline-first-local-first.md`
- `/docs/adr/ADR-0002-grounded-assistant-only.md`
- `/docs/adr/ADR-0003-online-knowledge-refresh-with-local-persistence.md`
- `/docs/risk-register.md`

If the repo already contains docs, preserve them and integrate rather than overwrite blindly.

## What each document must cover

### `/docs/00-doc-suite-index.md`
Create a document map for the whole suite.
Include:
- purpose of the suite
- file list and one-line description of each file
- reading order
- current status of each doc
- open questions summary
- decision log summary

### `/docs/01-problem-brief.md`
Define the product at a high level.
Include:
- problem statement
- target user(s)
- why this product exists
- anniversary-gift / personal-product context as background only
- product vision
- constraints
- non-goals
- success criteria
- major risks

### `/docs/02-prd.md`
Write a practical PRD.
Include:
- product summary
- user personas
- user jobs-to-be-done
- key user stories
- functional requirements
- non-functional requirements
- offline requirements
- online/web requirements
- AI requirements
- content-safety requirements
- data/privacy requirements
- out-of-scope list
- release goals

Be explicit that core offline features include:
- browsing handbook content
- searching local content
- using the local Ask feature over local data
- viewing quick cards
- viewing and editing inventory
- viewing and editing checklists
- personal notes

Be explicit that online-only or online-enhanced features may include:
- external web search
- source ingestion / knowledge refresh
- remote content updates
- future backup/sync

### `/docs/03-mvp-scope-roadmap.md`
Define MVP and phased delivery.
Include:
- v1 MVP scope
- v1.1 enhancements
- future stretch ideas
- what is deferred
- implementation sequencing
- milestone-based roadmap
- dependency map

### `/docs/04-information-architecture-and-ux-flows.md`
Describe the user experience.
Include:
- app navigation model
- top-level screens
- emergency-first shortcuts
- offline/online state handling in UI
- zero-state / empty-state behavior
- key user flows
- wireframe-level descriptions
- major UI states

Required top-level screens:
- Home
- Library
- Ask
- Inventory
- Checklists
- Quick Cards
- Personal Notes
- Settings

Include key flows for:
- first launch and setup
- offline question asking
- inventory add/edit/search
- checklist completion
- opening emergency quick cards under stress
- online knowledge refresh
- handling no connectivity gracefully

### `/docs/05-technical-architecture.md`
Create the system architecture spec.
Include:
- architecture overview
- component breakdown
- module boundaries
- local knowledge store architecture
- search/retrieval pipeline
- inference/model abstraction layer
- sync/update architecture
- content ingestion pipeline
- trust boundaries
- recommended tech choices with tradeoffs
- diagrams in Mermaid where useful

Include at least these architectural decisions/options:
- Foundation Models on supported devices vs bundled local model fallback
- SwiftData vs Core Data
- local document chunking/indexing approach
- whether embeddings are needed for v1 or keyword + metadata search is sufficient
- background refresh/update model

### `/docs/06-data-model-local-storage.md`
Define the local data layer.
Include:
- entities and relationships
- storage strategy
- schema for handbook chapters, sections, quick cards, inventory items, checklist templates, checklist runs, notes, sources, ingested knowledge, citations, AI sessions, and settings
- local file/storage layout
- migration strategy
- backup/restore considerations
- seed data strategy

Also define required metadata for imported knowledge:
- source title
- source URL
- publisher/domain
- fetched timestamp
- last-reviewed timestamp
- content hash
- trust level
- tags
- local chunk IDs

### `/docs/07-sync-connectivity-and-web-knowledge-refresh.md`
This is a first-class document.
Include:
- offline-first principles
- connectivity detection strategy
- queueing/retry behavior
- what happens when the app goes online/offline mid-task
- trusted web source policy
- user approval model for importing knowledge
- storage of imported knowledge locally
- deduplication/versioning
- stale-content rules
- sync conflict rules
- background refresh behavior
- telemetry/logging boundaries

Be explicit that imported or refreshed knowledge must become locally available for future offline use.

Define at least these online flows:
- user asks a question not answerable from local data and chooses to search online
- app retrieves candidate sources
- app summarizes/imports selected source material
- imported material is normalized, attributed, chunked, indexed, and persisted locally
- future offline answers can cite that locally stored source material

### `/docs/08-ai-assistant-retrieval-and-guardrails.md`
Define the local assistant.
Include:
- assistant scope
- allowed tasks
- disallowed tasks
- retrieval flow
- answer format
- citation rules
- confidence / fallback behavior
- prompt/policy design
- model abstraction layer
- support matrix for device/model availability
- performance constraints
- evaluation criteria

Required behavior:
- answer only from approved local sources
- cite local chapter/section/quick card/source records
- when not found locally, say so clearly
- optionally offer online search when connected
- never pretend to know unsupported information
- never answer outside scope as a general chatbot

Define guardrails for:
- high-risk medical content
- weapon/tactical content
- foraging/plant identification
- unsafe emergency improvisation
- hallucination prevention

### `/docs/09-content-model-editorial-guidelines.md`
Define how handbook content is authored.
Include:
- chapter template
- section template
- quick card template
- checklist template
- metadata/taxonomy
- writing style guide
- citation style
- review workflow
- update workflow
- safety-review rules

Include initial chapter map covering:
- preparedness foundations
- family plan and emergency contacts
- water
- food
- power outage
- cooking without power
- warmth/shelter
- first aid/hygiene/medications
- go-bags
- home supplies/utilities/tools
- local notes/maps/forest reference
- fire and lighting
- archery / longbow

For archery, scope content to safety, maintenance, inspection, storage, inventory, and practice logs only.

### `/docs/10-security-privacy-and-safety.md`
Create a combined security/privacy/product-safety doc.
Include:
- local data protection strategy
- network security assumptions
- secret handling
- permission model
- on-device privacy posture
- future sync/privacy implications
- product safety boundaries
- abuse/misuse considerations
- user disclosures
- App Store privacy note placeholders

Also define:
- what data stays on device
- what data may ever leave the device in online modes
- how imported web content is attributed
- what content categories require stricter controls or static-only handling

### `/docs/11-quality-strategy-test-plan-and-acceptance.md`
Define QA.
Include:
- test strategy by layer
- acceptance criteria
- offline test matrix
- online/offline transition test matrix
- performance tests
- storage/migration tests
- content-retrieval evaluation
- hallucination/failure tests
- safety regression tests
- manual QA scenarios
- device coverage assumptions

Must include explicit scenarios for:
- fully offline cold start
- degraded connectivity
- knowledge refresh interrupted mid-download
- missing/unsupported on-device model
- corrupted or stale local knowledge entries
- wrong or missing citations

### `/docs/12-release-readiness-and-app-store-plan.md`
Define launch readiness.
Include:
- pre-release checklist
- TestFlight plan
- release criteria
- privacy disclosures checklist
- content disclaimers
- crash/logging policy
- documentation handoff notes
- post-launch maintenance plan

### ADRs
Create these initial ADRs with status, context, decision, rationale, tradeoffs, and consequences.

#### `ADR-0001-offline-first-local-first.md`
Decision: the app is offline-first and all critical user workflows must function without connectivity.

#### `ADR-0002-grounded-assistant-only.md`
Decision: the assistant is not a general chatbot and may answer only from approved local sources and app data.

#### `ADR-0003-online-knowledge-refresh-with-local-persistence.md`
Decision: when online, the app may retrieve trusted external knowledge, but only persisted, attributed, locally stored knowledge becomes part of the usable offline knowledge base.

### `/docs/risk-register.md`
Include:
- risk description
- category
- likelihood
- impact
- mitigation
- owner
- status

Must include risks around:
- unsupported device/model availability
- hallucinations or weak grounding
- stale imported knowledge
- content safety drift
- storage growth on device
- migration complexity
- background refresh fragility
- scope creep

## Documentation standards

Every document must:
- be specific to this project, not generic boilerplate
- distinguish confirmed facts, assumptions, recommendations, and open questions
- include cross-links to related docs
- include acceptance criteria or “done means” where relevant
- optimize for implementation usefulness
- be written in clear engineering English
- avoid fluff
- include next-step recommendations

## Working method

Follow this sequence:
1. Inspect the existing repo structure, README, package/project files, and any docs.
2. Infer the likely app architecture and constraints from what exists.
3. Create the `/docs` structure.
4. Draft `/docs/00-doc-suite-index.md` first so the suite has a map.
5. Draft the remaining documents in dependency order.
6. Add the ADRs and risk register.
7. Cross-link everything.
8. End by updating the suite index with completion status and unresolved questions.

## Final response format

After creating the documents, respond with:
- the list of created files
- the top 5 architectural decisions captured
- the top 5 open questions that still need human input
- recommended next implementation step after documentation

Do not produce placeholder-only shells. Produce substantive first drafts.
