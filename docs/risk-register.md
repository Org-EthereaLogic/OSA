# Risk Register

Status: Initial draft complete.  
Related docs: [Problem Brief](./01-problem-brief.md), [Technical Architecture](./05-technical-architecture.md), [Sync And Refresh](./07-sync-connectivity-and-web-knowledge-refresh.md), [AI Assistant](./08-ai-assistant-retrieval-and-guardrails.md), [Quality Strategy](./11-quality-strategy-test-plan-and-acceptance.md)

## Confirmed Facts

- The project has completed Milestone 1 Phase 1 and now includes the first editorial-content persistence slice for handbook chapters, sections, quick cards, and bundled seed import. Broader business logic, retrieval, and user-data persistence are still pending.
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
| R1 | Foundation Models unavailable or underperforming on target devices, weakening Ask quality. | Platform | Medium | High | Build extractive fallback, capability checks, and device matrix testing before feature lock. | Engineering | Open |
| R2 | Hallucinations or weak grounding produce unsafe or misleading answers. | AI Safety | Medium | High | Enforce local-evidence-only retrieval, mandatory citations, refusal paths, and adversarial safety tests. | Engineering | Open |
| R3 | Imported knowledge becomes stale and answers remain technically grounded but outdated. | Content Freshness | High | High | Track freshness metadata, shorter stale windows for sensitive topics, and visible stale indicators. | Product/Content | Open |
| R4 | Content safety drift expands assistant behavior into tactical, medical, or foraging advice. | Product Safety | Medium | High | Lock scope in ADRs, review prompts/policies, and add regression tests for blocked categories. | Product/Engineering | Open |
| R5 | On-device storage growth from imported knowledge, raw artifacts, and search indexes degrades performance. | Storage | Medium | Medium | Set source-size limits, prune temp files, dedupe by hash, and monitor database/index growth. | Engineering | Open |
| R6 | Schema and seed-content migrations become brittle as the corpus grows. | Data | Medium | High | Version schemas, keep stable IDs, separate seed from user data, and test upgrade paths in CI. | Engineering | Open |
| R7 | Background refresh is unreliable across iOS conditions and produces confusing partial state. | Platform | Medium | Medium | Keep refresh resumable, atomic on commit, user-visible in status, and safe under Low Power Mode. | Engineering | Open |
| R8 | Scope creep pulls in mapping, sync, attachments, or complex AI too early. | Delivery | High | High | Hold MVP to curated handbook, local Ask, inventory, checklists, notes, and controlled online import only. | Product | Open |
| R9 | Trusted-source policy is too loose, allowing poor-quality or unsafe imports. | Trust | Medium | High | Start with allowlist and trust tiers, require approval for imports, and preserve provenance metadata. | Product/Content | Open |
| R10 | Privacy expectations are violated if prompts or personal notes ever leave device unexpectedly. | Privacy | Low | High | Keep logs local, avoid remote prompt processing in v1, and publish clear disclosures. | Engineering/Product | Open |
| R11 | Unsupported or ambiguous minimum OS decision causes rework in architecture and testing. | Planning | Medium | Medium | iOS 18.0 minimum target adopted. See [ADR-0004](./adr/ADR-0004-ios18-minimum-target-with-foundation-models.md). | Product/Engineering | Mitigated |
| R12 | Insufficient seed content quality makes retrieval look worse than the model or index actually are. | Content | Medium | High | Write structured, reviewable content with consistent taxonomy and chunk boundaries before evaluating Ask quality. | Content/Product | Open |

## Done Means

- Core risks have explicit owners and actionable mitigations.
- Release blockers around grounding, stale content, migrations, and privacy are visible early.
- The register is specific enough to drive milestone reviews, not just a generic appendix.

## Next-Step Recommendations

1. Re-score each risk at the end of the first architecture spike.
2. Promote R1, R2, R3, R6, and R8 into milestone exit criteria.
3. Add issue links once implementation tracking begins.
