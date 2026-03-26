# Networking

Optional online enrichment surfaces that never bypass local persistence and attribution.

## Implemented And Planned Subdomains

- `Clients/` — trusted-source discovery, allowlist enforcement, and HTTP client (M4P1 `ConnectivityService`; M4P3 `TrustedSourceAllowlist`, `TrustedSourceHTTPClient`, `URLSessionTrustedSourceHTTPClient`)
- `DTOs/` — network-facing transfer objects (M4P3 `TrustedSourceFetchResponse`)
- `ImportPipeline/` — normalization, chunking, and local commit stages (M4P4 complete: `ImportedKnowledgeNormalizer`, `KnowledgeChunker`, `ImportedKnowledgeImportPipeline`)
- `Refresh/` — stale checks, retry coordination, and refresh orchestration (scaffolded; M4P5+)
