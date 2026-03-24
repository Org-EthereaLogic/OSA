# docs/prompt

Prompt source material and prompt-working areas.

## Directory Map

| Path | Purpose |
| --- | --- |
| `doc/` | Reference materials on prompt engineering practices and techniques |
| `draft/` | In-progress or experimental prompt work not yet ready for reuse |
| `enhanced/` | Curated prompt rewrites, implementation task prompts, and prompt-derived artifacts |

## Boundaries

- Treat this tree as non-canonical unless a document is explicitly promoted into `docs/sdlc/` or another canonical location.
- Prompt material may inform implementation, but it does not override `docs/sdlc/` or `docs/adr/`.
- If a prompt-derived document becomes the living spec, move it out of this tree rather than relying on readers to infer intent from the filename.

## Current Layout Note

- Canonical numbered SDLC docs now live under `docs/sdlc/`.
- `enhanced/` is reserved for reusable prompt artifacts and prompt-derived source material.
- The preserved `sdlc_doc_suite_prompt.md` artifact may still mention the older flat `docs/` layout because it is retained for historical traceability.
