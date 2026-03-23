# Content Model And Editorial Guidelines

Status: Initial draft complete.  
Related docs: [PRD](./02-prd.md), [Data Model](./06-data-model-local-storage.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Security And Privacy](./10-security-privacy-and-safety.md)

## Confirmed Facts

- The app depends on a curated local corpus for handbook browsing, quick cards, and Ask.
- Sensitive topics must favor reviewed static content and concise reference materials over model improvisation.
- Archery and longbow content is intentionally limited to safety, maintenance, inspection, storage, inventory, and practice logs or lawful reference notes.

## Assumptions

- Initial seed content will be authored or reviewed manually rather than auto-generated wholesale.
- A single editor or very small content team will maintain the corpus.
- Content will be stored in a structured source format and imported into the local app store.

## Recommendations

- Author content in small, heading-rich sections that retrieve well and cite cleanly.
- Use consistent taxonomy across handbook, quick cards, and checklists.
- Mark sensitive sections with review cadence and safety level metadata.

## Open Questions

- Who is the formal reviewer for medical-adjacent and fire-safety content?
- How much imported web knowledge can enter the corpus before editorial review becomes a bottleneck?
- Should local note templates be included as seed content in v1?

## Chapter Template

Each handbook chapter should contain:

- `Title`
- `Purpose`
- `When this matters`
- `Key principles`
- `Step-by-step guidance`
- `Common mistakes or cautions`
- `Related quick cards`
- `Related checklists`
- `Review date`
- `Safety level`

## Section Template

Each section should contain:

- `Heading`
- `One-paragraph summary`
- `Detailed guidance`
- `Decision points` if needed
- `Cautions / do not do`
- `Related sources or references`
- `Tags`

Sections should stay small enough to cite precisely and to display cleanly on a phone.

## Quick Card Template

Each quick card should contain:

- `Title`
- `Use case`
- `Immediate actions`
- `What to check next`
- `What not to do`
- `Escalation or seek-help note` where appropriate
- `Related handbook section`
- `Review date`

Quick cards should be concise, large-type friendly, and action-oriented.

## Checklist Template

Each checklist template should contain:

- `Title`
- `Use case`
- `Estimated time`
- `Items in logical order`
- `Optional items`
- `Related quick cards or sections`
- `Review date`

Checklist items should start with clear verbs and avoid long paragraphs.

## Metadata And Taxonomy

Recommended shared metadata:

- domain such as water, food, power, first-aid
- topic tags
- urgency level
- safety level
- review date
- source type such as seed, imported-reviewed, or user-authored
- trust tier for imported sources

## Writing Style Guide

- Use calm, direct engineering English.
- Prefer short sentences and concrete verbs.
- State limits and cautions plainly.
- Avoid hype, fear language, and macho framing.
- Prefer "do this" and "avoid this" over open-ended speculation.
- Write for stressed readers first, curious readers second.

## Citation Style

- Handbook citations should use chapter and section titles.
- Quick cards should cite the card title.
- Imported sources should display title plus publisher/domain and review or fetch date when relevant.
- Sensitive guidance should show recency or review context prominently.

## Review Workflow

Recommended v1 workflow:

1. Draft source content in structured files.
2. Technical/editorial review for clarity, taxonomy, and retrieval shape.
3. Safety review for sensitive domains.
4. Assign version, review date, and safety level.
5. Import into seed manifest and test retrieval and citation quality.

## Update Workflow

- Seed content updates follow semantic or date-based versioning.
- Imported knowledge remains clearly separated from authored seed content.
- Any material change to safety-sensitive sections requires review-date update and regression testing of Ask prompts tied to that content.

## Safety-Review Rules

- Medical-adjacent content: reviewed static guidance only, no diagnostic or dosage invention.
- Fire and lighting: emphasize safe handling, fuel/storage boundaries, and do-not-improvise warnings.
- Utilities and shelter: avoid dangerous electrical, gas, structural, or heating improvisation unless the guidance is explicitly reviewed and conservative.
- Archery and longbow: limit to safety, maintenance, inspection, storage, inventory, range habits, and practice logs only.

## Initial Chapter Map

| Chapter | Focus | Notes |
| --- | --- | --- |
| Preparedness Foundations | Core principles, planning mindset, staging, and prioritization. | Good candidate for first seed chapter. |
| Family Plan And Emergency Contacts | Contacts, meeting points, communication plans, household coordination. | Connects closely to notes and checklist templates. |
| Water | Storage, rotation, purification basics, safe handling. | High-value quick cards. |
| Food | Pantry planning, ration basics, rotation, storage. | Avoid speculative nutritional or medical claims. |
| Power Outage | Outage preparation, device charging, load planning, household routines. | Links to inventory and checklists. |
| Cooking Without Power | Safe cooking options, fuel handling basics, indoor/outdoor boundaries. | Static safety review required. |
| Warmth And Shelter | Seasonal planning, layering, bedding, room selection, cold-weather basics. | Emphasize conservative guidance. |
| First Aid, Hygiene, And Medications | Basics, storage, hygiene, kit organization, recordkeeping. | Static-only handling for sensitive subtopics. |
| Go-Bags | Purpose-based bag planning, maintenance, family variants. | Strong checklist integration. |
| Home Supplies, Utilities, And Tools | Household readiness items, shutoff awareness notes, safe tool reference. | Avoid risky step-by-step utility intervention unless reviewed. |
| Local Notes, Maps, And Forest Reference | Place-based notes, routes, landmarks, lawful local references. | v1 may begin as text and image references instead of full maps. |
| Fire And Lighting | Safe lighting, batteries, lantern basics, fire safety boundaries. | Strong quick-card candidate. |
| Archery / Longbow | Safety, inspection, maintenance, storage, inventory, range habits, practice logs, lawful reference notes. | No tactical, hunting, or combat content. |

## Done Means

- Content structures are consistent with the retrieval and citation model.
- Editorial rules are explicit enough that new seed content can be authored without inventing format each time.
- Sensitive-domain constraints are encoded in the content process, not left to model behavior alone.

## Next-Step Recommendations

1. Author one complete sample chapter, one quick card, and one checklist template to validate the format.
2. Define trust tiers and review SLAs for imported content before enabling broad source import.
3. Build content lint checks once the source file format is chosen.

