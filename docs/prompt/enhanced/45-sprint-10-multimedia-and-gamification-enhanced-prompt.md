Developer: # Sprint 10 Multimedia And Gamification Enhanced Prompt

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** Sprint 10 extends the existing seed-content, quick-card, field-reference, Home, and local-persistence seams with bundled media, quiz definitions, weekly-drill surfacing, and local progress tracking. The work spans multiple domain, persistence, resource, UI, and test files while preserving offline-first behavior and strict separation between editorial content and user state.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 10 must add multimedia and gamification to local content: inline SVG illustrations, short-form videos, knot references, quiz modes, completion badges, a weekly drill card, and illustrated first-aid procedures. |
| `AGENTS.md` | Use Plan -> Act -> Verify -> Report, keep feature, domain, persistence, retrieval, and networking boundaries intact, and mark blocked verification as `unverified`. |
| `DIRECTIVES.md` | Keep the app offline-first, keep the assistant grounded and cited, preserve editorial versus user-state separation, and back verification claims with explicit evidence. |
| `.github/instructions/codacy.instructions.md` | Repository is `Org-EthereaLogic/OSA`; Codacy MCP analysis is expected when tooling is available. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Home, Library, Quick Cards, and existing tag-driven browse/search flows are the correct user-facing seams; do not add a new top-level destination for Sprint 10. |
| `docs/sdlc/05-technical-architecture.md` | Quick cards, field references, seed import, and local search already exist as first-class local seams; new behavior should extend them rather than creating a parallel content system. |
| `docs/sdlc/09-content-model-editorial-guidelines.md` | Sensitive content must remain concise, reviewed, static, citation-friendly, and tagged consistently; infographic-style cards should stay in the quick-card model when possible. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Media and practice features must remain device-local by default, avoid secret or network creep, and keep first-aid guidance conservative and escalation-aware. |
| `OSA/Domain/Content/Models/QuickCard.swift` | Quick cards already support `largeTypeLayoutVersion`, making them the preferred home for media-rich drill and quiz content. |
| `OSA/Domain/Content/Models/FieldReference.swift` | Field references already provide structured categorized content and are the right place for knot references and illustrated first-aid procedures. |
| `OSA/Persistence/SeedImport/SeedContentLoader.swift` | Seed packs already support handbook, quick cards, checklist templates, and field references with hash and cross-reference validation; Sprint 10 should extend this loader instead of bypassing it. |
| `OSA/Features/QuickCards/QuickCardDetailView.swift` | The detail surface already supports infographic layout variants but has no media or quiz rendering yet. |
| `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Home/HomeSectionViews.swift` | Home already composes bounded sections, so the weekly drill and earned-badge summary should be added as another local dashboard slice. |
| `OSA/Features/Library/SearchResultsView.swift` | Search already routes field references and quick cards; badges and drills should reuse existing content destinations instead of adding a new search kind. |

## Classification Summary

- Core intent: add bounded offline multimedia and local practice mechanics to existing editorial content so OSA becomes more instructive and habit-forming without widening into streaming media, social gamification, or general chat.
- In scope: bundled SVG illustrations, bundled short-form local videos, knot-reference content, illustrated first-aid procedures, quiz definitions and quiz UI, local-only completion state, derived completion badges, a weekly drill surfaced on Home, seed-pack/schema updates, and focused tests.
- Out of scope: streaming video, remote content delivery, social sharing, leaderboards, cloud sync, push-driven streak systems, general-purpose course authoring, or widening medical/tactical scope beyond documented safety rules.

## Mission Statement

Implement Sprint 10 by extending OSA's existing local quick-card and field-reference system with bundled offline media, quiz-driven practice flows, a weekly drill surface, and derived completion badges while keeping editorial seed content and user progress strictly separated.

## Technical Context

Sprint 9 already delivered two key foundations that Sprint 10 must reuse rather than replace:

1. `QuickCard` already supports infographic presentation through `largeTypeLayoutVersion`, and `QuickCardDetailView` already renders a special large-type panel layout.
2. `FieldReferenceEntry` is already a first-class local content type with repository, search, route, and detail-view support.

What does *not* exist yet is equally important:

- there is no current `WebKit` or `AVKit` surface for SVG or video playback
- there is no quiz or achievement model in the domain layer
- there is no local progress repository for practice state
- there is no weekly-drill selection or completion logic on Home

The smallest coherent Sprint 10 design is therefore:

