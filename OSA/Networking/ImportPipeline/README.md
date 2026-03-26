# ImportPipeline

Normalization, attribution, chunking, and local-commit stages for imported knowledge.

## M4P4: Import Pipeline (Complete)

- `ImportedKnowledgeNormalizer`: Accepts `TrustedSourceFetchResponse` and produces `NormalizedDocument` with extracted title (HTML title tag → h1 → URL fallback), plain text, normalized markdown, content hash, publisher domain, source URL, and document type classification (article, guide, checklist, reference). Supports `text/html`, `application/xhtml+xml`, and `text/plain`.
- `KnowledgeChunker`: Splits `NormalizedDocument` into ordered `KnowledgeChunk` records. Heading-aware chunking splits at `#`/`##`/`###` boundaries; paragraph-group fallback merges paragraphs into 150–400 word chunks when no headings exist. Each chunk carries a stable deterministic `localChunkID`, heading path, token estimate, trust level, and searchability flag.
- `ImportedKnowledgeImportPipeline`: Orchestrates the full local-commit sequence: fetch response → normalize → chunk → persist (`SourceRecord` + `ImportedKnowledgeDocument` + `KnowledgeChunk` records) → index approved chunks via `SearchService.indexImportedChunk`. Handles content-hash dedupe (same URL + same hash = metadata refresh only) and document versioning (same URL + different hash = new document version with `supersedesDocumentID`, old chunks de-indexed). Tier 3 pending chunks persist locally but are not indexed.
