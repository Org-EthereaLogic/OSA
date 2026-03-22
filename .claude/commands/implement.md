# implement

Implement scoped features within OSA's architectural constraints.

## Variables

task: $ARGUMENTS

## Workflow

1. Read the task description and confirm scope and acceptance criteria.
2. Read `CLAUDE.md` and relevant `docs/` files for architectural context.
3. Read existing code in the affected module(s) before making changes.
4. Implement only the required behavior — keep complexity proportional to the task.
5. Write tests alongside the implementation (TDD where possible).
6. Validate:
   - `swift build` (compiles without warnings)
   - `swift test` (all tests pass)
   - `swiftlint` (if configured)
7. Report outcomes:
   - Files created or modified
   - Tests added
   - Architectural decisions made
   - Any follow-up items