1. Keep **media and practice definitions inside existing editorial content** by extending `QuickCard` and `FieldReferenceEntry` with optional local media attachments and optional quiz definitions.
2. Keep **user progress separate from editorial seed content** by introducing a small local progress repository for quiz completion and weekly-drill completion data.
3. Keep **weekly drill** as a derived Home surface backed by tagged or explicitly flagged quick cards rather than inventing a new top-level content type.
4. Keep **completion badges derived from local progress** unless persistence of badge history becomes strictly necessary. Prefer derivation over a separate badge store.
5. Keep **media offline-only** by using bundled SVG and bundled MP4 assets referenced by local identifiers. No remote URLs, no streaming, and no live embeds.

**Rationale:** this approach preserves the current architecture, minimizes new persistence surfaces, keeps search and citations tied to existing content records, and prevents the multimedia/gamification request from drifting into a new product mode.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| SVG illustrations | No local SVG rendering seam exists. | Quick cards and field references can render bundled inline SVG illustrations with captions and accessibility labels. |
| Short-form videos | No local video-player surface exists. | Selected quick cards and field references can optionally show short bundled local videos with captions, transcript fallback, and no network dependency. |
| Knot reference | Field references exist, but no dedicated knot-reference section is shipped. | Field references include a dedicated knot-reference category or entry set with structured steps and illustrations. |
| First-aid illustrations | First-aid references are text-only. | First-aid procedures can show bounded illustrated steps while remaining static, conservative, and non-diagnostic. |
| Quiz mode | No question/answer or scoring flow exists. | Quick cards and field references can launch a local quiz flow with deterministic scoring and explanation text. |
| Completion badges | No completion or mastery affordance exists. | Home and detail views can show locally derived badges based on quiz mastery and weekly-drill completion. |
| Weekly drill | Home does not surface a rotating practice assignment. | Home presents one weekly drill card derived from eligible quick cards and tracks local completion for the current week. |
| Data boundaries | Editorial content is seed-backed; user progress for media/practice does not exist. | Editorial content remains seed-backed while quiz scores and drill completion live in separate local user-state persistence. |

## Pre-Flight Checks

1. Verify the current editorial and UI seams that Sprint 10 must extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Domain/Content/Models/QuickCard.swift && test -f OSA/Domain/Content/Models/FieldReference.swift && test -f OSA/Persistence/SeedImport/SeedContentLoader.swift && test -f OSA/Features/QuickCards/QuickCardDetailView.swift && test -f OSA/Features/Home/HomeScreen.swift && echo "sprint-10 seams present"
   ```

   *Success: the command prints `sprint-10 seams present`.*

2. Verify the current repo has no SVG/video/quiz implementation so Sprint 10 stays additive and explicit.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "import WebKit|WKWebView|import AVKit|AVPlayer|VideoPlayer|quiz|achievement|weekly drill" OSA
   ```

   *Success: either no matches are returned for media/player code, or the exact existing seams are identified and reused intentionally.*

3. Verify the seed content inventory that Sprint 10 will extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && ls OSA/Resources/SeedContent && sed -n '1,120p' OSA/Resources/SeedContent/SeedManifest.json
   ```

   *Success: the listing shows current handbook, quick-card, and field-reference packs, and the manifest confirms the existing local seed-pack structure.*

4. Verify the current infographic and field-reference routing seams that should carry Sprint 10 content.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "largeTypeLayoutVersion|FieldReferenceRouteView|FieldReferenceDetailView|QuickCardInfographicLayout" OSA
   ```

   *Success: matches show that infographic quick-card rendering and field-reference navigation already exist and can be extended rather than duplicated.*

## Phased Instructions

### Phase 1: Freeze The Smallest Coherent Sprint 10 Design

1. Keep multimedia attached to existing editorial content types.

   Extend `QuickCard` and `FieldReferenceEntry` with optional local media and quiz metadata instead of creating a new content repository for videos, drills, or badges.

   *Success: the implementation plan names only existing editorial seams plus a small new progress seam, not a new media subsystem.*

2. Keep user progress separate from seed-backed editorial content.

   Define a dedicated local progress seam for quiz attempts and weekly-drill completion. Do not store quiz results, badge state, or weekly-drill completion inside seed JSON records or editorial SwiftData entities.

   *Success: editorial records remain immutable content, and user progress is modeled as separate local state.*

