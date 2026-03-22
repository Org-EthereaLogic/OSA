# feature

Plan a new feature from an issue or description.

## Variables

description: $ARGUMENTS

## Instructions

1. Read `CLAUDE.md` and relevant `docs/` files for architectural context.
2. Verify the feature aligns with project constraints:
   - **Offline-first**: Does it work without network? (required)
   - **Privacy-first**: Does user data stay on device? (required)
   - **Grounded AI**: If it involves the assistant, does it use only local sources? (required)
3. Create the plan in `docs/plans/feature-{name}.md`.

## Feature Plan Format

```markdown
# Feature: {name}

**Created**: {date}
**Status**: draft
**Module**: {which module this belongs to}

## Description
What the feature does and why users need it.

## Constraint Alignment
- Offline-first: {yes/no — how}
- Privacy-first: {yes/no — how}
- Grounded AI: {yes/no/n/a — how}

## Relevant Files
- `path/to/file.swift` — why

## Implementation Phases

### Phase 1: Foundation
- Data models and persistence

### Phase 2: Core Logic
- Business logic and repositories

### Phase 3: UI Integration
- SwiftUI views and navigation

## Testing Strategy
- Unit tests for: ...
- Integration tests for: ...
- UI tests for: ...

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Validation
- `swift build`
- `swift test`
```
