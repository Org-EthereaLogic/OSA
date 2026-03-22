# Domain

Persistence-agnostic product logic and contracts.

## Planned Subdomains

- `Common/` — shared identifiers, lightweight value types, and cross-cutting protocols
- `Content/` — handbook, quick cards, citations, and source metadata contracts
- `Inventory/` — inventory entities, repositories, and use cases
- `Checklists/` — checklist templates, runs, and completion flows
- `Notes/` — user notes and local reference contracts
- `Assistant/` — retrieval inputs, answer-state contracts, and policy interfaces
- `Settings/` — app settings and capability-state contracts

## Notes

- Do not import SwiftData here.
- Repository protocols live here; implementations belong in `OSA/Persistence/`.
