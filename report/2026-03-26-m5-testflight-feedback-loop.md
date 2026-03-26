# M5 TestFlight Feedback Loop

Date: 2026-03-26
Milestone: 5 — Release Readiness
Status: Draft for review

---

## Release Channel

TestFlight internal first, then limited trusted beta. No public TestFlight or App Store submission until all release criteria pass.

---

## Tester Stages

### Stage 1: Internal Technical Alpha

**Audience:** Developer and immediate technical reviewers (1-3 people).

**Focus areas:**
- Seed content import and local storage integrity
- SwiftData persistence and migration behavior across builds
- Retrieval pipeline correctness (query normalization, evidence ranking, citation generation)
- Trusted-source import end-to-end flow (fetch, normalize, chunk, persist, index)
- Cold-start behavior in airplane mode
- Foundation Models adapter availability detection and extractive fallback

**Feedback prompts:**
1. Does the app reach all core screens on a completely cold start in airplane mode?
2. After updating to a new TestFlight build, is all previously stored data (inventory, notes, checklists, imported knowledge) still intact?
3. Does Ask produce a cited answer for a query covered by seed content? Does the citation reference the correct source?
4. Does Ask clearly refuse or indicate "not found locally" for a query outside its scope?
5. Can you complete the trusted-source import flow end-to-end and then access the imported content offline after toggling airplane mode?
6. On a device without Foundation Models support, does Ask degrade to extractive or search-first behavior without crashing?
7. Are any unexpected network requests visible in the console during offline local use?

**Acceptance criteria:**
- All core screens render from local data without network dependency
- SwiftData migration preserves existing records across at least one build update
- Ask citations point to real local sources with correct titles and publisher attribution
- Ask refuses or returns "not found" for out-of-scope queries without hallucinating
- Imported knowledge is available offline after import completes
- No crashes on unsupported-model devices

---

### Stage 2: Limited Trusted Beta

**Audience:** 5-10 trusted non-technical testers (household members, preparedness-interested friends).

**Focus areas:**
- Stress-state UX clarity (can users find quick cards and key information under cognitive load?)
- Content quality and comprehensibility of handbook chapters and quick cards
- Stale-content cues and freshness indicators for imported knowledge
- Ask trustworthiness — do answers feel grounded and appropriately bounded?
- Inventory and checklist usability for real household preparedness workflows

**Feedback prompts:**
1. Were quick cards easy to find and read when you imagined being in a stressful situation?
2. Was any handbook content confusing, incomplete, or missing a topic you expected?
3. Did Ask ever give an answer that felt unsafe, overconfident, or vague?
4. Did Ask ever fail to answer something you thought it should know from the handbook?
5. Were inventory fields (quantity, location, expiration) sufficient for tracking your real supplies?
6. Was the checklist flow clear enough to complete a full run without confusion?
7. Did anything in the app make you question whether your data was being sent somewhere?

**Acceptance criteria:**
- Testers can locate quick cards from the home screen within 2 taps
- No tester reports feeling misled by an Ask answer
- No tester reports content they perceive as unsafe or irresponsible
- Inventory and checklist workflows are completable without developer assistance
- Privacy expectations match actual behavior (no surprises about data handling)

---

### Stage 3: Release Candidate

**Audience:** All prior testers plus 2-3 fresh eyes who have not seen the app before.

