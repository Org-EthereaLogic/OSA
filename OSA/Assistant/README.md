# Assistant

Bounded assistant implementation surfaces.

## Subdomains

- `Policy/` — scope checks, blocked categories, and refusal rules
- `ModelAdapters/` — runtime capability detection and generation adapters
  - `DeviceCapabilityDetector` — runtime detection of Foundation Models availability via `#if canImport(FoundationModels)` and `#available(iOS 26, *)`
  - `FoundationModelAdapter` — concrete `GroundedAnswerGenerator` using Apple Foundation Models (compiled only when SDK supports it)

## Planned Subdomains

- `Orchestration/` — retrieval + policy + formatting coordination
- `Formatting/` — answer sections, UI shaping, and citation presentation helpers
