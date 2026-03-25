# docs

Documentation map for the OSA repository.

## Directory Map

| Path | Purpose | Canonicality |
| --- | --- | --- |
| `sdlc/` | Product, UX, architecture, data, safety, quality, release, and risk documents | Canonical |
| `adr/` | Accepted architecture decision records | Canonical |
| `prompt/` | Prompt source material, enhanced prompts, and prompt-working areas | Non-canonical unless explicitly promoted |
| `reference/` | Preserved local reference inputs and archived supporting material | Non-canonical |

## Navigation Rules

- Start with [`sdlc/README.md`](./sdlc/README.md) for the numbered document suite.
- Use [`adr/README.md`](./adr/README.md) for long-lived decisions that constrain implementation.
- Use [`prompt/README.md`](./prompt/README.md) for prompt artifacts and prompt-derived material.
- Use [`reference/README.md`](./reference/README.md) only for inputs that informed work but are not the source of truth.

## Current Layout Note

- The canonical numbered suite now lives under `docs/sdlc/`, with prompts and preserved source material separated into `docs/prompt/`.
- `docs/prompt/enhanced/sdlc_doc_suite_prompt.md` is intentionally retained as a historical prompt artifact for traceability and may mention the earlier flat `docs/` layout.

## Boundaries

- Directory location outranks filename numbering when deciding whether a document is canonical.
- Prompt assets should not override `docs/sdlc/` or `docs/adr/`.
- When created, use `report/` for dated evidence artifacts and release/readiness reporting rather than mixing them into `docs/`.
- Update this navigation layer when files move, split, or change role.
