# Constitution for OSA

This constitution defines the governing principles for OSA development.

## Scope

It applies to:

- native iPhone app implementation and app-shell behavior
- local knowledge storage, retrieval, and seed-content import
- assistant behavior, safety boundaries, and citation rules
- networking and trusted-source import surfaces
- documentation, ADRs, governance files, and delivery reporting

## Required Decision Order

When principles conflict, resolve them in this order:

1. User safety and correctness.
2. Grounding, provenance, and citation integrity.
3. Privacy, security, and device-local data boundaries.
4. Simplicity and proportionality.
5. Reproducibility and operational reliability.
6. Performance and stress-state usability.

## Governing Principles

### P1. Safety, Correctness, and Product Boundary Integrity

- Never ship a change that knowingly violates safety boundaries, offline guarantees, or acceptance criteria.
- Prefer explicit refusal, clear fallback behavior, or disabled actions over silent unsafe behavior.
- Core local features must remain usable without network connectivity.

### P2. Grounded Knowledge and Provenance

- The assistant may answer only from approved local content and allowed app data.
- Imported web content becomes usable only after local persistence, normalization, attribution, and review-state checks.
- Substantive assistant answers must carry durable local citations.
- If local evidence is insufficient, the product must say so plainly.

### P3. Privacy, Security, and Secret Hygiene

- User notes, inventory, checklists, prompts, and local knowledge remain on device by default.
- No credentials, tokens, or secret material belong in repository content or committed artifacts.
- Request the minimum system permissions necessary; avoid broad permissions without documented product need.

### P4. Simplicity and Proportionality

- Prefer one app target with clear folder and protocol boundaries before introducing more modules or packages.
- Avoid speculative generic repositories, plugin systems, service locators, or sync abstractions.
- Choose the smallest coherent implementation that satisfies the current milestone.

### P5. Reproducibility and Operational Reliability

- Keep `project.yml`, `OSA.xcodeproj`, code, and docs aligned.
- Verification claims must reference commands that were actually run.
- Seed content, migrations, and durable identifiers must be versioned explicitly when introduced.
- Another developer should be able to explain or replay a claimed result from repository artifacts and command history.

### P6. Human Control and Transparent Networking

- Any online action must be user-visible or explicitly user-initiated unless a future ADR says otherwise.
- The app must make local-only mode, insufficient local evidence, and online fallback offers understandable to the user.
- Interrupted import or refresh work must not corrupt or silently replace existing local content.

### P7. Validation Before Expansion

- Land persistence, retrieval, safety, and citation correctness before broad assistant polish or online enrichment.
- Stress-state usability and offline behavior outrank cosmetic feature expansion.
- Safety-sensitive guidance requires reviewed static content and matching tests, not prompt optimism.

## Evidence Integrity Rules

- Build, test, security, and behavior claims require explicit command or artifact evidence.
- If verification is blocked by the environment, report the blocker and mark the claim `unverified`.
- Offline or local-only claims must not rely on unstated connectivity assumptions.
- Current repository docs and accepted ADRs are canonical; historical prompts or reference repos are advisory only.

## Prohibited Anti-Patterns

- General-chat behavior that bypasses local evidence.
- Uncited assistant answers or authoritative-looking fallback prose with no support.
- Mixing editorial content identity with mutable user state in the same records.
- Exposing SwiftData or storage-framework details directly to feature views.
- Shipping remote dependencies, analytics, or permissions without documented product need.
- Destructive edits to governance, docs, or evidence intended to hide failures or drift.

## Relationship to Other Governance Docs

- `AGENTS.md` defines operational behavior for coding agents.
- `DIRECTIVES.md` defines enforceable repository rules.
- `CLAUDE.md` provides the operator quick reference.
- `docs/` and accepted ADRs define the current product, architecture, safety, and quality contract.
