# Assistant

Bounded assistant implementation surfaces.

## Subdomains

- `Policy/` — scope checks, blocked categories, prompt injection detection, and refusal rules
- `PromptShaping/` — grounded prompt construction with safety instructions, citation rules, and style constraints
  - `GroundedPromptBuilder` — builds model-ready prompts from retrieval pipeline outputs; enforces grounding, citation, scope, safety, and override-protection rules
- `ModelAdapters/` — runtime capability detection and generation adapters
  - `DeviceCapabilityDetector` — runtime detection of Foundation Models availability via `#if canImport(FoundationModels)` and `#available(iOS 26, *)`
  - `FoundationModelAdapter` — concrete `GroundedAnswerGenerator` using Apple Foundation Models; delegates prompt construction to `GroundedPromptBuilder`

## Planned Subdomains

- `Orchestration/` — retrieval + policy + formatting coordination
- `Formatting/` — answer sections, UI shaping, and citation presentation helpers
