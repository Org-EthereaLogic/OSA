# Information Architecture And UX Flows

Status: Initial draft complete.  
Related docs: [PRD](./02-prd.md), [Technical Architecture](./05-technical-architecture.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md)

## Confirmed Facts

- The UX must work under both ordinary planning use and stress-state emergency use.
- Core functionality must remain useful offline.
- Required top-level screens are Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings.
- All top-level screens are now implemented with SwiftUI feature surfaces backed by repository and retrieval protocols through environment injection. The navigation shell uses 4 primary tabs (Home, Library, Ask, Inventory) plus a More section (Checklists, Quick Cards, Notes, Settings).

## Assumptions

- The first release is iPhone-only.
- The app will use SwiftUI navigation patterns and large-touch targets.
- The top-level destinations do not all need permanent bottom-tab slots as long as they remain first-class and easy to reach.

## Recommendations

- Make Home and Quick Cards the fastest routes under stress.
- Keep Ask useful but secondary to quick cards for immediate action scenarios.
- Use explicit offline status and local-source cues throughout the app.

## Open Questions

- ~~Should Checklists or Quick Cards get a permanent tab slot in v1?~~ **Resolved by implementation:** neither gets a permanent tab slot. Both live in the `More` section of the tab bar alongside Notes and Settings, consistent with the 4-primary-tab navigation pattern.
- Should first launch offer a guided setup for family contacts and core kits, or skip directly into content?
- How much customization should Home allow before launch?

## App Navigation Model

Recommended root model:

- Primary navigation shell with persistent access to `Home`, `Library`, `Ask`, `Inventory`, and a root overflow surface or route list for `Checklists`, `Quick Cards`, `Notes`, and `Settings`.
- Home acts as the launch screen and emergency-first dashboard.
- Global search entry from Home, Library, and Ask.
- A persistent offline/online status indicator in the navigation chrome or Home header.

This keeps the required screens first-class without overcrowding a five-slot tab bar.

## Top-Level Screens

### Home

- Launch surface.
- Shows offline status, top quick cards from the local repository, most important checklists, recent notes, and inventory reminders.
- Contains the fastest route to emergency quick cards.

### Library

- Chapter list, section view, topical search, and related links into quick cards and notes.

### Ask

- Bounded local assistant with citation-focused results, capability state, and navigation routing to source content. Optional online search offer planned for M4.

### Inventory

- Searchable list of supplies with categories, quantities, locations, expirations, and edit flows.

### Checklists

- Template list, active runs, completion history, and quick-start household checklists.

### Quick Cards

- High-priority large-type cards optimized for one-handed reading and low-light or stress use.

### Notes

- User-created notes and local references, optionally linked to handbook topics or inventory items.

### Settings

- Organized into focused sections: Preparedness Profile, Emergency Contacts, Accessibility & Feedback, Assistant, Connectivity, Knowledge Discovery, Privacy, and About.
- Model capability status, trusted-source preferences, privacy posture, Ask scope controls, accessibility toggles (large print, critical haptics), emergency contact management, connectivity status with inline callouts, and knowledge discovery controls.

## Emergency-First Shortcuts

Recommended v1 shortcuts:

- Home header card: `Open Quick Cards`
- pinned "urgent topics" row on Home
- one-tap access to recent or starred quick cards
- large-type quick card mode with no dense chrome
- future-ready space for widget or app shortcut support in v1.1

Under stress, the app should bias toward direct card opening and simple checklist launches rather than asking the user to search or chat.

## Offline And Online State Handling In UI

- Show current mode as `Offline`, `Online (constrained)`, `Online (usable)`, or `Refreshing` via `ConnectivityBadge` in the Home header.
- Connectivity state changes trigger inline `ConnectivityStatusCallout` notices on Home and Settings: offline and constrained notices persist until state improves; reconnection notices auto-dismiss after 4 seconds. All transitions respect `accessibilityReduceMotion`.
- Never gray out local features because network is unavailable.
- Online-only actions should remain visible but clearly labeled.
- When Ask lacks local evidence, the UX should say that plainly and optionally offer `Search trusted web sources` only if connected.
- During refresh, existing local content remains visible and usable.

## Zero-State And Empty-State Behavior

- Home zero state: show starter actions such as browse the handbook, pin a quick card, add first inventory item, and create the family plan note.
- Inventory zero state: suggest starter categories like water, food, power, first aid.
- Notes zero state: prompt the user to add emergency contacts, meeting points, or local reference notes.
- Checklists zero state: show starter templates rather than a blank page.
- Ask zero state: explain scope and encourage questions grounded in the handbook or personal data.

## Key User Flows

### First Launch And Setup

