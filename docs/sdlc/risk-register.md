# Risk Register

Status: Initial draft complete.  
Related docs: [Problem Brief](./01-problem-brief.md), [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md)

## Confirmed Facts

- The project has completed Milestones 1, 2, and 3. Editorial-content persistence, user-data CRUD (inventory, checklists, notes), FTS5 search, the grounded retrieval pipeline with sensitivity policy and extractive answer assembly, Foundation Models generation adapter (M3P3), and prompt shaping with safety guardrails (M3P5) are all implemented and tested.
- AI capability, content safety, and offline reliability are core product risks rather than secondary concerns.

## Assumptions

- One developer or a very small team will own implementation.
- The first release will likely use modern Apple frameworks and on-device AI capabilities where available.

## Recommendations

- Review this register at each milestone and update ADRs when mitigations change architecture.
- Treat safety, grounding, and migration risks as release blockers, not backlog cleanup items.

## Open Questions

- Which risks are acceptable for beta but not public launch?
- Who owns content review and source approval if implementation starts before full editorial staffing exists?

## Risks

| ID | Risk Description | Category | Likelihood | Impact | Mitigation | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R1 | Foundation Models unavailable or underperforming on target devices, weakening Ask quality. | Platform | Medium | High | Extractive fallback and `DeviceCapabilityDetector` implemented in M3P1. `FoundationModelAdapter` with real capability detection implemented in M3P3. Remaining: real-device matrix testing across hardware tiers. | Engineering | Partially Mitigated |
| R2 | Hallucinations or weak grounding produce unsafe or misleading answers. | AI Safety | Medium | High | Local-evidence-only retrieval enforced. `GroundedPromptBuilder` encodes mandatory grounding, citation, and refusal rules. `SafetyRegressionTests` covers adversarial prompt variants, routing verification, and deterministic refusal. Remaining: real-corpus evaluation with Foundation Models output. | Engineering | Partially Mitigated |
| R3 | Imported knowledge becomes stale and answers remain technically grounded but outdated. | Content Freshness | High | High | Track freshness metadata, shorter stale windows for sensitive topics, and visible stale indicators. | Product/Content | Open |
| R4 | Content safety drift expands assistant behavior into tactical, medical, or foraging advice. | Product Safety | Medium | High | Scope locked in ADRs. `SensitivityPolicy` enforces blocked/sensitive categories and prompt injection detection. `GroundedPromptBuilder` reinforces safety boundaries in model prompts. `SafetyRegressionTests` regression suite covers blocked categories, injection, and mixed-intent prompts. | Product/Engineering | Partially Mitigated |
| R5 | On-device storage growth from imported knowledge, raw artifacts, and search indexes degrades performance. | Storage | Medium | Medium | Set source-size limits, prune temp files, dedupe by hash, and monitor database/index growth. | Engineering | Open |
| R6 | Schema and seed-content migrations become brittle as the corpus grows. | Data | Medium | High | Seed-content versioning and stable-ID import implemented. User-data schema stable across M1–M2. Comprehensive migration testing deferred to M5 (Hardening). | Engineering | Partially Mitigated |
| R7 | Background refresh is unreliable across iOS conditions and produces confusing partial state. | Platform | Medium | Medium | Keep refresh resumable, atomic on commit, user-visible in status, and safe under Low Power Mode. | Engineering | Open |
| R8 | Scope creep pulls in mapping, sync, attachments, or complex AI too early. | Delivery | High | High | Hold MVP to curated handbook, local Ask, inventory, checklists, notes, and controlled online import only. | Product | Open |
| R9 | Trusted-source policy is too loose, allowing poor-quality or unsafe imports. | Trust | Medium | High | Start with allowlist and trust tiers, require approval for imports, and preserve provenance metadata. | Product/Content | Open |
| R10 | Privacy expectations are violated if prompts or personal notes ever leave device unexpectedly. | Privacy | Low | High | Keep logs local, avoid remote prompt processing in v1, and publish clear disclosures. | Engineering/Product | Open |
| R11 | Unsupported or ambiguous minimum OS decision causes rework in architecture and testing. | Planning | Medium | Medium | iOS 18.0 minimum target adopted. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md). | Product/Engineering | Mitigated |
| R12 | Insufficient seed content quality makes retrieval look worse than the model or index actually are. | Content | Medium | High | Seed corpus expanded: 11 handbook chapters with 35 sections, 14 quick cards, 5 checklist templates. Content hashes populated in SeedManifest.json v0.3.1. Two planned chapters (Local Notes/Maps, Archery/Longbow) deferred. | Content/Product | Substantially Mitigated |

## Done Means

- Core risks have explicit owners and actionable mitigations.
- Release blockers around grounding, stale content, migrations, and privacy are visible early.
- The register is specific enough to drive milestone reviews, not just a generic appendix.

## Next-Step Recommendations

1. Re-score each risk at the end of the first architecture spike.
2. Promote R1, R2, R3, R6, and R8 into milestone exit criteria.
3. Add issue links once implementation tracking begins.
