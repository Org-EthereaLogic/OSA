# OSA Source Layout

The app stays in a single target for now, but the source tree is organized by architectural boundary rather than by framework type.

## Directory Map

| Path | Purpose |
| --- | --- |
| `App/` | App lifecycle, composition root, model-container bootstrap, and top-level navigation |
| `Features/` | First-class SwiftUI feature surfaces such as Home, Library, Ask, Inventory, and Settings |
| `Domain/` | Domain models, repository protocols, use cases, and policy-facing interfaces |
| `Persistence/` | SwiftData models, repository implementations, migrations, seed import, and local index persistence |
| `Retrieval/` | Query construction, chunking, ranking, and citation packaging |
| `Assistant/` | Assistant policy, orchestration, model adapters, and answer formatting |
| `Networking/` | Trusted-source clients, import pipeline, refresh coordination, and network DTOs |
| `Shared/` | Reusable UI primitives, design tokens, cross-cutting support types, and focused helpers |
| `Resources/` | Bundled app resources, including assets and future seed content packs |

## Notes

- Keep SwiftData-specific APIs out of `Features/` and `Domain/`.
- Add code to the narrowest boundary that can own it cleanly.
- Prefer feature-owned components before promoting something to `Shared/`.