3. Freeze the local-only media policy before editing UI code.

   Permit only bundled SVG and bundled local video files referenced by app-owned asset names or bundle-relative paths. Forbid remote URLs, embedded web players, streaming manifests, analytics beacons, and autoplay audio.

   *Success: the implementation can describe exactly where media assets live and can prove they remain offline-capable.*

4. Keep the weekly drill as a Home extension, not a navigation redesign.

   Reuse `HomeScreen.swift` and `HomeSectionViews.swift` for a bounded weekly-drill section that points into existing quick-card or field-reference detail routes.

   *Success: no new top-level tab, modal flow hub, or separate drill dashboard is required.*

### Phase 2: Extend Domain Models And Local Progress Contracts

1. Add shared multimedia and quiz value types under `OSA/Domain/Content/Models/`.

   Create a focused model file such as `ContentEnhancementModels.swift` that defines the smallest needed supporting types, for example:

   - `LocalMediaAttachment`
   - `LocalMediaKind` (`inlineSVG`, `shortVideo`)
   - `QuizDefinition`
   - `QuizQuestion`
   - `QuizOption`
   - `WeeklyDrillMetadata`

   Keep them immutable, `Codable` when needed for seed decoding, and `Equatable`/`Sendable`.

   *Success: the seed loader and UI can reference concrete typed metadata instead of loosely typed dictionaries.*

2. Extend `OSA/Domain/Content/Models/QuickCard.swift` and `OSA/Domain/Content/Models/FieldReference.swift`.

   Add optional properties for:

   - bundled media attachments
   - optional quiz definition
   - optional weekly-drill eligibility or metadata on quick cards

   Keep knot references and illustrated first-aid procedures inside `FieldReferenceEntry`, not as a separate editorial type.

   *Success: existing quick-card and field-reference records can carry Sprint 10 enhancements without changing their identity model.*

3. Add a dedicated local progress repository contract under `OSA/Domain/`.

   Preferred shape:

   - `OSA/Domain/Practice/Models/PracticeProgressModels.swift`
   - `OSA/Domain/Practice/Repositories/PracticeProgressRepository.swift`

   Minimum tracked state:

   - best quiz score per content item
   - quiz completion timestamp
   - weekly-drill completion keyed by ISO week or explicit week token

   Derive completion badges from that state first; only persist badges separately if derivation becomes insufficient.

   *Success: quiz progress, mastery, and weekly-drill completion have an explicit domain contract that does not leak SwiftData into features.*

4. Keep search kinds unchanged unless a new browseable first-class record truly exists.

   Do not add `SearchResultKind.badge`, `SearchResultKind.quiz`, or `SearchResultKind.weeklyDrill`. Continue routing users to quick-card and field-reference destinations.

   *Success: search continues to expose content, not transient progress artifacts.*

### Phase 3: Extend Seed Import, Persistence, And Resource Packaging

1. Extend `OSA/Domain/Content/Models/SeedContentModels.swift` and `OSA/Persistence/SeedImport/SeedContentLoader.swift` for the new content metadata.

   Update the seed pack decoding so quick cards and field references can decode multimedia attachments, quiz definitions, and weekly-drill metadata while preserving current content-hash and record-count validation.

   *Success: the loader accepts the new schema additions and still fails fast on malformed pack data.*

2. Preserve the current editorial-content persistence boundary in `OSA/Persistence/SwiftData/Repositories/SwiftDataContentRepository.swift`.

   Extend existing persisted quick-card and field-reference models only as needed to hold the new seed-backed editorial metadata. Do not mix user quiz progress or badge state into the same persisted records.

   *Success: seed upsert remains deterministic, and editorial records remain distinct from local user-progress records.*

3. Add a dedicated SwiftData persistence slice for user progress.

   Preferred shape:

   - `OSA/Persistence/SwiftData/Models/PersistedPracticeProgress.swift`
   - `OSA/Persistence/SwiftData/Repositories/SwiftDataPracticeProgressRepository.swift`

   Store only local progress data needed for Sprint 10. Do not introduce cloud sync, sharing, or analytics hooks.

   *Success: practice state survives relaunch and remains device-local.*

4. Add bundled media assets under `OSA/Resources/` using clear subfolders.

   Recommended layout:

   - `OSA/Resources/Media/Illustrations/*.svg`
   - `OSA/Resources/Media/Videos/*.mp4`
   - optional poster or transcript sidecars only if the chosen player needs them

   Keep asset names stable and reference them from seed content by identifier.

   *Success: every new media attachment resolves to a bundled local asset with no remote fallback path.*

