# MVP Handbook And Quick-Card Corpus Expansion Enhanced Prompt

**Date:** 2026-03-24
**Prompt Level:** Level 2
**Prompt Type:** Feature
**Complexity:** Complex
**Complexity Justification:** This task expands the curated seed corpus across multiple handbook and quick-card topics, must preserve the offline-first and safety-first editorial posture, and needs to remain consistent with the existing manifest, taxonomy, and review metadata without widening persistence or retrieval scope.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow` with the note: `Remaining "Not Started" Notion task: "Expand seed content packs into broader MVP handbook and quick-card corpus" — independent of milestone work, can proceed in parallel with M4.`
- Project operating rules: `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md`
- Product and architecture docs: `docs/sdlc/00-doc-suite-index.md`, `docs/sdlc/02-prd.md`, `docs/sdlc/03-mvp-scope-roadmap.md`, `docs/sdlc/04-information-architecture-and-ux-flows.md`, `docs/sdlc/05-technical-architecture.md`, `docs/sdlc/06-data-model-local-storage.md`, `docs/sdlc/09-content-model-editorial-guidelines.md`, `docs/sdlc/10-security-privacy-and-safety.md`, `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`, `docs/sdlc/12-release-readiness-and-app-store-plan.md`
- Risk context: `docs/sdlc/risk-register.md`
- Current corpus files: `OSA/Resources/SeedContent/SeedManifest.json`, `OSA/Resources/SeedContent/handbook-foundations-v1.json`, `OSA/Resources/SeedContent/quick-cards-core-v1.json`, `OSA/Resources/SeedContent/checklist-templates-core-v1.json`
- Current content-model guidance: `OSA/README.md`, `OSA/Resources/README.md`, `docs/prompt/enhanced/15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md`

## Classification Summary

- Core intent: broaden the seeded local handbook and quick-card corpus so the MVP feels materially useful offline before or alongside later milestone work.
- In scope: adding high-value handbook chapters and sections, adding complementary quick cards, preserving review metadata and taxonomy, updating the seed manifest, and keeping the corpus internally consistent.
- Out of scope: persistence schema work, importer redesign, Ask assistant changes, retrieval ranking, online knowledge refresh, navigation changes, or broad UI polish.

## Assumptions

- The current seed packs are the canonical starting point and should be expanded in place rather than replaced.
- The content should remain manually authored or reviewed, not wholesale auto-generated.
- The task can proceed in parallel with M4 without introducing cross-milestone dependencies.
- Checklist templates stay unchanged unless a tiny supporting fix is required for a cross-link or metadata correction.
- Content breadth matters more than novelty; the goal is to cover the most likely preparedness questions first.

## Mission Statement

Expand the seeded handbook and quick-card corpus from a thin proof-of-concept into a broader, grounded MVP library that improves offline browseability, citation quality, and stress-state usefulness while staying inside the app's safety and editorial boundaries.

## Technical Context

The current seed corpus is intentionally small. It already proves the content shape, but it does not yet cover enough of the everyday preparedness surface to feel complete for an MVP. The current packs include a single handbook chapter, a small quick-card set, and a starter set of checklist templates. That is enough to validate the format, not enough to support broad local browsing or a strong Ask grounding experience.

The expansion should preserve the existing corpus conventions:

- chapters stay compact, structured, and cite-friendly
- quick cards stay action-oriented and one-screen readable
- each record keeps stable identity, ordering, versioning, and review metadata
- `SeedManifest.json` stays in lockstep with the actual pack files and record counts
- sensitive topics remain conservative, reviewed, and grounded in approved static guidance

The content-model guidance already defines the editorial shape for chapters, sections, quick cards, and checklist templates. This task should use that structure directly rather than inventing a new format.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| The seed corpus has one handbook chapter and a small quick-card set. | The corpus covers the core MVP preparedness topics with multiple handbook chapters and complementary quick cards. |
| The current packs validate the shape but not the breadth of the library. | The expanded packs give users enough local material to browse, scan, and act on common preparedness needs. |
| Manifest metadata matches a thin starter corpus. | Manifest metadata accurately describes a broader versioned corpus with consistent counts and identifiers. |
| Sensitive topics are present only in limited form. | Sensitive or safety-relevant topics remain conservative, reviewed, and clearly bounded. |
| The corpus is useful as a sample. | The corpus is useful as an MVP seed library under offline conditions. |

## Pre-Flight Checks

1. Confirm the current seed-pack shape before adding new content.
   *Success signal: the implementer can name the pack files, their kinds, and the metadata fields that must remain in sync.*

2. Confirm which MVP topics are highest value to add next.
   *Success signal: the implementer can list the target handbook chapters and quick cards before writing content.*

3. Confirm the safety boundary for any risky or sensitive subject matter.
   *Success signal: the implementer can state what will stay static, conservative, or out of scope.*

4. Confirm whether any checklist-template change is actually necessary.
   *Success signal: the implementer can explain why checklist updates are required, or explicitly leave them untouched.*

5. Confirm that the work remains local-first and corpus-focused.
   *Success signal: no online import, UI redesign, or schema expansion is introduced to solve a content-breadth problem.*

## Phased Instructions

### Phase 1: Freeze The Corpus Scope

1. Define the minimum expansion needed for a broader MVP corpus.
   *Success signal: the implementer explicitly lists which handbook domains and quick-card categories are being added now and which are deferred.*

2. Keep the task inside the seed-content boundary.
   *Success signal: no persistence, importer, retrieval, or assistant-policy change is needed to complete the content expansion.*

3. Prefer broad utility over niche completeness.
   *Success signal: new content targets common preparedness actions and household decision points first.*

4. Preserve the existing editorial style and metadata patterns.
   *Success signal: new records use stable IDs, slugs where applicable, sort order, tags, versioning, and review dates consistent with the current packs.*

### Phase 2: Expand Handbook Coverage

1. Add handbook chapters for the highest-value MVP topics.
   *Success signal: the corpus covers common readiness domains such as family planning, water, food, power outage, cooking without power, warmth and shelter, first aid, hygiene, medications, go-bags, home supplies, utilities, tools, fire and lighting, and local notes or maps where appropriate.*

2. Keep each chapter structured and readable under stress.
   *Success signal: each chapter includes a purpose, when this matters, key principles, step-by-step guidance, cautions, related quick cards, related checklists, review date, and safety level where applicable.*

3. Keep sections small enough to retrieve and scan cleanly.
   *Success signal: sections do not become dense essays and remain suitable for small-screen browsing and citation-oriented use.*

4. Do not over-specify facts that are better left to reviewed static content.
   *Success signal: content remains concise, direct, and conservative rather than trying to be encyclopedic.*

### Phase 3: Expand Quick-Card Coverage

1. Add quick cards for the most repeated or time-sensitive tasks.
   *Success signal: quick cards cover first-hour actions, outage checks, kit checks, rotation tasks, safety boundaries, and other common readiness actions.*

2. Keep quick cards immediate and action-oriented.
   *Success signal: titles are direct, the body starts with immediate actions, and what-not-to-do or escalation notes are obvious.*

3. Anchor each card to the handbook corpus.
   *Success signal: each quick card references the most relevant handbook section or related content record so the corpus stays internally linked.*

4. Keep quick cards clearly distinct from chapters.
   *Success signal: the quick-card set remains short-form and task-focused rather than becoming a duplicate chapter library.*

### Phase 4: Preserve Editorial And Safety Boundaries

1. Apply the content-model guidelines consistently.
   *Success signal: the writing stays calm, concrete, and short, with strong headings and minimal ambiguity.*

2. Keep sensitive domains conservative.
   *Success signal: medical-adjacent, fire-related, utilities-related, and similar topics avoid unsafe improvisation, diagnosis, or step-by-step risk escalation.*

3. Keep weapon-adjacent or hazardous material tightly bounded.
   *Success signal: archery or longbow references, if included, stay limited to safety, inspection, maintenance, storage, inventory, practice logs, or lawful reference notes only.*

4. Preserve provenance discipline.
   *Success signal: the corpus does not invent source claims, trust tiers, or review history that are not actually present.*

### Phase 5: Update Manifest And Keep Packs Consistent

1. Update `SeedManifest.json` whenever the packs change.
   *Success signal: version, record counts, and file names reflect the actual pack contents.*

2. Keep pack-level metadata aligned with the content files.
   *Success signal: the manifest can be used to determine whether the corpus changed and which pack changed.*

3. Validate cross-record references.
   *Success signal: quick-card related IDs, chapter-section IDs, and any checklist links resolve inside the seed corpus.*

4. Avoid duplication.
   *Success signal: new content broadens the corpus instead of repeating the same guidance with slightly different wording.*

### Phase 6: Review And Verification

1. Verify the corpus still decodes cleanly.
   *Success signal: JSON integrity and any loader or decoding tests pass for the updated files.*

2. Verify the expansion improved breadth rather than just volume.
   *Success signal: common MVP questions now have better local coverage and clearer entry points.*

3. Verify the safety posture still holds.
   *Success signal: no new content crosses the documented safety and editorial boundaries.*

4. Record any intentionally deferred topics.
   *Success signal: the report calls out what remains for a later seed-content expansion instead of implying full coverage.*

## Guardrails

- Do not change the persistence schema or importer unless the existing seed shape truly cannot support the expanded corpus.
- Do not introduce retrieval, Ask, or online refresh work as part of corpus expansion.
- Do not fabricate sources, dates, safety levels, or trust tiers.
- Do not add unsafe tactical, medical, foraging, or improvisational fire guidance.
- Do not turn the task into a UI redesign or navigation project.
- Do not leave placeholder content where a real seed record is expected.

## Verification Checklist

- [ ] The handbook corpus includes additional high-value MVP chapters.
- [ ] The quick-card corpus includes additional fast-action cards.
- [ ] Manifest counts and file names match the actual pack contents.
- [ ] Each new record has stable identity, ordering, and review metadata.
- [ ] Sensitive-topic wording stays conservative and reviewable.
- [ ] The corpus remains local-first and offline usable.
- [ ] Any JSON integrity or loader checks were updated or rerun.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| A new chapter or card repeats an existing topic too closely | Merge the guidance or refocus the record so it adds distinct value. |
| A record lacks review or safety metadata | Add the missing metadata before treating the pack as complete. |
| A quick card has no clear handbook anchor | Add the supporting handbook section or choose a different source topic. |
| Manifest counts diverge from the actual file contents | Update the manifest and content files together so the corpus stays internally consistent. |
| A topic drifts into unsafe or speculative advice | Tighten the wording or move the topic out of scope for this expansion. |
| The corpus starts to grow wider than the MVP needs | Prefer deeper coverage of the highest-value household domains instead of adding niche material. |

## Out Of Scope

- New persistence models or repository work.
- Retrieval-ranking changes.
- Ask policy or prompt-shaping changes.
- Online knowledge refresh or live-web import.
- Non-corpus UI polish or navigation changes.
- Expanding into unrelated content domains before the core MVP corpus is materially improved.

## Report Format

When the corpus expansion is complete, report in this structure:

1. Files changed.
2. Handbook chapters added.
3. Quick cards added.
4. Manifest updates.
5. Any checklist-template changes, if any.
6. Validation results.
7. Deferred topics or residual risks.