1. App presents `OnboardingFlowView` as a fullScreenCover (controlled by `UserProfileSettings.onboardingCompletedKey` via `@AppStorage`).
2. Onboarding introduces the offline-first preparedness concept and key app surfaces.
3. Bundled seed content is imported into the local store during `AppModelContainer.makeShared()`.
4. Offer optional lightweight setup:
   - add emergency contacts (family, ICE) via `EmergencyContactFormView`
   - create first inventory item
   - pin favorite quick cards
5. On completion, `onboardingCompleted` is set to `true` and the Home tab is shown.
6. Show that the app is usable offline immediately.
7. Skipped during UI testing (`UI-TESTING` launch argument forces onboarding completed).

### Offline Question Asking

1. User opens Ask while offline.
2. Ask screen states that it is using local content only.
3. User submits question.
4. App retrieves local evidence and returns:
   - cited answer
   - not found locally
   - blocked out-of-scope response
5. If not found locally and offline, UI offers search inside local library instead of online fallback.

### Inventory Add, Edit, And Search

1. User opens Inventory.
2. User taps add item, enters category, quantity, location, tags, and optional expiry.
3. Item appears immediately in the local list.
4. Search filters by name, tag, or location.
5. Edit updates are saved offline and reflected in Ask scope if enabled.

### Checklist Completion

1. User opens Checklists and selects a template.
2. User starts a run.
3. Run view shows compact checklist rows, progress state, and optional notes.
4. User completes items offline and exits.
5. Progress is preserved across relaunch and surfaced from Home if still active.

### Opening Emergency Quick Cards Under Stress

1. User launches app to Home.
2. User taps `Quick Cards` or a pinned urgent card.
3. App opens directly into large-type card mode.
4. Swipe or tap to related cards and deeper handbook content only if needed.

### Online Knowledge Refresh

1. User asks a question or opens a source-search feature while connected.
2. App explains local evidence is insufficient and offers trusted online search.
3. Candidate sources appear with trust and provenance cues.
4. User selects import.
5. App shows staged progress: downloading, normalizing, saving locally, indexing.
6. Once complete, the new source is available offline and citeable by Ask.

### Handling No Connectivity Gracefully

1. User starts an online action but loses connectivity.
2. App preserves local state and marks the task paused or retryable.
3. UI explains that local content is still available and the online task can resume later.

## Wireframe-Level Descriptions

### Home

- top header with app state and offline badge
- Spotlight section with segmented picker (Quick Cards / Feed tabs):
  - Quick Cards tab: randomized selection of 3 quick cards from the full local repository set on load and pull-to-refresh
  - Feed tab: top 5 most recent RSS-discovered articles sorted by publish date (lazy-loaded on first tab switch), with source host and publish date shown when available and article URLs opened through the system URL handler
- section for active checklist runs (loaded from checklist repository)
- section for inventory reminders (loaded from inventory repository, filtered by expiry)
- recent notes (loaded from notes repository)

### Library

- search field
- chapter list or topic clusters
- section view with headings, citations, and related quick cards

### Ask

- input composer
- capability and scope label such as `Local sources only`
- answer card with citations
- buttons for related quick cards or online trusted search when appropriate

### Inventory

- search and filter controls
- grouped list by category or location
- add/edit sheet

### Checklists

- template list
- active run cards
- completion history

### Quick Cards

- card carousel or stacked list
- category chips
- large-text action format

### Notes

- searchable notes list
- rich text or markdown-lite editor
- topic links

### Settings

- Preparedness Profile: region picker, household size stepper, hazard toggles
- Emergency Contacts: CRUD with I'm Safe shortcut integration
- Accessibility & Feedback: large print reading mode, critical haptics toggle
- Assistant: model capability status (live from `DeviceCapabilityDetector`), personal notes scope toggle
- Connectivity: inline status callout with connectivity state stream, reduce-motion-aware transitions
- Knowledge Discovery: Brave Search API key management, discover action with status feedback
- Privacy: data storage explanation, reset option
- About: version, branding

## Major UI States

- first launch importing seed content
- fully offline ready
- online idle
- online refresh in progress
- empty state for new users
- unsupported model capability
- blocked sensitive Ask request
- stale imported-source warning
- migration or reindex in progress after app update

## Done Means

- All required top-level screens are defined with clear roles.
- The stress-state and offline-state UX paths are explicit.
- Key flows are concrete enough to inform initial SwiftUI routing and view-model design.

## Next-Step Recommendations

1. ~~Convert these flows into low-fidelity wireframes before writing UI code.~~ **Done:** All core screens are implemented as SwiftUI views.
2. ~~Decide which destinations get permanent tab presence versus Home or overflow access.~~ **Resolved by implementation:** 4 primary tabs (Home, Library, Ask, Inventory) plus a More section for Checklists, Quick Cards, Notes, and Settings.
3. Prototype the Quick Cards large-type presentation early; it is central to the product identity.
