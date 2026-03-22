# plan

Create a structured implementation plan for a task.

## Variables

task: $ARGUMENTS

## Instructions

1. Read relevant documentation (`CLAUDE.md`, `docs/`) for architectural context.
2. Classify complexity:
   - **Simple**: Single file change, clear implementation path
   - **Medium**: Multiple files, requires coordination between modules
   - **Complex**: Cross-cutting concerns, new patterns, architecture decisions
3. Create the plan in `docs/plans/plan-{name}.md` (create directory if needed).

## Plan Format

```markdown
# Plan: {task name}

**Complexity**: simple | medium | complex
**Created**: {date}
**Status**: draft

## Objective
What this plan achieves in 1-2 sentences.

## Relevant Files
- `path/to/file.swift` — why it's relevant

## Implementation Steps
1. Step with acceptance criterion
2. Step with acceptance criterion

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Validation
- `swift build` — compiles without warnings
- `swift test` — all tests pass
```

For **medium/complex** plans, also include:
- Problem statement and solution approach
- Implementation phases (foundation, core, integration)
- Testing strategy
- Risk assessment