5. Update `OSA/Resources/SeedContent/SeedManifest.json` and the relevant seed pack files.

   Minimum expected updates:

   - extend existing quick-card pack records with media and quiz metadata
   - extend `field-references-core-v1.json` with knot-reference entries and illustrated first-aid entries
   - bump content-pack version and hashes

   If you add resource folders outside the current XcodeGen resource glob, update `project.yml` and run `xcodegen generate` immediately.

   *Success: manifest counts and hashes match the shipped pack files, and any new resource folders are included by the app target.*

6. Extend search indexing only where discoverability would otherwise regress.

   Ensure search indexing includes quiz prompt text, illustration captions, and video transcript text only when those fields materially improve local discoverability. Do not create a separate search index for media assets.

   *Success: a user can still find knot references or illustrated first-aid procedures through the existing search system.*

### Phase 4: Add The Multimedia And Practice UI

1. Add a bounded SVG rendering component in `OSA/Shared/Components/`.

   Create a view such as `LocalSVGIllustrationView.swift` that renders bundled app-owned SVG content only. Prefer a dependency-free implementation using a locked-down `WKWebView` wrapper or an equivalent system-only approach. Disable navigation, scripting, and remote loads.

   *Success: SVG illustrations render inline from bundled assets and cannot navigate or fetch network content.*

2. Add a bounded local video component in `OSA/Shared/Components/`.

   Create a view such as `LocalVideoPlayerView.swift` using `AVKit` for bundled local files only. Provide a static caption or transcript fallback and avoid autoplay with sound.

   *Success: short-form videos can be played offline from local assets with accessible fallback text.*

3. Update `OSA/Features/QuickCards/QuickCardDetailView.swift`.

   Render optional media attachments above or alongside the existing infographic/text content. Add a quiz entry point, quiz-completion state, and badge summary without obscuring the card's primary emergency-reading function.

   *Success: a quick card can show illustration/video content and launch a local quiz while remaining readable under stress.*

4. Update `OSA/Features/Library/FieldReferenceDetailView.swift` and related route/category views.

   Render knot-reference diagrams and illustrated first-aid procedures using the same shared media components. Keep the field-reference layout concise and category-aware.

   *Success: knot and first-aid references appear through the existing field-reference browse flow with illustrations and optional quiz CTA.*

5. Add the cross-content quiz UI in a bounded shared feature surface.

   Preferred shape:

   - `OSA/Features/Practice/QuizSessionView.swift`
   - `OSA/Features/Practice/CompletionBadgeStripView.swift`

   The quiz flow should use deterministic local scoring, explanation text from seed content, and repository-backed completion updates.

   *Success: both quick cards and field references can present a consistent local quiz flow without duplicated UI logic.*

6. Add the weekly-drill surface to Home.

   Update `OSA/Features/Home/HomeScreen.swift` and `OSA/Features/Home/HomeSectionViews.swift` to derive one weekly drill from eligible quick cards, show completion state for the current week, and route into the underlying quick-card detail.

   *Success: Home shows a single local weekly drill card with completion state and no new navigation destination.*

7. Surface badges conservatively.

   Show derived completion badges only where they reinforce learning without crowding emergency content. Preferred placements are the weekly-drill section on Home and a compact badge strip in quick-card or field-reference detail.

   *Success: badges exist as lightweight feedback, not as a dominant gamification layer.*

### Phase 5: Author The Sprint 10 Seed Corpus

1. Add a knot-reference slice to `field-references-core-v1.json`.

   Introduce a dedicated rope-and-knots section or category with a bounded starter set such as square knot, bowline, clove hitch, and trucker's hitch. Each entry should include plain-language use case, do-not-use cautions, and one or more bundled illustrations.

   *Success: knot references are structured, searchable, and illustrative without becoming a general outdoor-skills expansion.*

2. Add illustrated first-aid procedure content to `field-references-core-v1.json` and, where needed, related handbook references.

   Keep content static, conservative, reviewed, and escalation-aware. Focus on bounded procedures such as wound dressing, splint stabilization basics, burn cooling boundaries, or recovery-position reminders only if already within the repo's documented safety scope.

   *Success: first-aid procedure content remains static, cited, and non-diagnostic while gaining illustration support.*

