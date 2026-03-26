# M5 App Store Materials

Date: 2026-03-26
Milestone: 5 — Release Readiness
Status: Draft for review

---

## App Identity

| Field | Value |
| --- | --- |
| App Name | Lantern |
| Subtitle | Offline Preparedness Handbook |
| Bundle ID | (to be confirmed at submission) |
| Primary Category | Reference |
| Secondary Category | Utilities |

---

## Short Description (30 words)

Lantern is an offline-first preparedness handbook for iPhone. Browse curated guides, quick cards, checklists, and inventory — and ask a grounded local assistant that cites its sources.

---

## Full Description (300 words max)

Lantern keeps essential preparedness knowledge on your device so it works when you need it most — even without a signal.

**Offline by design.** Lantern stores curated handbook chapters, quick cards, checklists, inventory, and personal notes directly on your iPhone. Every core feature works without an internet connection.

**Ask with confidence.** The grounded Ask assistant answers questions using only approved local sources and your own app data. Every answer includes citations so you can verify where information came from. When evidence is insufficient, Ask tells you clearly rather than guessing.

**Quick Cards for high-pressure moments.** Access concise, actionable reference cards from your home screen with minimal taps — designed for clarity under stress.

**Inventory and Checklists.** Track supplies, quantities, locations, and expiration dates. Browse curated checklist templates, start timed runs, and keep completion history on device.

**Notes that stay private.** Create personal notes, tag them by topic, and optionally link them to handbook sections or inventory items. Notes never leave your device.

**Trusted-source import.** When connected, search a curated set of trusted publishers — government agencies, university extensions, and vetted preparedness organizations — and import reviewed material for future offline use. Imported content retains full publisher attribution.

**No account required.** Lantern has no login, no analytics, and no cloud dependency. Your data stays on your device by default.

Built for Pacific Northwest preparedness but useful anywhere reliable offline reference matters.

---

## Keyword Candidates (100 characters)

```
preparedness,offline,handbook,emergency,checklist,inventory,survival,earthquake,first aid,reference
```

(99 characters including commas)

---

## App Review Notes

Lantern is an offline-first reference app. The following points may help during review:

1. **Offline-first behavior.** The app is fully functional without network access. All core screens — Home, Library, Ask, Quick Cards, Inventory, Checklists, Notes, Settings — render from local SwiftData persistence. No mandatory network call is required at launch or during normal use.

2. **Bounded Ask assistant.** The Ask feature is not a general chatbot. It retrieves evidence only from approved local sources (handbook chapters, quick cards, imported knowledge) and optionally from user notes (opt-in via Settings). It answers with citations or refuses when evidence is insufficient. Safety-sensitive topics (weapons, medical diagnosis, edible-plant identification) are blocked by `SensitivityPolicy` before reaching the model adapter.

3. **Foundation Models usage.** On supported devices (iOS 26+), Ask uses Apple Foundation Models via `FoundationModelAdapter` for on-device generation. The app compiles against the FoundationModels framework conditionally (`#if canImport(FoundationModels)`) and checks runtime availability via `DeviceCapabilityDetector`. On unsupported devices, Ask degrades to extractive or search-first behavior. No third-party AI APIs are used.

4. **Trusted-source import.** The app can fetch content only from an explicit allowlist of 15 HTTPS publishers defined in `TrustedSourceAllowlist`. Hosts are matched exactly — no wildcard or suffix rules. All fetches require HTTPS scheme, and the HTTP client validates status codes, Content-Type, and payload size before accepting a response. Imported content is normalized, chunked, indexed locally, and attributed to the original publisher before it becomes available to Ask.

5. **No hidden network calls.** In offline/local mode, the app makes zero network requests. Online features (trusted-source import, knowledge refresh) are user-initiated. `NWPathMonitorConnectivityService` observes connectivity state but does not transmit data.

---

## Privacy Disclosure Answers

| Question | Answer |
| --- | --- |
| Does any user content leave the device in normal use? | No. All user data (inventory, notes, checklists, Ask prompts and responses, AI session logs) is stored locally in the app container using SwiftData. |
| Are online queries user-initiated? | Yes. Trusted-source import and knowledge refresh are user-initiated HTTPS-only requests to allowlisted hosts. No background data transmission occurs in v1. |
| Are analytics or crash logs collected? | No. v1 includes no analytics SDK, no crash reporting service, and no remote telemetry. Local diagnostics remain on device. |
| Is a login or account required? | No. The app has no account system, no authentication, and no user-linked data collection. |
| What data types are collected? | None. Under Apple's App Privacy framework, Lantern declares "Data Not Collected" for all categories. |
| Are permissions requested? | No system permissions are requested in v1. No access to location, contacts, photos, camera, microphone, or notifications is required. |

---

## Content Disclaimers

The following disclaimers are recommended for in-app display and App Store metadata:

1. **Not emergency services.** Lantern is an informational reference tool. It is not a substitute for calling 911 or contacting emergency services.

2. **Not medical or legal advice.** Content is for general preparedness information only. It is not a substitute for professional medical, legal, or safety advice.

3. **Ask answers are bounded.** The Ask assistant answers only from approved local sources and may not cover every scenario. Users should verify critical information with authoritative sources.

4. **Imported content retains attribution.** Material imported from trusted publishers preserves source title, publisher domain, fetch timestamp, and trust level. Imported content may age over time and should be refreshed periodically.

---

## Age Rating Justification

| Rating | 4+ |
| --- | --- |
| Justification | The app contains no objectionable content, no user-generated public content, no social features, no in-app purchases, and no advertising. The Ask assistant is safety-bounded with explicit topic restrictions enforced by `SensitivityPolicy` and prompt-level override protection. Content covers general household preparedness (water, food, shelter, first aid basics, checklists) with safety-sensitive topics constrained to reviewed static material. |

---

## Source References

| Claim | Evidence |
| --- | --- |
| Allowlist has 15 publishers | `OSA/Networking/Clients/TrustedSourceAllowlist.swift` — tier1 (6) + tier2 (6) + tier3 (3) |
| Ask uses Foundation Models conditionally | `OSA/Assistant/ModelAdapters/FoundationModelAdapter.swift`, `DeviceCapabilityDetector.swift` |
| Safety policy blocks sensitive topics | `OSA/Assistant/Policy/SensitivityPolicy.swift` |
| Override protection in prompts | `OSA/Assistant/PromptShaping/GroundedPromptBuilder.swift:72` |
| No permissions requested | `project.yml` — no entitlements or Info.plist permission keys |
| All data local via SwiftData | `OSA/Persistence/SwiftData/` — 14 `@Model` classes |
