# Data Model And Local Storage

Status: Initial draft complete.  
Related docs: [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Content Guidelines](./09-content-model-editorial-guidelines.md), [Security And Privacy](./10-security-privacy-and-safety.md)

## Confirmed Facts

- Core functionality must work fully offline from locally stored content and user data.
- Imported web knowledge must become locally available for future offline use.
- The product requires local handbook content, quick cards, checklists, inventory, notes, citations, AI sessions, and settings.
- The first editorial-content persistence slice is now implemented: SwiftData models for `PersistedHandbookChapter`, `PersistedHandbookSection`, `PersistedQuickCard`, and `PersistedSeedContentState`; domain-facing value types and repository protocols (`HandbookRepository`, `QuickCardRepository`, `SeedContentRepository`); a `SwiftDataContentRepository` implementation; a versioned seed-manifest loader and importer; and focused repository-contract tests.

## Assumptions

- SwiftData will be the primary persistence mechanism for v1.
- Search indexing will use a separate sidecar store rather than relying only on SwiftData queries.
- Seed content will be shipped as versioned bundled data and imported into the local store on first launch.

## Recommendations

- Keep structured records in SwiftData and raw imported artifacts in `Application Support`.
- Use stable UUIDs and content hashes to support deduplication, refresh, and citation durability.
- Separate editorial content identity from user state so handbook updates do not corrupt notes, checklist history, or citations.

## Open Questions

- Should attachments such as photos or scanned documents be in scope for inventory or notes in v1?
- Should local map assets be records in the same store or a future file-backed feature?
- Is user export needed before any migration strategy is considered production-ready?

## Storage Strategy

### Primary Store

- SwiftData for normalized entities and relationships.
- One persistent store for user data and local knowledge.
- Repository layer hides direct framework calls from feature code.

### Sidecar Stores

- `SearchIndex.sqlite`: keyword and metadata index.
- `RawSources/`: downloaded HTML, text extracts, source snapshots, or parser intermediates.
- `SeedContent/`: bundled JSON or Markdown content packs with version manifests.

### Data Classes

- Immutable or slowly changing editorial content: chapters, sections, quick cards, checklist templates.
- Mutable user state: notes, inventory items, checklist runs, settings, AI sessions.
- Imported knowledge: source metadata, normalized documents, chunks, citations, refresh state.

## Core Entities

```mermaid
erDiagram
    HandbookChapter ||--o{ HandbookSection : contains
    HandbookSection ||--o{ QuickCard : summarizes
    ChecklistTemplate ||--o{ ChecklistTemplateItem : contains
    ChecklistTemplate ||--o{ ChecklistRun : instantiates
    ChecklistRun ||--o{ ChecklistRunItem : tracks
    SourceRecord ||--o{ ImportedKnowledgeDocument : owns
    ImportedKnowledgeDocument ||--o{ KnowledgeChunk : contains
    KnowledgeChunk ||--o{ CitationRecord : cited_by
    AISession ||--o{ AIMessage : contains
    AppSetting ||--o{ PendingOperation : configures
```

## Entity Schemas

### HandbookChapter

- `id`: UUID
- `slug`: stable string
- `title`
- `summary`
- `sortOrder`
- `tags`
- `version`
- `isSeeded`
- `lastReviewedAt`

### HandbookSection

- `id`
- `chapterID`
- `parentSectionID` optional
- `heading`
- `bodyMarkdown`
- `plainText`
- `sortOrder`
- `tags`
- `safetyLevel` such as normal, sensitive-static-only
- `chunkGroupID`
- `version`
- `lastReviewedAt`

### QuickCard

- `id`
- `title`
- `slug`
- `category`
- `summary`
- `bodyMarkdown`
- `priority` for emergency surfacing
- `relatedSectionIDs`
- `tags`
- `lastReviewedAt`
- `largeTypeLayoutVersion`

### InventoryItem

- `id`
- `name`
- `category`
- `quantity`
- `unit`
- `location`
- `notes`
- `expiryDate` optional
- `reorderThreshold` optional
- `tags`
- `createdAt`
- `updatedAt`
- `isArchived`

### ChecklistTemplate

- `id`
- `title`
- `slug`
- `category`
- `description`
- `estimatedMinutes`
- `tags`
- `sourceType` such as seeded or imported-reviewed
- `lastReviewedAt`

### ChecklistTemplateItem

- `id`
- `templateID`
- `text`
- `detail`
- `sortOrder`
- `isOptional`
- `riskLevel`

### ChecklistRun

- `id`
- `templateID` optional for ad hoc lists
- `title`
- `startedAt`
- `completedAt` optional
- `status`
- `contextNote`

### ChecklistRunItem

- `id`
- `runID`
- `templateItemID` optional
- `text`
- `isComplete`
- `completedAt` optional
- `sortOrder`