3. Add multimedia-backed quick cards for drill and quiz use.

   Extend the relevant quick-card pack files with:

   - bundled SVG illustrations
   - optional local short-form videos
   - quiz questions and explanations
   - weekly-drill metadata for the eligible cards

   *Success: at least one weekly-drill-capable quick card and one knot or first-aid quick-learning card can be exercised end-to-end.*

4. Add transcripts, captions, and accessibility metadata for all new media.

   Every SVG and video asset should have a human-readable label, and every video should have transcript or caption text available locally for search and accessibility.

   *Success: the media layer remains accessible and searchable without relying on playback alone.*

### Phase 6: Add Focused Tests And Execute Verification

1. Extend seed-content tests first.

   Update or add focused tests in:

   - `OSATests/SeedContentRepositoryTests.swift`
   - `OSATests/SeedContentMigrationTests.swift`
   - `OSATests/SearchIndexRebuilderTests.swift`

   Cover at minimum:

   - decoding of media and quiz metadata
   - missing-asset or malformed-reference failure behavior
   - manifest hash/count updates
   - index coverage for captions or transcripts when included

   *Success: malformed Sprint 10 content fails in tests instead of surfacing only at runtime.*

2. Add focused repository and progress tests.

   Add a new test file such as `OSATests/PracticeProgressRepositoryTests.swift` for quiz and weekly-drill persistence, plus any focused content-repository tests needed for the new editorial metadata.

   *Success: local progress state is covered by deterministic repository tests.*

3. Add targeted UI or feature tests for the new surfaces.

   Extend the smallest relevant UI tests, likely:

   - `OSATests/OSAContentAndInputTests.swift`
   - `OSATests/OSAFullE2EVisualTests.swift`

   Verify the weekly drill card, knot-reference detail, illustrated first-aid detail, and quiz entry flow.

   *Success: the user can reach the new Sprint 10 surfaces through Home or Library without regressions.*

4. Run the narrowest relevant tests before broad validation.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/SeedContentRepositoryTests -only-testing:OSATests/SeedContentMigrationTests -only-testing:OSATests/SearchIndexRebuilderTests -only-testing:OSATests/PracticeProgressRepositoryTests
   ```

   *Success: the focused seed and local-progress tests pass, or the failure maps directly to the edited Sprint 10 slice.*

5. Run broader build and test validation for the touched surfaces.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```

   *Success: the app builds and the relevant test suite passes, or any Xcode/environment blocker is reported verbatim as `unverified`.*

6. Run the required first-party security scan if Swift or configuration files changed.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
   ```

   *Success: the scan completes without new issues, or the exact tooling blocker is reported if `snyk` is unavailable.*

## Guardrails

- Do not add remote media URLs, streaming services, embedded web players, or analytics.
- Do not create a second editorial-content architecture for quizzes, drills, or badges when the existing quick-card and field-reference seams are sufficient.
- Do not mix quiz or badge progress into seed-backed editorial entities.
- Do not add a new top-level tab, course hub, or social profile surface.
- Do not widen first-aid scope into diagnosis, dosage, or personalized medical advice.
- Do not widen knot content into a broad wilderness-survival curriculum beyond the bounded reference use case requested.
- Do not introduce third-party SVG or video dependencies unless the system-only approach is proven insufficient and the justification is written explicitly.
- Do not make Home or Quick Card emergency reading flows dependent on finishing quizzes or watching videos.

## Verification Checklist

- [ ] Quick cards and field references can decode optional media and quiz metadata from seed packs.
- [ ] Bundled SVG illustrations render offline with accessibility labels and no network path.
- [ ] Bundled short-form videos play offline with transcript or caption fallback.
- [ ] Field references now include a knot-reference slice and illustrated first-aid procedures.
- [ ] Quick cards can launch a deterministic local quiz flow.
- [ ] Weekly drill appears on Home and routes into existing content detail.
- [ ] Completion badges are derived from local progress and do not require a new search or navigation model.
- [ ] Editorial content and user progress persist through separate local seams.
- [ ] Focused seed, progress, and UI tests pass.
- [ ] `xcodebuild` verification is run or blocked status is reported precisely.
- [ ] `snyk code test --path="$PWD"` is run or blocked status is reported precisely.

## Error Handling And Verification Reporting

Use this table together with `## Verification Checklist` as a strict reporting contract: every verification or tool command you attempt or plan to rely on must be reported per command with an explicit outcome of `passed`, `failed`, or `unverified`, plus the exact blocker or failure text when applicable. Do not present planned work as executed work. Any claim about shipped behavior, completed fixes, or verification must be backed by file, test, or tool evidence, or explicitly marked `unverified`. If repository seams differ from expectations, freeze scope at the nearest existing seam, avoid inventing parallel architecture, and note the adaptation briefly before coding or reporting. Keep reporting concise: focus on concrete changes, evidence, and remaining gaps rather than re-explaining architecture already established elsewhere.

