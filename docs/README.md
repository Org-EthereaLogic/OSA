# docs

Canonical OSA product, architecture, safety, quality, and release documentation.

## Directory Map

| Path | Purpose |
| --- | --- |
| `adr/` | Accepted architecture decisions that constrain implementation |
| `reference/` | Non-canonical local reference snapshots and preserved external inputs |
| root `docs/*.md` | Canonical SDLC, product, architecture, data, safety, and release documents |

## Boundaries

- Treat root `docs/*.md` plus `docs/adr/` as the canonical documentation surface.
- Use `docs/reference/` only for preserved references that informed decisions but are not themselves source of truth.
- Use `report/` for dated evidence artifacts and release/readiness reporting rather than mixing those into `docs/`.
- Update canonical docs when repository structure changes invalidate factual statements.