### NoteRecord

- `id`
- `title`
- `bodyMarkdown`
- `plainText`
- `noteType` such as personal, local-reference, family-plan
- `tags`
- `linkedSectionIDs`
- `linkedInventoryItemIDs`
- `createdAt`
- `updatedAt`

### SourceRecord

Required metadata for imported knowledge:

- `id`
- `sourceTitle`
- `sourceURL`
- `publisherDomain`
- `publisherName`
- `fetchedAt`
- `lastReviewedAt`
- `contentHash`
- `trustLevel`
- `tags`
- `localChunkIDs`
- `reviewStatus`
- `licenseSummary` optional
- `isActive`
- `staleAfter`

### ImportedKnowledgeDocument

- `id`
- `sourceID`
- `title`
- `normalizedMarkdown`
- `plainText`
- `documentType`
- `versionHash`
- `importedAt`
- `supersedesDocumentID` optional

### KnowledgeChunk

- `id`
- `documentID`
- `localChunkID`
- `headingPath`
- `plainText`
- `sortOrder`
- `tokenEstimate`
- `tags`
- `trustLevel`
- `contentHash`
- `isSearchable`

### CitationRecord

- `id`
- `chunkID` optional
- `sectionID` optional
- `quickCardID` optional
- `displayLabel`
- `anchorText`
- `sourceTitle`
- `sourceURL` optional for imported sources
- `publisherDomain` optional
- `generatedAt`

### AISession

- `id`
- `startedAt`
- `endedAt` optional
- `capabilityMode` such as foundationGeneration or extractiveOnly
- `scope` such as handbook-only or handbook-plus-user-data
- `lastAnswerStatus`

### AIMessage

- `id`
- `sessionID`
- `role`
- `text`
- `citationIDs`
- `createdAt`
- `blockedReason` optional

### AppSetting

- `id`
- `key`
- `valueType`
- `stringValue` optional
- `boolValue` optional
- `numberValue` optional
- `updatedAt`

### PendingOperation

- `id`
- `operationType`
- `status`
- `payloadReference`
- `createdAt`
- `updatedAt`
- `retryCount`
- `lastError`

## Local File And Storage Layout

Recommended layout under app container:

```text
Application Support/
  OSA.sqlite
  SearchIndex.sqlite
  SeedManifest.json
  RawSources/
    <source-id>/
      original.html
      extracted.txt
      metadata.json
  ContentPacks/
    handbook-v1.json
    quickcards-v1.json
  Imports/
    <document-id>.json
Caches/
  RefreshTemp/
  RenderedSearchSnippets/
```

## Migration Strategy

- Use explicit schema versioning for seed content and data model.
- Migrate editorial content by comparing stable slugs, content hashes, and version numbers.
- Keep user-authored records separate from seeded records so seeded updates do not overwrite user edits.
- Run migration checks on cold start after app updates and before background refresh jobs mark new content active.
- Keep a rollback-safe backup of the last known-good store before any destructive schema migration during development and beta.

## Backup And Restore Considerations

- Default stance for v1: rely on iOS device backup behavior, but do not promise cross-device restore semantics yet.
- Keep raw imported artifacts reproducible from normalized stored records where possible to reduce storage footprint.
- Future explicit export should include user notes, inventory, checklist runs, and settings, but not necessarily bundled seed content.
- If iCloud backup opt-out is needed for sensitive content, it must be a deliberate later decision with user communication.

## Seed Data Strategy

- Author handbook chapters, sections, quick cards, and checklist templates as versioned source files in the repo once content drafting begins.
- Import seed content on first launch into normalized records with stable IDs.
- Maintain a seed manifest with content pack version, record counts, content hashes, and review timestamps.
- Treat seed updates as migrations rather than ad hoc inserts.

## Done Means

- The entities cover all required core features and online knowledge refresh needs.
- Required imported-source metadata is explicitly defined.
- Local file layout and migration strategy are concrete enough to implement without inventing new structure.
- The schema keeps citations durable across refresh and reindexing events.

## Next-Step Recommendations

1. ~~Convert this model into SwiftData schemas and repository protocols before feature UI.~~ **Done:** First editorial-content slice (chapters, sections, quick cards) implemented with SwiftData models, domain value types, repository protocols, and seed import. The browsing UI layer (`OSA/Features/Library`, `OSA/Features/QuickCards`) now reads from this model through repository protocol injection, completing the first user-visible offline reading surface.
2. ~~Create versioned seed content manifests alongside the future Xcode project.~~ **Done:** `SeedManifest.json` with content-pack versioning, record counts, and content hashes is in `OSA/Resources/SeedContent/`.
3. Decide whether attachments and map assets belong in v1 before freezing the first schema version.