| Error Condition | Resolution |
| --- | --- |
| SVG rendering is visually incorrect or too heavy in the chosen view wrapper | Fall back to a stricter system-only renderer path or a pre-rendered bounded asset fallback while keeping the same local attachment model and accessibility text. Report which renderer path was actually shipped, and mark visual correctness as `unverified` if you could not validate it in the target runtime. |
| Bundled video assets cause app-size or build-time pressure | Reduce clip count/length, use poster-plus-transcript fallback for lower-value clips, and keep the same editorial references so the UX remains coherent. If size or build impact was not measured with available tooling, report that verification as `unverified` rather than implied complete. |
| Seed loader fails because media references point to missing bundle assets | Add explicit loader or repository validation for asset existence and block import until the referenced files and manifest hashes are corrected. Report the validation command or check outcome per command, including exact missing-asset blocker text when unavailable or failing. |
| Quiz progress persistence introduces schema or migration issues | Keep the progress schema minimal, add migration coverage immediately, and derive badges from progress instead of persisting extra achievement records. Do not claim persistence is complete without migration or test evidence; otherwise mark it `unverified`. |
| Weekly drill selection feels unstable or non-deterministic across launches | Key drill selection to ISO week and stable content IDs so the chosen drill remains deterministic for the same week. If determinism was reasoned about but not exercised with tests or runtime checks, report that verification as `unverified`. |
| `project.yml` must change to include new media folders | Run `xcodegen generate` immediately after the change and treat the generated `OSA.xcodeproj` update as part of the same verification slice. Report the exact command and its outcome as `passed`, `failed`, or `unverified`. |
| `xcodebuild` cannot run because full Xcode is unavailable | Report the exact command and failure mode as `unverified`; do not claim build or test success. |
| `snyk` is unavailable | Report the exact missing-tool blocker as `unverified`; do not claim a completed security scan. |

## Out Of Scope

- Streaming or remote-hosted video delivery
- Social sharing of quiz scores or badges
- Push-driven streak systems or habit notifications
- Backend sync, account profiles, or cloud persistence for progress
- User-authored quiz creation or general-purpose authoring tools
- Expansion into broader survival instruction categories beyond the requested knot, first-aid, and practice surfaces
- General-chat or assistant-behavior changes unrelated to citing local content

## Alternative Solutions

1. **Poster-plus-transcript fallback for videos:** if bundled MP4 clips add too much size or complexity, keep the same content model but ship poster imagery plus transcript text only. Pros: lower app size and simpler playback surface. Cons: less motion guidance for procedural content.
2. **Pre-rendered illustration fallback:** if a system-only SVG renderer proves too unstable, convert the approved SVG assets to a bounded static format at build time while preserving the same attachment IDs and captions. Pros: simpler rendering. Cons: loses the explicit SVG asset requirement and some scaling flexibility.
3. **Settings-backed progress fallback:** if a full SwiftData progress repository is too large for the first pass, store only weekly-drill completion and best-score summaries in `@AppStorage` as a temporary bounded solution. Pros: smaller persistence surface. Cons: weaker extensibility and less testable than a repository-backed model.

## Report Format

1. **Scope executed:** confirm whether Sprint 10 shipped media attachments, quiz mode, weekly drill, and badges or which parts were deferred.
2. **Files changed:** list the edited domain, persistence, resource, UI, and test files.
3. **Content added:** summarize the shipped knot references, first-aid illustrations, quick cards, quizzes, and media assets.
4. **Progress model:** state where quiz and weekly-drill completion are persisted and whether badges are derived or stored.
5. **Verification evidence:** include the exact `xcodebuild`, targeted-test, and `snyk` commands run with pass/fail or `unverified` status.
6. **Environment blockers:** report any missing Xcode, missing `snyk`, asset-packaging, or simulator blockers verbatim.
7. **Follow-up risks:** note any deferred items such as asset-size reduction, fallback rendering, or additional accessibility polish.
