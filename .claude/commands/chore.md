# chore

Run low-risk maintenance tasks within project constraints.

## Variables

task: $ARGUMENTS

## Workflow

1. Confirm the task is low-risk maintenance (formatting, dependency updates, config changes).
2. Verify the task does NOT modify:
   - Core feature logic
   - Data models or persistence layer
   - SDLC documentation in `docs/`
   - Architecture decisions (ADRs)
3. Make the changes.
4. Validate:
   - `swift build`
   - `swift test`
5. Report:
   - Files changed
   - Validation status (pass/fail)