**Focus areas:**
- App Store text, disclosures, and metadata accuracy
- Final defect triage against release criteria
- First-run experience clarity (does a new user understand the app's purpose and boundaries?)
- Privacy label and content disclaimer accuracy against shipped build
- Edge cases: very large inventory lists, long notes, many imported sources

**Feedback prompts:**
1. After reading the App Store description, did the app match your expectations?
2. Was the app's purpose and scope clear within the first minute of use?
3. Did any disclaimer or privacy statement feel inaccurate or incomplete?
4. Did you encounter any crash, hang, or visual glitch?
5. Did the app feel fast enough on cold start and during normal navigation?

**Acceptance criteria:**
- App Store description accurately represents shipped functionality
- Privacy disclosures match observed behavior (no undisclosed network calls, no undisclosed data collection)
- No new high-severity defects discovered
- Cold start to home screen is acceptable on target devices
- Fresh testers understand the app's purpose without external explanation

---

## Triage Rubric

All feedback items are categorized using the following rubric before influencing release decisions.

### Release Blocker

**Definition:** A defect or gap that prevents the app from meeting a stated release criterion.

**Examples:**
- Core screen does not render offline
- Ask produces an answer without any citation
- Trusted-source import silently fails and loses fetched content
- Crash on launch or during a primary workflow
- Privacy disclosure contradicts shipped behavior

**Action:** Must be fixed before submission. Blocks the release.

### Release Risk

**Definition:** A significant issue that does not break a release criterion but materially degrades the user experience or trust.

**Examples:**
- Ask citation points to wrong source section
- Imported content display is confusing or missing attribution
- Checklist run state is lost after backgrounding
- Cold start takes noticeably long on supported devices

**Action:** Should be fixed before submission. Escalate to blocker if fix is infeasible within timeline.

### Post-Launch Backlog

**Definition:** A defect or gap that is real but does not affect release criteria or core trust.

**Examples:**
- Minor visual inconsistency on specific screen size
- Handbook section ordering is suboptimal
- Search results ranking could be improved
- Settings screen layout is functional but unpolished

**Action:** Log in issue tracker. Fix in next update cycle.

### Enhancement Request

**Definition:** A feature or improvement that is out of current scope.

**Examples:**
- Request for iPad support
- Request for cloud backup
- Request for additional trusted sources
- Request for notification reminders on expiring inventory

**Action:** Log as feature request. Evaluate for future milestone.

---

## Triage Category to Release Criteria Mapping

| Triage Category | Mapped Release Criteria |
| --- | --- |
| Release Blocker | RC-1: No open high-severity defects affecting offline core flows |
| Release Blocker | RC-2: No open high-severity privacy or safety issues |
| Release Blocker | RC-3: Ask passes citation and refusal regression suite |
| Release Blocker | RC-4: Imported-source flow works end to end and remains available offline |
| Release Blocker | RC-6: App Store privacy answers match shipped behavior |
| Release Risk | RC-5: App size, cold start, and local performance are acceptable |
| Release Risk | RC-3 (partial): Citation correctness edge cases |
| Post-Launch Backlog | None — does not map to release criteria by definition |
| Enhancement Request | None — out of current scope by definition |

---

## Feedback Collection Method

### Primary: TestFlight In-App Feedback

Testers use the built-in TestFlight screenshot-and-feedback mechanism for:
- Bug reports with device context and screenshots
- Free-form observations during use

### Secondary: Structured Feedback Form

A structured Google Form or Notion database collects responses to the stage-specific feedback prompts above. This provides:
- Consistent data across testers
- Quantifiable responses for acceptance criteria evaluation
- Written record for release sign-off evidence

**Form structure per stage:**
- Tester name/identifier
- TestFlight build number
- Device model and iOS version
- Responses to each feedback prompt (rating + free text)
- Overall confidence rating: "Ready to ship" / "Needs fixes" / "Needs significant work"
- Free-form comments

### Triage Workflow

1. All feedback items are collected into a single triage list after each stage completes.
2. Each item is assigned a triage category (Blocker / Risk / Backlog / Enhancement).
3. Blockers and Risks are mapped to their release criterion.
4. Blockers must be resolved and re-verified before advancing to the next stage.
5. Risks are evaluated for fix feasibility within the release timeline.
6. The triage list serves as evidence input for the release readiness report.

---

## Source References

| Claim | Evidence |
| --- | --- |
| Three-stage TestFlight plan | `docs/sdlc/12-release-readiness-and-app-store-plan.md` lines 41-48 |
| Six release criteria | `docs/sdlc/12-release-readiness-and-app-store-plan.md` lines 59-64 |
| Privacy disclosures checklist | `docs/sdlc/12-release-readiness-and-app-store-plan.md` lines 68-73 |
| Content disclaimers | `docs/sdlc/12-release-readiness-and-app-store-plan.md` lines 76-81 |
| Safety boundaries | `docs/sdlc/10-security-privacy-and-safety.md` lines 107-123 |
| Core feature surfaces | `docs/sdlc/02-prd.md` lines 8-9 |
